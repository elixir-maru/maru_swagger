defmodule MaruSwagger.ResponseFormatter do
  alias MaruSwagger.ConfigStruct

  def format(routes, tags, config = %ConfigStruct{}) do
    paths =
      routes
      |> List.foldr(%{}, fn %{
                              desc: desc,
                              method: method,
                              path: url_list,
                              params: params,
                              tag: tag
                            },
                            result ->
        desc = desc || %{}
        responses = desc[:responses] || [%{code: 200, description: "ok"}]
        url = join_path(url_list)

        if Map.has_key?(result, url) do
          result
        else
          result |> put_in([url], %{})
        end
        |> put_in([url, to_string(method)], %{
          tags: [tag],
          description: desc[:detail] || "",
          summary: desc[:summary] || "",
          parameters: params,
          responses:
            for r <- responses, into: %{} do
              {to_string(r.code), %{description: r.description}}
            end
        })
      end)

    definitions = format_definitions(routes)

    wrap_in_swagger_info(paths, tags, definitions, config)
  end

  defp format_definitions(routes) do
    routes |> List.foldr(%{}, fn (route, result) ->
      case route do
        %{desc: %{model: %{name: name, fields: fields}}} ->
          result |> put_in([name],
            %{
              type: "object",
              properties: fields |> Enum.into(%{}, &(&1 |> format_field))
            })
        _ -> result
      end
    end)
  end

  defp format_field(field) do
    case field do
      %{name: name, model: model} -> {name, %{"$ref": "#/definitions/#{model}"}}
      %{name: name, type: type}   -> {name, %{type: type}}
    end
  end

  defp wrap_in_swagger_info(paths, tags, definitions, config = %ConfigStruct{}) do
    res = %{
      swagger: "2.0",
      info:
        case config.info do
          [_ | _] -> format_info(config.info)
          _ -> format_default(config)
        end,
      paths: paths,
      definitions: definitions,
      tags: tags
    }

    for {k, v} <- config.swagger_inject || [], into: res, do: {k, v}
  end

  defp format_info(info) do
    %{
      title: info[:title],
      description: info[:desc]
    }
  end

  defp format_default(config) do
    %{title: "Swagger API for #{elixir_module_name(config.module)}"}
  end

  defp elixir_module_name(module) do
    "Elixir." <> m = module |> to_string
    m
  end

  defp join_path(path) do
    [
      "/"
      | for i <- path do
          cond do
            is_atom(i) -> "{#{i}}"
            is_binary(i) -> i
            true -> raise "unknow path type"
          end
        end
    ]
    |> Path.join()
  end
end
