defmodule MaruSwagger.ParamsExtractorTest do
  use ExUnit.Case, async: true
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

      desc "parameter in path"
      params do
        requires :foo, type: Integer
      end
      post "/:foo" do
        conn |> json(params)
      end
    end

    test "works with basic POST params" do
      route_info = route_from_module(BasicPostApi, :post, ["res1"])
      assert [
        %{description: "", in: "formData", name: "user_name", required: true, type: "string"},
        %{description: "", in: "formData", name: "email", required: true, type: "string"},
      ] == extract_params(route_info)
    end

    test "force json" do
      route_info = route_from_module(BasicPostApi, :post, ["res1"])
      assert [
        %{description: "", in: "body", name: "body", required: false, schema: %{properties: %{"email" => %{description: "", required: true, type: "string"}, "user_name" => %{description: "", required: true, type: "string"}}}}
      ] == extract_params(route_info, %{force_json: true})
    end

    test "basic POST params in path" do
      route_info = route_from_module(BasicPostApi, :post, ["123"])
      assert [
        %{description: "", in: "path", name: "foo", required: true, type: "integer"},
      ] == extract_params(route_info)
    end
  end


  describe "more extensive POST example" do
    defmodule BasicTest.Homepage do
      use Maru.Router
      desc "root page"
      params do
        requires :id, type: Integer
        optional :query, type: List do
          optional :keyword, type: String
        end
      end
      post "/list" do
        _ = params
        conn |> json(%{ hello: :world })
      end

      desc "complex post"
      params do
        requires :name, type: :map do
          requires :first, type: :string
          requires :last, type: :string
        end
        requires :email, type: :string
        optional :age, type: :integer, desc: "age information"
      end
      post "/map" do
        conn |> json(params)
      end

      desc "dependent params"
      params do
        requires :foo, type: Integer
        given [foo: fn val -> val > 10 end] do
          optional :bar
          given :bar do
            requires :qux
          end
        end
        given [foo: fn val -> val < 10 end] do
          requires :baz
        end
      end
      post "/dependent" do
        conn |> json(params)
      end

    end

    defmodule BasicTest.Api do
      use Maru.Router
      mount MaruSwagger.ParamsExtractorTest.BasicTest.Homepage
    end

    test "extracts expected swagger data from nested list params" do
      route_info = route_from_module(BasicTest.Homepage, :post, ["list"])
      assert [
        %{ description: "", in: "body", name: "body", required: false, schema: %{
           properties: %{
             "id" => %{ description: "", required: true, type: "integer" },
             "query" => %{ items: %{properties: %{
               "keyword" => %{ description: "", required: false, type: "string"}
             }, type: "object" }, type: "array" }}}}
      ] = extract_params(route_info)
    end

    test "extracts expected swagger data from nested map params" do
      route_info = route_from_module(BasicTest.Homepage, :post, ["map"])
      assert [
        %{ description: "", in: "body", name: "body", required: false, schema: %{
           properties: %{
             "age" => %{ description: "age information", required: false, type: "integer" },
             "email" => %{ description: "", required: true, type: "string" },
             "name" => %{ type: "object", properties: %{
               "first" => %{ description: "", required: true, type: "string" },
               "last" => %{ description: "", required: true, type: "string" },
                          }}}}}
      ] = extract_params(route_info)
    end

    test "dependent params" do
      route_info = route_from_module(BasicTest.Homepage, :post, ["dependent"])
      assert [
        %{name: "foo", required: true, type: "integer"},
        %{name: "bar", required: false, type: "string"},
        %{name: "qux", required: false, type: "string"},
        %{name: "baz", required: false, type: "string"},
      ] = extract_params(route_info)
    end
  end

  describe "one-line nested list test" do
    defmodule OneLineNestedList do
      use Maru.Router

      desc "one-line nested list test"
      params do
        requires :foo, type: List[String]
      end
      post "/path" do
        conn |> json(params)
      end
    end

    test "one-line nested list test" do
      route_info = route_from_module(OneLineNestedList, :post, ["path"])
      assert [
        %{ description: "", in: "body", name: "body", required: false, schema: %{
             properties: %{"foo" => %{
               type: "array", items: %{type: "string"}
             }}
        }}
      ] = extract_params(route_info)
    end
  end

  describe "validation in parameters test" do
    defmodule ValidationInParametes do
      use Maru.Router

      desc "validation in parameters list test"
      params do
        requires :foo
        requires :bar
        all_or_none_of [:foo, :bar]
      end
      get "/path" do
        conn |> json(params)
      end
    end

    test "validation in parameters test" do
      route_info = route_from_module(ValidationInParametes, :get, ["path"])
      assert [%{name: "foo"}, %{name: "bar"}] = extract_params(route_info)
    end
  end

end
