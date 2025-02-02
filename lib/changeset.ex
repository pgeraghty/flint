defmodule Flint.Changeset do
  @moduledoc """
  The base `changeset` function defined by `Flint`. `Flint.Changeset` uses the module attributes
  that are collected when using the `Flint.Schema` macros to perform transformations and validations.
  """

  @doc """
  Uses the quoted expressions from the `Flint.Schema.field` and `Flint.Schema.field!`
  `do` blocks to validate the changeset.

  You can optionally pass bindings to be added to the evaluation context.
  """
  def validate_do_blocks(changeset, bindings \\ []) do
    module = changeset.data.__struct__
    env = Module.concat(module, Env) |> apply(:env, [])

    all_validations =
      module.__schema__(:blocks)

    for {field, block} <- all_validations, reduce: changeset do
      changeset ->
        bindings = bindings ++ Enum.into(changeset.changes, [])

        block
        |> Enum.with_index()
        |> Enum.reduce(changeset, fn
          {{quoted_condition, quoted_err}, index}, chngset ->
            try do
              {invalid?, _bindings} = Code.eval_quoted(quoted_condition, bindings, env)

              invalid? =
                if is_function(invalid?) do
                  case Function.info(invalid?, :arity) do
                    {:arity, 0} ->
                      apply(invalid?, [])

                    {:arity, 1} when not is_nil(field) ->
                      apply(invalid?, [Ecto.Changeset.fetch_change!(changeset, field)])

                    _ ->
                      raise ArgumentError,
                            "Anonymous functions in validation clause must be either 0-arity or an input value for the field must be provided."
                  end
                else
                  invalid?
                end

              {err_msg, _bindings} = Code.eval_quoted(quoted_err, bindings, env)

              if invalid? do
                Ecto.Changeset.add_error(chngset, field, err_msg,
                  validation: :block,
                  clause: index + 1
                )
              else
                chngset
              end
            rescue
              _ ->
                Ecto.Changeset.add_error(
                  chngset,
                  field,
                  "Error evaluating expression in Clause ##{index + 1} of `do:` block"
                )
            end
        end)
    end
  end

  @doc """
  Given a `Flint` (or `Ecto`) schema and params (can be a map, struct of the given schema, or an existing changeset),
  applies all steps of the `Flint.Changeset` to generate a new changeset.

  This function casts all fields (recursively casting all embeds using this same function),
  validates required fields (specified using the bang (`!`) macros exposed by `Flint`),
  outputting the resulting `Ecto.Changeset`.
  """
  def changeset(schema, params \\ %{}, bindings \\ []) do
    module = schema.__struct__
    fields = module.__schema__(:fields) |> MapSet.new()
    embedded_fields = module.__schema__(:embeds) |> MapSet.new()

    params =
      case params do
        %Ecto.Changeset{params: params} -> params
        s when is_struct(s) -> Map.from_struct(params)
        _ -> params
      end

    required = module.__schema__(:required)
    fields = fields |> MapSet.difference(embedded_fields)
    required_embeds = Enum.filter(required, &(&1 in embedded_fields))
    required_fields = Enum.filter(required, &(&1 in fields))

    changeset =
      schema
      |> Ecto.Changeset.cast(params, fields |> MapSet.to_list())

    changeset =
      for field <- embedded_fields, reduce: changeset do
        changeset ->
          changeset
          |> Ecto.Changeset.cast_embed(field,
            required: field in required_embeds,
            with: &changeset(&1, &2, bindings)
          )
      end

    changeset
    |> Ecto.Changeset.validate_required(required_fields)
    |> validate_do_blocks(bindings)
  end
end
