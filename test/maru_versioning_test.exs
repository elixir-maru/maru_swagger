defmodule MaruVersioningTest do
  use ExUnit.Case, async: true
  doctest MaruSwagger
  alias MaruSwagger.ConfigStruct


  describe "basic test" do
    defmodule BasicTest.Homepage do
      use Maru.Router

      desc "basic get" do
        detail "detail of basic get"
        responses do
          status :default, desc: "ok"
          status 500, desc: "error"
        end
      end
      params do
        requires :id, type: Integer
      end
      get "/basic" do
        conn |> json(%{ id: params.id })
      end
    end

    defmodule BasicTest.Api do
      use Maru.Router

      version "v1" do
        get "/bla" do
          conn |> json(%{})
        end
        mount MaruVersioningTest.BasicTest.Homepage
      end
    end

    test "includes the API version" do
      swagger_docs =
        %ConfigStruct{
          module: MaruVersioningTest.BasicTest.Api,
        } |> MaruSwagger.Plug.generate
      assert swagger_docs.tags == [%{name: "Version: v1"}]
    end

    test "includes the paths information" do
      swagger_docs =
        %ConfigStruct{
          module: MaruVersioningTest.BasicTest.Api,
        } |> MaruSwagger.Plug.generate
      assert %{
        "/basic" => %{
          "get" => %{
            summary: "basic get",
            description: "detail of basic get",
            parameters: [
              %{description: "", in: "query", name: "id", required: true, type: "integer"}
            ],
            responses: %{
              "default" => %{description: "ok"},
              "500" => %{description: "error"},
            },
            tags: ["Version: v1"],
          }
        },
        "/bla" => %{
          "get" => %{
            summary: "",
            description: "",
            parameters: [],
            responses: %{"200" => %{description: "ok"}},
            tags: ["Version: v1"],
          }
        }
      } = swagger_docs.paths
    end
  end


  describe "with different versions" do
    defmodule DiffVersions.Homepage do
      use Maru.Router

      version "v2" do
        desc "basic get"
        params do
          requires :id, type: Integer
        end
        get "/basic" do
          conn |> json(%{ id: params.id })
        end
      end
    end

    defmodule DiffVersions.Api do
      use Maru.Router

      version "v1" do
        get "/bla" do
          conn |> json(%{})
        end
      end
      mount MaruVersioningTest.DiffVersions.Homepage
    end

    test "returns only docs for specified version" do
      swagger_docs =
        %ConfigStruct{
          module: MaruVersioningTest.DiffVersions.Api,
        } |> MaruSwagger.Plug.generate
      assert swagger_docs.tags == [%{name: "Version: v1"}, %{name: "Version: v2"}]
      assert %{
        "/bla" => %{
          "get" => %{
            tags: ["Version: v1"],
          }
        },
        "/basic" => %{
          "get" => %{
            tags: ["Version: v2"],
          }
        }
      } = swagger_docs.paths
    end
  end
end
