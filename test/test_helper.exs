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
  def route_from_module(module, version \\ nil, method, path_list) do
    route = Enum.find(module.__routes__, fn x ->
      path_match?(path_list, x.path) &&
        x.method == String.upcase(method) &&
        x.version == version
    end)
    parameters = Enum.map(route.parameters, &(&1.information))
    %{ route | parameters: parameters }
  end

  @doc """
  shortcut to extract_params
  """
  def extract_params(route, config \\ %{force_json: false}) do
    MaruSwagger.ParamsExtractor.extract_params(route, config)
  end

  defp path_match?([], []),                         do: true
  defp path_match?([h|t1], [h|t2]),                 do: path_match?(t1, t2)
  defp path_match?([_|t1], [h|t2]) when is_atom(h), do: path_match?(t1, t2)
  defp path_match?(_, _),                           do: false
end
