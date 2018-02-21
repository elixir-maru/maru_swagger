defmodule MaruSwagger.ResponseFormatterTest do
  use ExUnit.Case, async: true
  doctest MaruSwagger.ResponseFormatter
  alias MaruSwagger.ConfigStruct
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
        _ = params
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

    defmodule BasicTest.API do
      use Maru.Router, make_plug: true
      use MaruSwagger

      swagger at:     "/swagger/v1.json", # (required) the mount point for the URL
              pretty: true,               # (optional) should JSON be pretty-printed?
              swagger_inject: [           # (optional) this will be directly injected into the root Swagger JSON
                host:     "myapi.com",
                basePath: "/api",
                schemes:  [ "http" ],
                consumes: [ "application/json" ],
                produces: [
                  "application/json",
                  "application/vnd.api+json"
                ]
              ]

      mount MaruSwagger.ResponseFormatterTest.BasicTest.Homepage
    end

    test "includes basic information for swagger (title, API version, Swagger version)" do
      swagger_docs =
        %ConfigStruct{
          module: MaruSwagger.ResponseFormatterTest.BasicTest.Homepage,
        } |> MaruSwagger.Plug.generate


      assert swagger_docs |> get_in([:info, :title]) == "Swagger API for MaruSwagger.ResponseFormatterTest.BasicTest.Homepage"
      assert swagger_docs |> get_in([:swagger]) == "2.0"
    end

    test "works in full integration" do
      json = get_response(BasicTest.API, conn(:get, "/swagger/v1.json"))
      assert json.basePath == "/api"
      assert json.host == "myapi.com"
    end
    test "swagger info config" do

      swagger_docs =
        %ConfigStruct{
          module: MaruSwagger.ResponseFormatterTest.BasicTest.Homepage,
          info: [title: "title", desc: "description"]
        } |> MaruSwagger.Plug.generate

      assert swagger_docs |> get_in([:info, :title]) == "title"
      assert swagger_docs |> get_in([:info, :description]) == "description"
      assert swagger_docs |> get_in([:swagger]) == "2.0"
    end
  end
end
