defmodule MaruSwagger.ResponseFormatter do
  # TODO too cryptic, split up into smaller functions...
  def format(list, module, version) do
    #IO.puts "## FORMATTING ### \n #{inspect(list)}"

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
    wrap_in_swagger_info(module, version, paths)
  end

  defp wrap_in_swagger_info(module, version, paths) do
    %{
      swagger: "2.0",
      info: %{
        version: version,
        title: "Swagger API for #{elixir_module_name(module)}",
      },
      paths: paths
    }
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
