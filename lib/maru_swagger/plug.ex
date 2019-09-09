defmodule MaruSwagger.Plug do
  use Maru.Middleware
  alias MaruSwagger.ConfigStruct
  alias Plug.Conn

  def init(opts) do
    ConfigStruct.from_opts(opts)
  end

  def call(%Conn{path_info: path} = conn, %ConfigStruct{path: path} = config) do
    json_library = Maru.json_library()
    resp = config |> generate() |> json_library.encode!(pretty: config.pretty)

    conn
    |> Conn.put_resp_header("access-control-allow-origin", "*")
    |> Conn.put_resp_content_type("application/json")
    |> Conn.send_resp(200, resp)
    |> Conn.halt()
  end

  def call(conn, _) do
    conn |> Conn.put_resp_header("access-control-allow-origin", "*")
  end

  def generate(%ConfigStruct{} = config) do
    c = (Application.get_env(:maru, config.module) || [])[:versioning] || []
    adapter = Maru.Builder.Versioning.get_adapter(c[:using])

    routes =
      config.module.__routes__
      |> Enum.map(fn route ->
        parameters = Enum.map(route.parameters, & &1.information)
        %{route | parameters: parameters}
      end)

    tags =
      routes
      |> Enum.map(& tag_name(&1.path))
      |> Enum.uniq()
      |> Enum.map(& %{name: &1})

    routes =
      routes
      |> Enum.map(&extract_route(&1, adapter, config))

    MaruSwagger.ResponseFormatter.format(routes, tags, config)
  end

  defp extract_route(ep, adapter, config) do
    params = MaruSwagger.ParamsExtractor.extract_params(ep, config)
    path = adapter.path_for_params(ep.path, ep.version)

    method =
      case ep.method do
        {:_, [], nil} -> :match
        m -> m
      end

    %{
      desc: ep.desc,
      method: method,
      path: path,
      params: params,
      tag: tag_name(ep.path)
    }
  end

  defp tag_name(nil), do: "DEFAULT"
  defp tag_name([h]), do: h
  defp tag_name(path), do: Enum.at(path, 1)
end
