defmodule MaruSwagger.ResponseFormatter do
  def format(list, module, version) do
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

    "Elixir." <> m = module |> to_string
    %{ swagger: "2.0",
       info: %{
         version: version,
         title: "Swagger API for #{m}",
       },
       paths: paths
     }
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
