ExUnit.start()

defmodule TestHelper do
  defmacro assert_route_info(swagger_docs, path, expected) do
    quote do
      real_info = unquote(swagger_docs) |> get_in([:paths, unquote(path)])
      assert real_info == unquote(expected)
    end
  end
end
