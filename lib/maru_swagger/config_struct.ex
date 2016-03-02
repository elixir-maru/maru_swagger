defmodule MaruSwagger.ConfigStruct do
  defstruct [
    :path,           # [string]  where to mount the Swagger JSON
    :module,         # [atom]    Maru API module
    :version,        # [string]  version
    :pretty,         # [boolean] should JSON output be prettified?
    :prefix          # [list]    the param to prepent to URLS in the Swagger JSON
  ]

  def from_opts(opts) do
    path    = opts |> Keyword.fetch!(:at) |> Maru.Router.Path.split
    module  = opts |> Keyword.get_lazy(:for, module_func)
    version = opts |> Keyword.get(:version, nil)
    pretty  = opts |> Keyword.get(:pretty, false)
    prefix  = opts |> Keyword.get_lazy(:prefix, prefix_func(module))

    %__MODULE__{
      path: path,
      module: module,
      version: version,
      pretty: pretty,
      prefix: prefix
    }
  end

  defp prefix_func(module) do
    fn ->
      if Code.ensure_loaded?(Phoenix) do
        phoenix_module = Module.concat(Mix.Phoenix.base(), "Router")
        phoenix_module.__routes__ |> Enum.filter(fn r ->
          match?(%{kind: :forward, plug: ^module}, r)
        end)
        |> case do
          [%{path: p}] -> p |> String.split("/", trim: true)
          _            -> []
        end
      else
        []
      end
    end
  end

  defp module_func do
    fn ->
      case Maru.Config.servers do
        [{module, _} | _] -> module
        _                 -> raise "missing configured module for Maru in config.exs (MaruSwagger depends on it!)"
      end
    end
  end
end
