defmodule MaruSwagger.ResponseFormatterTest do
  use ExSpec, async: true
  doctest MaruSwagger.ResponseFormatter


  describe "basic test" do
    defmodule BasicTest.Homepage do
      use Maru.Router

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
      mount MaruSwagger.ResponseFormatterTest.BasicTest.Homepage
    end

    @swagger_docs MaruSwagger.generate(MaruSwagger.ResponseFormatterTest.BasicTest.Api, nil, ["/"])

    it "includes basic information for swagger (title, API version, Swagger version)" do
      assert @swagger_docs |> get_in([:info, :title]) =~ "MaruSwagger.ResponseFormatterTest.BasicTest.Api"
      assert @swagger_docs |> get_in([:info, :version]) == nil
      assert @swagger_docs |> get_in([:swagger]) == "2.0"
    end
  end
end
