defmodule MaruVersioningTest do
  use ExSpec, async: true
  doctest MaruSwagger
  import TestHelper

  describe "basic test" do
    defmodule BasicTest.Homepage do
      use Maru.Router
      version "v1" do
        desc "basic get"
        params do
          requires :id, type: Integer
        end
        get "/basic" do
          conn |> json(%{ id: params.id })
        end
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

    it "includes the API version" do
      swagger_docs = MaruSwagger.generate(MaruVersioningTest.BasicTest.Api, "v1", ["/"])
      assert swagger_docs.info.version == "v1"
    end

    it "includes the paths information" do
      swagger_docs = MaruSwagger.generate(MaruVersioningTest.BasicTest.Api, "v1", ["/"])
      assert swagger_docs.paths == %{"basic" => %{"get" => %{description: "basic get", parameters: [%{description: "", in: "query", name: :id, required: true, type: "integer"}],
                 responses: %{"200" => %{description: "ok"}}}}, "bla" => %{"get" => %{description: "", parameters: [], responses: %{"200" => %{description: "ok"}}}}}
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
        mount MaruVersioningTest.DiffVersions.Homepage
      end
    end

    it "returns only docs for specified version" do
      swagger_docs = MaruSwagger.generate(MaruVersioningTest.DiffVersions.Api, "v1", ["/"])
      assert swagger_docs.info.version == "v1"
      assert swagger_docs.paths == %{"bla" => %{"get" => %{description: "", parameters: [], responses: %{"200" => %{description: "ok"}}}}}


      swagger_docs = MaruSwagger.generate(MaruVersioningTest.DiffVersions.Api, "v2", ["/"])
      assert swagger_docs.info.version == "v2"
      assert swagger_docs.paths == %{"basic" => %{"get" => %{description: "basic get", parameters: [%{description: "", in: "query", name: :id, required: true, type: "integer"}],
                 responses: %{"200" => %{description: "ok"}}}}}

    end
  end
end
