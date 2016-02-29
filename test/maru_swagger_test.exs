defmodule MaruSwaggerTest do
  use ExSpec, async: true
  doctest MaruSwagger


  describe "basic test" do
    defmodule BasicTest.Homepage do
      use Maru.Router

      desc "hello world action"
      params do
        requires :id, type: Integer
      end
      get do
        %{ hello: :world }
      end
    end

    defmodule BasicTest.Api do
      use Maru.Router
      mount MaruSwaggerTest.BasicTest.Homepage
      rescue_from :all do
        conn
        |> put_status(500)
        |> text("Server Error")
      end
    end


    it "works" do
      res = MaruSwagger.generate(MaruSwaggerTest.BasicTest.Api, nil, ["/"])
      expected = %{info: %{title: "Swagger API for MaruSwaggerTest.BasicTest.Api", version: nil},
  paths: %{"" => %{"get" => %{description: "hello world action", parameters: [],
        responses: %{"200" => %{description: "ok"}}}}}, swagger: "2.0"}

      assert res == expected
    end
  end
end
