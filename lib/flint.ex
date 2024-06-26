defmodule Flint do
  @moduledoc """
  #{File.cwd!() |> Path.join("README.md") |> File.read!() |> then(&Regex.run(~r/.*<!-- BEGIN MODULEDOC -->(?P<body>.*)<!-- END MODULEDOC -->.*/s, &1, capture: :all_but_first)) |> hd()}
  """

  defmacro __using__(opts) do
    {schema, opts} = Keyword.pop(opts, :schema)

    opts =
      Keyword.validate!(
        opts,
        primary_key: false,
        schema_prefix: nil,
        schema_context: nil,
        timestamp_opts: [type: :naive_datetime]
      )

    Module.register_attribute(__CALLER__.module, :required, accumulate: true)

    prelude =
      quote do
        @behaviour Access

        defdelegate fetch(term, key), to: Map
        defdelegate get_and_update(term, key, fun), to: Map
        defdelegate pop(data, key), to: Map

        use Ecto.Schema
        import Ecto.Changeset
        import Ecto.Schema, except: [embedded_schema: 1]
        import Flint.Schema, only: [embedded_schema: 1]

        @before_compile Flint.Schema

        @schema_prefix unquote(opts[:schema_prefix])
        @schema_context unquote(opts[:schema_context])
        @timestamp_opts unquote(opts[:timestamp_opts])
        @primary_key unquote(opts[:primary_key])
      end

    if schema do
      quote do
        unquote(prelude)

        embedded_schema do
          unquote(schema)
        end
      end
    else
      quote do
        unquote(prelude)
      end
    end
  end
end
