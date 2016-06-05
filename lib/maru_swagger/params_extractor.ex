defmodule MaruSwagger.ParamsExtractor do
  alias Maru.Struct.Parameter.Information

  defmodule NonGetParamsGenerator do
    def generate(file_param_list, param_list, path) do

      default_body
      |> adjust_param_list(param_list)
      |> adjust_file_param_list(file_param_list)
      |> adjust_pathes(path)
    end

    defp default_body do
      %{ name: "body",
         in: "body",
         description: "desc",
         required: false}
    end

    defp adjust_param_list(r, param_list) do
      if param_list == %{} do
        r
      else
        r
        |> put_in([:schema], %{})
        |> put_in([:schema, :properties], param_list)
      end
    end

    defp adjust_file_param_list(r, []), do: [r]
    defp adjust_file_param_list(_r, file_param_list), do: file_param_list

    defp adjust_pathes(r, path) do
      if Enum.any?(path, &is_atom/1) do
        r ++ (path |> Enum.filter(&is_atom/1) |> Enum.map(&(%{name: &1, in: "path", required: true, type: "string"})))
      else
        r
      end
    end
  end

  alias Maru.Struct.Route
  def extract_params(%Route{method: {:_, [], nil}}=ep) do
    %{ep | method: "MATCH"} |> extract_params
  end

  def extract_params(%Route{method: "GET", path: path, parameters: parameters}) do
    for param <- parameters do
      %{ name:        param.param_key,
         description: param.desc || "",
         required:    param.required,
         type:        decode_type(param.type),
         in:          param.attr_name in path && "path" || "query",
      }
    end
  end
  def extract_params(%Route{method: "GET"}), do: []
  def extract_params(%Route{parameters: []}), do: []

  def extract_params(%Route{parameters: parameters, path: path}) do
    {file_param_list, param_list} = split_file_list_and_rest(parameters)
    file_param_list_swagger       = convert_file_param_list_to_swagger(file_param_list)
    param_list_swagger            = convert_param_list_to_swagger(param_list)
    NonGetParamsGenerator.generate(file_param_list_swagger, param_list_swagger, path)
  end

  defp convert_param_list_to_swagger(param_list_extra) do
    for %Information{param_key: param_key, type: type, required: required, desc: desc} <- param_list_extra do
      { param_key,
        %{
          type: decode_type(type),
          required: required,
          description: desc || "",
        }
      }
    end |> Enum.into(%{})
  end

  defp convert_file_param_list_to_swagger(file_list) do
     for param <- file_list do
      %{ name:        param.source || param.attr_name,
         in:          "formData",
         description: "file",
         required:    true,
         type:        "file"
       }
    end
  end

  defp decode_type(type) do
    type |> String.downcase
  end

  defp split_file_list_and_rest(params_list) do
     Enum.split_while(params_list, fn(param) -> decode_type(param.type) == "file" end)
  end
end
