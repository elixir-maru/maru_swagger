defmodule MaruSwagger.ConfigStruct do
  defstruct [
    # [string]  where to mount the Swagger UI
    :ui_path,    
    # [string]  where to mount the Swagger JSON
    :sw_path,
    # [atom]    Maru API module
    :module,
    # [boolean] force JSON for all params instead of formData
    :force_json,
    # [boolean] should JSON output be prettified?
    :pretty,
    # [keyword list] key-values to inject directly into root of Swagger JSON
    :swagger_inject,
    # [keyword list] key-values to inject directly into info of Swagger JSON
    :info
  ]

  def from_opts(opts) do
    ui_path = opts |> Keyword.fetch!(:at) |> Maru.Utils.split_path()
    sw_path = ui_path ++ ["swagger.json"]
    module = opts |> Keyword.fetch!(:module)
    force_json = opts |> Keyword.get(:force_json, false)
    pretty = opts |> Keyword.get(:pretty, false)

    swagger_inject =
      opts
      |> Keyword.get(:swagger_inject, [])
      |> Keyword.put_new_lazy(:basePath, base_path_func(module))
      |> check_swagger_inject_keys

    info = opts |> Keyword.get(:info, []) |> check_info_inject_keys

    %__MODULE__{
      ui_path: ui_path,
      sw_path: sw_path,
      module: module,
      force_json: force_json,
      pretty: pretty,
      swagger_inject: swagger_inject,
      info: info
    }
  end

  defp base_path_func(module) do
    fn ->
      [
        ""
        | if apply(Code, :ensure_loaded?, [Phoenix]) do
            phoenix_module =
              Mix.Phoenix
              |> apply(:base, [])
              |> Module.concat("Router")

            phoenix_module.__routes__
            |> Enum.filter(fn r ->
              match?(%{kind: :forward, plug: ^module}, r)
            end)
            |> case do
              [%{path: p}] -> p |> String.split("/", trim: true)
              _ -> []
            end
          else
            []
          end
      ]
      |> Enum.join("/")
    end
  end

  defp check_swagger_inject_keys(swagger_inject) do
    swagger_inject
    |> Enum.filter(fn {k, v} ->
      k in allowed_swagger_fields() and not (v in [nil, ""])
    end)
  end

  defp allowed_swagger_fields do
    [:host, :basePath, :schemes, :consumes, :produces]
  end

  defp check_info_inject_keys(info) do
    info
    |> Enum.filter(fn {k, v} ->
      k in allowed_info_fields() and not (v in [nil, ""])
    end)
  end

  defp allowed_info_fields do
    [:title, :desc]
  end
end
