defmodule MaruSwagger.ParamsExtractorTest do
  use ExSpec, async: true
  doctest MaruSwagger.ParamsExtractor
  import TestHelper


  describe "POST" do
    defmodule BasicPostApi do
      use Maru.Router
      desc "res1 create"
      params do
        requires :name, type: :string, source: "user_name"
        requires :email, type: :string
      end
      def pc, do: @param_context
      post "/res1" do
        conn |> json(params)
      end
    end

    it "works with basic POST params" do
      endpoint_info = endpoint_from_module(BasicPostApi, "POST", ["res1"])
      expected = [
        %{description: "desc", in: "body", name: "body", required: false,
          schema: %{
            properties: %{
              :email => %{description: "", required: true, type: "string"},
              "user_name" => %{description: "", required: true, type: "string"}
            }
          }
        }
      ]
      assert extract_params(endpoint_info) == expected
    end
  end


  describe "more extensive POST example" do
    defmodule BasicTest.Homepage do
      use Maru.Router
      desc "root page"
      params do
        requires :id, type: Integer
        optional :query, type: Map
      end
      get "/" do
        conn |> json(%{ hello: :world })
      end

      desc "complex post"
      params do
        requires :name, type: :string
        requires :email, type: :string
        optional :age, type: :integer, desc: "age information"
      end
      def pc, do: @param_context
      post "/complex" do
        conn |> json(params)
      end
    end

    defmodule BasicTest.Api do
      use Maru.Router
      mount MaruSwagger.ParamsExtractorTest.Homepage
    end

    it "has expected params_context" do
      assert BasicTest.Homepage.pc == [
        %Maru.Router.Param{attr_name: :name, children: [], coerce_with: nil, default: nil, desc: nil, parser: :string, required: true, source: nil, validators: []},
        %Maru.Router.Param{attr_name: :email, children: [], coerce_with: nil, default: nil, desc: nil, parser: :string, required: true, source: nil, validators: []},
        %Maru.Router.Param{attr_name: :age, children: [], coerce_with: nil, default: nil, desc: "age information", parser: :integer, required: false, source: nil, validators: []}
      ]
    end

    it "extracts expected swagger data from given params_context" do
      endpoint_info = endpoint_from_module(BasicTest.Homepage, "POST", ["complex"])
      expected = [
        %{description: "desc", in: "body", name: "body", required: false,
              schema: %{properties: %{
                age:   %{description: "age information", required: false, type: "integer"},
                email: %{description: "", required: true, type: "string"},
                name:  %{description: "", required: true, type: "string"}}}}
      ]
      assert extract_params(endpoint_info) == expected
    end
  end
end
