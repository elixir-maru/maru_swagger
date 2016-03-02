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



  describe "MaruSwagger - Plug: init options" do
    def init(opts) do
      opts |> MaruSwagger.init
    end

    it "requires :at for mounting point" do
      assert {["swagger", "v1"], MaruSwaggerTest.BasicTest.Api, nil, false, [] } == init(
        at: "swagger/v1",
        for: BasicTest.Api
      )
    end

    it "raises without :at" do
      assert_raise KeyError, "key :at not found in: [for: MaruSwaggerTest.BasicTest.Api]", fn ->
        init(for: BasicTest.Api)
      end
    end

    it "accepts :version for specified version" do
      assert {["swagger", "v1"], MaruSwaggerTest.BasicTest.Api, "v1", false, [] } == init(
        at: "swagger/v1",
        version: "v1",
        for: BasicTest.Api
      )
    end

    it "accepts :pretty for JSON output" do
      assert {["swagger", "v1"], MaruSwaggerTest.BasicTest.Api, "v1", true, [] } == init(
        at: "swagger/v1",
        version: "v1",
        pretty: true,
        for: BasicTest.Api
      )
    end

    it "accepts :prefix to prepend to URLs" do
      assert {["swagger", "v1"], MaruSwaggerTest.BasicTest.Api, "v1", true, "/longish/prefix" } == init(
        at: "swagger/v1",
        version: "v1",
        pretty: true,
        prefix: "/longish/prefix",
        for: BasicTest.Api
      )
    end
  end
end
