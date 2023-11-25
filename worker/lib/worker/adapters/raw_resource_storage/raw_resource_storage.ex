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

  # TODO: we don't handle any exit reason, we only handle our errors; should actually handle abnormal exits
  # TODO: better error handling in get(), now every error is translated to "resource not found"
  @behaviour Worker.Domain.Ports.RawResourceStorage

  @file_prefix :worker |> Application.compile_env!(__MODULE__) |> Keyword.fetch!(:prefix)
  @process_prefix "file_writer_"
  @registry Worker.Adapters.RawResourceStorage.Registry

  @doc """

  Gets the saved raw resource, if available.
  In case a process is already writing/deleting it, it waits for it to complete.

  ## Parameters
  - `function_name`: the name of the function
  - `module`: the module of the function

  ## Returns
  - `resource` if the resource is found;
  - `:resource_not_found` if the resource is not found.
  """
  @impl true
  def get(function_name, module) do
    process_name = @process_prefix <> "#{module}_#{function_name}"

    case Registry.lookup(@registry, process_name) do
      [] ->
        do_get(function_name, module)

      [{pid, _} | _] ->
        ref = Process.monitor(pid)

        receive do
          {:DOWN, ^ref, _, _, {:error, _}} ->
            :resource_not_found

          {:DOWN, ^ref, _, _, _} ->
            do_get(function_name, module)
        end
    end
  end

  defp do_get(function_name, module) do
    file_path = get_file_path(function_name, module)

    case File.read(file_path) do
      {:ok, resource} -> resource
      {:error, _} -> :resource_not_found
    end
  end

  @doc """
  Inserts a raw resource, using function name and module as key.
  It spawns and registers a process to perform the file creation, using Worker.Adapters.RawResourceStorage.Registry.
  The process is monitored as soon as it is spawned.
  In case a process is already writing/deleting the same file, it monitors that instead.

  If the file was being deleted, this function returns `:ok` if the deletion completes successfully.

  ## Parameters
  - `function_name`: the name of the function
  - `module`: the module of the function
  - `resource`: the resource to store

  ## Returns
  - `:ok` if everything went well
  - `{:error, err}` if any error arose during the registration of the process, or the creation of the file
  """
  @impl true
  def insert(function_name, module, resource) do
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
                resource
              ],
              [:monitor]
            )

          ref

        [{pid, _} | _] ->
          Process.monitor(pid)
      end

    receive do
      {:DOWN, ^insert_ref, _, _, {:error, err}} ->
        {:error, err}

      {:DOWN, ^insert_ref, _, _, _} ->
        :ok
    end
  end

  defp do_insert(process_name, function_name, module, resource) do
    case Registry.register(@registry, process_name, nil) do
      {:ok, _} ->
        file_path = get_file_path(function_name, module)

        result =
          if File.exists?(file_path) do
            # nothing to do (in the future we should update)
            :ok
          else
            File.write(file_path, resource)
          end

        case result do
          :ok -> :ok
          {:error, err} -> exit({:error, err})
        end

      {:error, err} ->
        exit({:error, err})
    end
  end

  @doc """

  Deletes a raw resource, if it exists.
  It spawns and registers a process to perform the file deletion, using Worker.Adapters.RawResourceStorage.Registry.
  The process is monitored as soon as it is spawned.
  In case a process is already writing/deleting the same file, it monitors that instead.

  If the file was being created, this function returns `:ok` if the creation completes successfully.

  ## Parameters
  - `function_name`: the name of the function
  - `module`: the module of the function

  ## Returns
  - `:ok` if everything went well
  - `{:error, err}` if any error arose during the registration of the process, or the deletion of the file
  """
  @impl true
  def delete(function_name, module) do
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
                module
              ],
              [:monitor]
            )

          ref

        [{pid, _} | _] ->
          Process.monitor(pid)
      end

    receive do
      {:DOWN, ^delete_ref, _, _, {:error, err}} ->
        {:error, err}

      {:DOWN, ^delete_ref, _, _, _} ->
        :ok
    end
  end

  defp do_delete(process_name, function_name, module) do
    case Registry.register(@registry, process_name, nil) do
      {:ok, _} ->
        file_path = get_file_path(function_name, module)

        case File.rm(file_path) do
          :ok -> :ok
          {:error, err} -> exit({:error, err})
        end

      {:error, err} ->
        exit({:error, err})
    end
  end

  defp get_file_path(function_name, module) do
    @file_prefix <> "#{module}_#{function_name}"
  end
end
