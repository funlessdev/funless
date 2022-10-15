defmodule Worker.Adapters.Runtime.Wasm.Engine do
  defstruct [
    # The actual NIF Resource.
    resource: nil,
    # Normally the compiler will happily do stuff like inlining the
    # resource in attributes. This will convert the resource into an
    # empty binary with no warning. This will make that harder to
    # accidentaly do.
    reference: nil
  ]

  def wrap_resource(resource) do
    %__MODULE__{
      resource: resource,
      reference: make_ref()
    }
  end
end

defimpl Inspect, for: Worker.Adapters.Runtime.Wasm.Engine do
  import Inspect.Algebra

  def inspect(dict, opts) do
    concat(["#Wasm.Engine<", to_doc(dict.reference, opts), ">"])
  end
end
