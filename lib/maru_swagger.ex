defmodule MaruSwagger do
  use Maru.Middleware

  def init(opts) do
    module_func = fn ->
      case Maru.Config.servers do
        [{module, _} | _] -> module
        _                 -> raise "missing module for maru swagger"
      end
    end

    path    = opts |> Keyword.fetch!(:at) |> Maru.Router.Path.split
    module  = opts |> Keyword.get_lazy(:for, module_func)

    prefix_func = fn ->
      if Code.ensure_loaded?(Phoenix) do
        phoenix_module = Module.concat(Mix.Phoenix.base(), "Router")
        phoenix_module.__routes__ |> Enum.filter(fn r ->
          match?(%{kind: :forward, plug: ^module}, r)
        end)
        |> case do
          [%{path: p}] -> p |> String.split("/", trim: true)
          _            -> []
        end
      else [] end
    end
    version = opts |> Keyword.get(:version, nil)
    pretty  = opts |> Keyword.get(:pretty, false)
    prefix  = opts |> Keyword.get_lazy(:prefix, prefix_func)
    {path, module, version, pretty, prefix}
  end

  def call(%Plug.Conn{path_info: path_info}=conn, {path, module, version, pretty, prefix}) do
    case Maru.Router.Path.lstrip(path_info, path) do
      {:ok, []} ->
        resp =
          generate(module, version, prefix)
          |> Poison.encode!(pretty: pretty)
        conn
        |> Plug.Conn.put_resp_header("access-control-allow-origin", "*")
        |> Plug.Conn.send_resp(200, resp)
        |> Plug.Conn.halt
      _ -> conn
    end
  end

  def generate(module, version, prefix) do
    module
    |> Maru.Builder.Routers.generate
    |> Dict.fetch!(version)
    |> Enum.sort(&(&1.path > &2.path))
    |> Enum.map(&extract_endpoint(&1, prefix))
    |> to_swagger(module, version)
  end

  defp extract_endpoint(ep, prefix) do
    params = ep |> MaruSwagger.ParamsExtractor.extract_params
    method =
      case ep.method do
        {:_, [], nil} -> "MATCH"
        m             -> m
      end
    %{desc: ep.desc, method: method, path: prefix ++ ep.path, params: params, version: ep.version}
  end

  defp to_swagger(list, module, version) do
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
