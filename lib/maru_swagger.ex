defmodule MaruSwagger do
  use Maru.Middleware
  alias MaruSwagger.ConfigStruct

  def init(opts) do
    ConfigStruct.from_opts(opts)
  end

  def call(%Plug.Conn{path_info: path_info}=conn, config = %ConfigStruct{}) do
    case Maru.Router.Path.lstrip(path_info, config.path) do
      {:ok, []} ->
        resp =
          generate(config.module, config.version, config.prefix)
          |> Poison.encode!(pretty: config.pretty)
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
    |> MaruSwagger.ResponseFormatter.format(module, version)
  end

  defp extract_endpoint(ep, prefix) do
    params = ep |> MaruSwagger.ParamsExtractor.extract_params
    method = case ep.method do
      {:_, [], nil} -> "MATCH"
      m             -> m
    end
    %{
      desc:    ep.desc,
      method:  method,
      path:    prefix ++ ep.path,
      params:  params,
      version: ep.version
    }
  end
end
