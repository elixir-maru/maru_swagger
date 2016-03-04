defmodule MaruSwagger.ResponseFormatterTest do
  use ExSpec, async: true
  doctest MaruSwagger.ResponseFormatter
  import Plug.Test

  describe "basic test" do
    def get_response(module, conn) do
      res = module.call(conn, [])
      {:ok, json} = res.resp_body  |> Poison.decode(keys: :atoms)
      json
    end

    defmodule BasicTest.Homepage do
      use Maru.Router
      version "v1"

      desc "hello world action"
      params do
        requires :id, type: Integer
      end
      get "/" do
        conn |> json(%{ hello: :world })
      end

      desc "creates res1"
      params do
        requires :name, type: String
        requires :email, type: String
      end
      post "/res1" do
        conn |> json(params)
      end
    end

    defmodule BasicTest.Api do
      use Maru.Router
      version "v1"
      mount MaruSwagger.ResponseFormatterTest.BasicTest.Homepage
    end

    defmodule BasicTest.Swagger do
      use Maru.Router
      plug MaruSwagger,
        at:      "/swagger/v1.json", # (required) the mount point for the URL
        for:     BasicTest.Api,      # (required) if missing is taken from config.exs
        version: "v1",               # (optional) what version should be considered during Swagger JSON generation?
        prefix:  ["v1"],             # (optional) in case you need a prefix for the URLs in Swagger JSON
        pretty:  true,               # (optional) should JSON be pretty-printed?
        swagger_inject: [            # (optional) this will be directly injected into the root Swagger JSON
          host: "myapi.com",
          basePath: "/",
          schemes:  [ "http" ],
          consumes: [ "application/json" ],
          produces: [
            "application/json",
            "application/vnd.api+json"
          ]
        ]
    end

    it "includes basic information for swagger (title, API version, Swagger version)" do
      swagger_docs = MaruSwagger.generate(MaruSwagger.ResponseFormatterTest.BasicTest.Api, "v1", ["/"])
      assert swagger_docs |> get_in([:info, :title]) =~ "MaruSwagger.ResponseFormatterTest.BasicTest.Api"
      assert swagger_docs |> get_in([:info, :version]) == "v1"
      assert swagger_docs |> get_in([:swagger]) == "2.0"
    end

    it "works in full integration" do
      json = get_response(BasicTest.Swagger, conn(:get, "/swagger/v1.json"))
      assert json.basePath == "/"
      assert json.host == "myapi.com"
    end
  end
end
