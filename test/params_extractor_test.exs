defmodule MaruSwagger.ParamsExtractorTest do
  use ExSpec, async: true
  doctest MaruSwagger.ParamsExtractor

  def extract(endpoint) do
    MaruSwagger.ParamsExtractor.extract_params(endpoint)
  end

  describe "POST" do
    @endpoint_info %Maru.Router.Endpoint{block: {:|>, [line: 25],
      [{:conn, [line: 25], nil},
       {:json, [line: 25], [{:params, [line: 25], nil}]}]}, desc: "creates res1",
     helpers: [], method: "POST",
     param_context: [%Maru.Router.Param{attr_name: :name, children: [],
       coerce_with: nil, default: nil, desc: nil, parser: :string, required: true,
       source: nil, validators: []},
      %Maru.Router.Param{attr_name: :email, children: [], coerce_with: nil,
       default: nil, desc: nil, parser: :string, required: true, source: nil,
       validators: []}], path: ["res1"], version: nil}


    it "includes basic information for swagger (title, API version, Swagger version)" do
      # "name":{
      #    "description":"company name",
      #    "required":true,
      #    "type":"string"
      # },

      expected = [
          %{description: "desc", in: "body", name: "body", required: false,
            schema: %{
              properties: %{
                email: %{description: "", required: true, type: "string"},
                name: %{description: "", required: true, type: "string"}
              }
            }
          }
      ]
      assert extract(@endpoint_info) == expected
    end
  end
end

