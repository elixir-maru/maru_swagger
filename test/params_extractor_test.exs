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
      post "/res1" do
        conn |> json(params)
      end
    end

    it "works with basic POST params" do
      route_info = route_from_module(BasicPostApi, "POST", ["res1"])
      assert [
        %{description: "desc", in: "body", name: "body", required: false,
          schema: %{
            properties: %{
              "email" => %{description: "", required: true, type: "string"},
              "user_name" => %{description: "", required: true, type: "string"}
            }
          }
        }
      ] == extract_params(route_info)
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
      post "/complex" do
        conn |> json(params)
      end
    end

    defmodule BasicTest.Api do
      use Maru.Router
      mount MaruSwagger.ParamsExtractorTest.BasicTest.Homepage
    end

    it "extracts expected swagger data from given params_context" do
      route_info = route_from_module(BasicTest.Homepage, "POST", ["complex"])
      assert [
        %{description: "desc", in: "body", name: "body", required: false,
              schema: %{properties: %{
                "age"   =>   %{description: "age information", required: false, type: "integer"},
                "email" => %{description: "", required: true, type: "string"},
                "name"  => %{description: "", required: true, type: "string"}}}}
      ] = extract_params(route_info)
    end
  end

end
