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
          generate(config)
          |> Poison.encode!(pretty: config.pretty)
        conn
        |> Plug.Conn.put_resp_header("access-control-allow-origin", "*")
        |> Plug.Conn.send_resp(200, resp)
        |> Plug.Conn.halt
      _ -> conn
    end
  end

  def generate(module, version, prefix) do
    %ConfigStruct{module: module, version: version, prefix: prefix} |> generate
  end

  def generate(config = %ConfigStruct{}) do
    config.module
    |> Maru.Builder.Routers.generate
    |> Dict.fetch!(config.version)
    |> Enum.map(&extract_endpoint(&1, config.prefix))
    |> MaruSwagger.ResponseFormatter.format(config)
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
