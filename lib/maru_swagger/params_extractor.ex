defmodule MaruSwagger.ParamsExtractor do
  alias Maru.Router.Endpoint
  def extract_params(%Endpoint{method: {:_, [], nil}}=ep) do
    %{ep | method: "MATCH"} |> extract_params
  end

  def extract_params(%Endpoint{method: "GET", path: path, param_context: params_list}) do
    for param <- params_list do
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

  def extract_params(%Endpoint{path: path, param_context: params_list}) do
    {file_list, param_list_extra} = split_file_list(params_list) #FIXME find a better name
    p = convert_maru_params_to_swagger_params(param_list_extra)  #FIXME find a better name

    f = for param <- file_list do
      %{ name:        param.attr_name,
         in:          "formData",
         description: "file",
         required:    true,
         type:        "file"
       }
    end

    %{ name: "body",
       in: "body",
       description: "desc",
       required: false,
     }
    |> fn r ->
      if p == %{} do
        r
      else
        r
        |> put_in([:schema], %{})
        |> put_in([:schema, :properties], p)
      end
    end.()
    |> fn r ->
      if f == [] do [r] else f end
    end.()
    |> fn r ->
      if Enum.any?(path, &is_atom/1) do
        r ++ (path |> Enum.filter(&is_atom/1) |> Enum.map(&(%{name: &1, in: "path", required: true, type: "string"})))
      else r end
    end.()
  end

  defp convert_maru_params_to_swagger_params(param_list_extra) do
    for %Maru.Router.Param{attr_name: attr_name, parser: parser, required: required} <- param_list_extra do
      { attr_name, %{
          type: decode_parser(parser),
          required: required
        }
      }
    end |> Enum.into(%{}) #|> IO.inspect
  end

  defp decode_parser(parser) do
    parser |> to_string |> String.split(".") |> List.last |> String.downcase
  end

  defp split_file_list(params_list) do
     Enum.split_while(params_list, fn(param) -> decode_parser(param.parser) == "file" end)
  end
end
