defmodule MaruSwagger.ParamsExtractor do
  alias Maru.Router.Endpoint
  def extract_params(%Endpoint{method: {:_, [], nil}}=ep) do
    %{ep | method: "MATCH"} |> extract_params
  end

  def extract_params(%Endpoint{method: "GET", path: path, param_context: param_context}) do
    for param <- param_context do
      %{ name:        param.attr_name,
         description: param.desc || "",
         required:    param.required,
         type:        decode_parser(param.parser),
         in:          param.attr_name in path && "path" || "query",
      }
    end
  end
  def extract_params(%Endpoint{method: "GET"}), do: []
  def extract_params(%Endpoint{param_context: []}), do: []

  def extract_params(%Endpoint{param_context: param_context, path: path}) do
    {file_param_list, param_list} = split_file_list_and_rest(param_context)
    file_param_list_swagger       = convert_file_param_list_to_swagger(file_param_list)
    param_list_swagger            = convert_param_list_to_swagger(param_list)
    generate_swagger_non_get_data(file_param_list_swagger, param_list_swagger, path)
  end

  def generate_swagger_non_get_data(file_param_list_swagger, param_list_swagger, path) do
    %{ name: "body",
       in: "body",
       description: "desc",
       required: false,
     }
    |> fn r ->
      if param_list_swagger == %{} do
        r
      else
        r
        |> put_in([:schema], %{})
        |> put_in([:schema, :properties], param_list_swagger)
      end
    end.()
    |> fn r ->
      if file_param_list_swagger == [] do [r] else file_param_list_swagger end
    end.()
    |> fn r ->
      if Enum.any?(path, &is_atom/1) do
        r ++ (path |> Enum.filter(&is_atom/1) |> Enum.map(&(%{name: &1, in: "path", required: true, type: "string"})))
      else
        r
      end
    end.()
  end

  defp convert_param_list_to_swagger(param_list_extra) do
    for %Maru.Router.Param{attr_name: attr_name, parser: parser, required: required, desc: desc} <- param_list_extra do
      { attr_name, %{
          type: decode_parser(parser),
          required: required,
          description: desc || "",
        }
      }
    end |> Enum.into(%{})
  end

  defp convert_file_param_list_to_swagger(file_list) do
     for param <- file_list do
      %{ name:        param.attr_name,
         in:          "formData",
         description: "file",
         required:    true,
         type:        "file"
       }
    end
  end

  defp decode_parser(parser) do
    parser |> to_string |> String.split(".") |> List.last |> String.downcase
  end

  defp split_file_list_and_rest(params_list) do
     Enum.split_while(params_list, fn(param) -> decode_parser(param.parser) == "file" end)
  end
end
