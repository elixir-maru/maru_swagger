defmodule MaruSwagger.ResponseFormatter do
  alias MaruSwagger.ConfigStruct

  def format(list, module, version) do
    list |> format(%ConfigStruct{module: module, version: version})
  end

  def format(list, config=%ConfigStruct{}) do
    paths = list |> List.foldr(%{}, fn (%{desc: desc, method: method, path: url_list, params: params}, result) ->
      url = join_path(url_list)
      if Map.has_key? result, url do
        result
      else
        result |> put_in([url], %{})
      end
      |> put_in([url, String.downcase(method)], %{
        description: desc || "",
        parameters: params,
        responses: %{
          "200" => %{description: "ok"}
        }
      })
    end)
    wrap_in_swagger_info(paths, config)
  end

  defp wrap_in_swagger_info(paths, config=%ConfigStruct{}) do
    res = %{
      swagger: "2.0",
      info: %{
        version: config.version,
        title: "Swagger API for #{elixir_module_name(config.module)}",
      },
      paths: paths
    }
    for {k,v} <- (config.swagger_inject || []), into: res, do: {k,v}
  end

  defp elixir_module_name(module) do
    "Elixir." <> m = module |> to_string
    m
  end

  defp join_path(path) do
    [ "/" | for i <- path do
      cond do
        is_atom(i) -> "{#{i}}"
        is_binary(i) -> i
        true -> raise "unknow path type"
      end
    end ] |> Path.join
  end
end
