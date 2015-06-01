defmodule MaruSwagger do
  use Maru.Middleware

  def init(opts) do
    at = Keyword.fetch!(opts, :at)
    Plug.Router.Utils.split(at)
  end

  def call(%Plug.Conn{path_info: path}=conn, path) do
    header "access-control-allow-origin", "*"
    generate |> json
  end

  def call(conn, _) do
    conn
  end

  def generate do
    for {mod, _} <- Maru.Config.servers do
      generate_module(mod, [], nil)
    end
 |> List.flatten
 |> Enum.sort(&(&1[:path] > &2[:path]))
 |> to_swagger
  end

  defp generate_module(mod, path, version) do
    version = version || mod.__version__
    for ep <- mod.__endpoints__ do
      params = extract_params({ep.method, ep.path, ep.param_context})
      %{desc: ep.desc, method: ep.method, path: ep.path, params: params}
    end
    ++
    for {_, [router: m, resource: resource], _} <- mod.__routers__ do
      generate_module(m, path ++ resource.path, version)
    end
  end

  defp extract_params({"GET", _, []}), do: []
  defp extract_params({"GET", path, params_list}) do
    for param <- params_list do
      if param.attr_name in path do
        %{ in: "path" }
      else
        %{ in: "query" }
      end
   |> Map.merge %{
        name: param.attr_name,
        description: param.desc || "",
        required: param.required,
        type: decode_parser(param.parser)
      }
    end
  end

  defp extract_params({_, _, []}), do: []
  defp extract_params({_, path, params_list}) do
    {file_list, param_list} = Enum.split_while(
      params_list,
      fn(param) ->
        decode_parser(param.parser) == "file"
      end
    )

    p = for param <- param_list do
      {param.attr_name, %{type: decode_parser(param.parser)}}
    end |> Enum.into %{}

    f = for param <- file_list do
      %{ name: param.attr_name,
         in: "formData",
         description: "file",
         required: true,
         type: "file"
       }
    end

    %{ name: "body",
       in: "body",
       description: "desc",
       required: false,
     }
 |> fn r ->
      if p == %{} do r else
        r
     |> put_in([:schema], %{})
     |> put_in([:schema, :properties], p)
      end
    end.()
 |> fn r ->
      if f == [] do [r] else f end
    end.()
 |> fn r ->
      if Enum.any? path, &is_atom/1 do
        r ++ path |> Enum.filter(&is_atom/1) |> Enum.map &(%{name: &1, in: "path", required: true, type: "string"})
      else r end
    end.()
  end

  defp decode_parser(parser) do
      parser |> to_string |> String.split(".") |> List.last |> String.downcase
  end

  defp to_swagger(list) do
    paths = list |> List.foldr%{}, fn (%{desc: desc, method: method, path: url_list, params: params}, result) ->
      url = join_path(url_list)
      if Map.has_key? result, url do
        result
      else
        result |> put_in([url], %{})
      end
   |> put_in([url, String.downcase(method)], %{
        description: desc || "",
        parameters: params,
      })
    end

    [{mod, _}] = Maru.Config.servers
    version =  mod.__version__ || "0.0.1"
    %{ swagger: "2.0",
       info: %{ version: version,
                title: mod,
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
