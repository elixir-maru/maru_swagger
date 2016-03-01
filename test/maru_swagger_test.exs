defmodule MaruSwaggerTest do
  use ExSpec, async: true
  doctest MaruSwagger
  import TestHelper


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
    end


    defmodule BasicTest.Api do
      use Maru.Router
      mount MaruSwaggerTest.BasicTest.Homepage
    end

    @swagger_docs MaruSwagger.generate(MaruSwaggerTest.BasicTest.Api, nil, ["/"])

    it "includes the required params" do
      @swagger_docs |>
        assert_route_info("",
          %{"get" => %{description: "hello world action", parameters: [%{description: "", in: "query", name: :id, required: true, type: "integer"}],
               responses: %{"200" => %{description: "ok"}}}}
        )
    end
  end
end
