# Copyright 2023 Giuseppe De Palma, Matteo Trentin
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

defmodule Worker.Adapters.RawResourceStorage do
  @moduledoc """
    Implements the RawResourceStorage behaviour.
    Raw resources (i.e. binaries) are saved in files.
  """

  @behaviour Worker.Domain.Ports.RawResourceStorage

  @file_prefix :worker |> Application.compile_env!(__MODULE__) |> Keyword.fetch!(:prefix)
  @process_prefix "file_writer_"
  @registry Worker.Adapters.RawResourceStorage.Registry

  require Elixir.Logger

  @doc """

  Gets the saved raw resource, if available and if it matches the given hash.
  In case a process is already writing/deleting it, it waits for it to complete.

  ## Parameters
  - `function_name`: the name of the function
  - `module`: the module of the function
  - `hash`: an hash code which identifies the function

  ## Returns
  - `resource` if the resource is found;
  - `:resource_not_found` if the resource is not found.
  """
  @impl true
  def get(function_name, module, hash) do
    process_name = @process_prefix <> "#{module}_#{function_name}"

    case Registry.lookup(@registry, process_name) do
      [] ->
        do_get(function_name, module, hash)

      [{pid, _} | _] ->
        ref = Process.monitor(pid)

        receive do
          {:DOWN, ^ref, _, _, :normal} ->
            do_get(function_name, module, hash)

          {:DOWN, ^ref, _, _, :noproc} ->
            do_get(function_name, module, hash)

          {:DOWN, ^ref, _, _, {:error, _}} ->
            :resource_not_found

          {:DOWN, ^ref, _, _, _reason} ->
            :resource_not_found
        end
    end
  end

  defp do_get(function_name, module, hash) do
    file_path = get_file_path(function_name, module)
    hash_path = get_hash_path(function_name, module)

    with {:ok, resource} <- File.read(file_path),
         {:ok, resource_hash} <- File.read(hash_path) do
      if resource_hash == hash do
        resource
      else
        :resource_not_found
      end
    else
      {:error, _} -> :resource_not_found
    end
  end

  @doc """
  Inserts a raw resource, using function name and module as key.
  It spawns and registers a process to perform the file creation, using Worker.Adapters.RawResourceStorage.Registry.
  The process is monitored as soon as it is spawned.
  In case a process is already writing/deleting the same file, it monitors that instead.
  The process also saves a hash file, to identify the function in subsequent `get`/`delete` requests.

  If the file was being deleted, this function returns `:ok` if the deletion completes successfully.

  ## Parameters
  - `function_name`: the name of the function
  - `module`: the module of the function
  - `hash`: an hash code which identifies the function
  - `resource`: the resource to store

  ## Returns
  - `:ok` if everything went well
  - `{:error, err}` if any error arose during the registration of the process, or the creation of the file
  """
  @impl true
  def insert(function_name, module, hash, resource) do
    process_name = @process_prefix <> "#{module}_#{function_name}"

    insert_ref =
      case Registry.lookup(@registry, process_name) do
        [] ->
          {_pid, ref} =
            Process.spawn(
              __MODULE__,
              :do_insert,
              [
                process_name,
                function_name,
                module,
                hash,
                resource
              ],
              [:monitor]
            )

          ref

        [{pid, _} | _] ->
          Process.monitor(pid)
      end

    receive do
      {:DOWN, ^insert_ref, _, _, :normal} ->
        :ok

      {:DOWN, ^insert_ref, _, _, :noproc} ->
        :ok

      {:DOWN, ^insert_ref, _, _, {:error, err}} ->
        {:error, err}

      {:DOWN, ^insert_ref, _, _, reason} ->
        {:error, reason}
    end
  end

  @spec do_insert(String.t(), String.t(), String.t(), binary(), binary()) :: :ok | {:error, any()}
  def do_insert(process_name, function_name, module, hash, resource) do
    with {:ok, _} <- Registry.register(@registry, process_name, nil),
         file_path <- get_file_path(function_name, module),
         hash_path <- get_hash_path(function_name, module),
         :ok <- check_and_save(file_path, resource),
         :ok <- check_and_save(hash_path, hash) do
      :ok
    else
      {:error, err} ->
        exit({:error, err})
    end
  end

  defp check_and_save(path, nil) do
    Logger.warning("RawResourceStorage: trying to save on #{path} but content is nil!")
  end

  defp check_and_save(path, content) do
    if File.exists?(path) do
      # nothing to do (in the future we should update)
      :ok
    else
      Logger.info("RawResourceStorage: saving #{path}")
      File.write(path, content)
    end
  end

  @doc """

  Deletes a raw resource, if it exists and it matches the given hash.
  It spawns and registers a process to perform the file deletion, using Worker.Adapters.RawResourceStorage.Registry.
  The process is monitored as soon as it is spawned.
  In case a process is already writing/deleting the same file, it monitors that instead.

  If the file was being created, this function returns `:ok` if the creation completes successfully.

  ## Parameters
  - `function_name`: the name of the function
  - `module`: the module of the function
  - `hash`: an hash code which identifies the function

  ## Returns
  - `:ok` if everything went well
  - `{:error, err}` if any error arose during the registration of the process, or the deletion of the file
  """
  @impl true
  def delete(function_name, module, hash) do
    process_name = @process_prefix <> "#{module}_#{function_name}"

    delete_ref =
      case Registry.lookup(@registry, process_name) do
        [] ->
          {_pid, ref} =
            Process.spawn(
              __MODULE__,
              :do_delete,
              [
                process_name,
                function_name,
                module,
                hash
              ],
              [:monitor]
            )

          ref

        [{pid, _} | _] ->
          Process.monitor(pid)
      end

    receive do
      {:DOWN, ^delete_ref, _, _, :normal} ->
        :ok

      {:DOWN, ^delete_ref, _, _, :noproc} ->
        :ok

      {:DOWN, ^delete_ref, _, _, {:error, err}} ->
        {:error, err}

      {:DOWN, ^delete_ref, _, _, reason} ->
        {:error, reason}
    end
  end

  @spec do_delete(String.t(), String.t(), String.t(), binary()) :: :ok | {:error, any()}
  def do_delete(process_name, function_name, module, hash) do
    with {:ok, _} <- Registry.register(@registry, process_name, nil),
         file_path <- get_file_path(function_name, module),
         hash_path <- get_hash_path(function_name, module),
         {:ok, resource_hash} <- File.read(hash_path),
         :ok <- check_and_delete(file_path, resource_hash, hash),
         :ok <- check_and_delete(hash_path, resource_hash, hash) do
      :ok
    else
      {:error, err} ->
        exit({:error, err})
    end
  end

  defp check_and_delete(path, saved_hash, hash) do
    if saved_hash == hash do
      Logger.info("RawResourceStorage: deleting #{path}")

      case File.rm(path) do
        :ok -> :ok
        {:error, :enoent} -> :ok
        {:error, err} -> {:error, err}
      end
    else
      :ok
    end
  end

  defp get_file_path(function_name, module) do
    Path.join([@file_prefix, "#{module}_#{function_name}"])
  end

  defp get_hash_path(function_name, module) do
    Path.join([@file_prefix, "#{module}_#{function_name}.hash"])
  end
end
