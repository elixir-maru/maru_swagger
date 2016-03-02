defmodule MaruSwagger do
  use Maru.Middleware

  defmodule ConfigStruct do
    defstruct [
      :path,           # [string]  where to mount the Swagger JSON
      :module,         # [atom]    Maru API module
      :version,        # [string]  version
      :pretty,         # [boolean] should JSON output be prettified?
      :prefix          # [list]    the param to prepent to URLS in the Swagger JSON
    ]

    def from_opts(opts) do
      module_func = fn ->
        case Maru.Config.servers do
          [{module, _} | _] -> module
          _                 -> raise "missing configured module for Maru in config.exs (MaruSwagger depends on it!)"
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

      %ConfigStruct{
        path: path,
        module: module,
        version: version,
        pretty: pretty,
        prefix: prefix
      }
    end
  end

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
