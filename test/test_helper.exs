ExUnit.start()

defmodule TestHelper do
  defmacro assert_route_info(swagger_docs, path, expected) do
    quote do
      real_info = unquote(swagger_docs) |> get_in([:paths, unquote(path)])
      assert real_info == unquote(expected)
    end
  end

  @doc """
  helper function to get Endpoint datastructure from a given module

  Example:
      # post "/complex", no version ->
      TestHelper.route_from_module(BasicTest.Homepage, "POST", ["complex"])

      # post "/complex", "v1" ->
      # TestHelper.route_from_module(BasicTest.Homepage, "v1", "POST", ["complex"])
  """
  def route_from_module(module, method, path_list) do
    module.__routes__
      # |> Maru.Builder.Routers.generate
      # |> Map.get(version) # ?? this is the missing version I guess...
      |> Enum.find(fn(x)-> x.path == path_list && x.method == String.upcase(method) end)
  end

  @doc """
  shortcut to extract_params
  """
  def extract_params(route) do
    MaruSwagger.ParamsExtractor.extract_params(route)
  end
end
