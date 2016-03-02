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


    it "param :for -> raises if not provided and not configured in config.exs" do
      assert_raise RuntimeError, "missing configured module for Maru in config.exs (MaruSwagger depends on it!)", fn ->
        init(at: "/swagger/v1")
      end
    end

    it "requires :at for mounting point" do
      assert %MaruSwagger.ConfigStruct{
        module: MaruSwaggerTest.BasicTest.Api,
        path: ["swagger", "v1"],
        prefix: [],
        pretty: false,
        version: nil
      } == init(
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
      assert %MaruSwagger.ConfigStruct{
        module: MaruSwaggerTest.BasicTest.Api,
        path: ["swagger", "v1"],
        prefix: [],
        pretty: false,
        version: "v1"
      } == init(
        at: "swagger/v1",
        version: "v1",
        for: BasicTest.Api
      )
    end

    it "accepts :pretty for JSON output" do
      assert %MaruSwagger.ConfigStruct{
        module: MaruSwaggerTest.BasicTest.Api,
        path: ["swagger", "v1"],
        prefix: [],
        pretty: true,
        version: "v1"
      } == init(
        at: "swagger/v1",
        version: "v1",
        pretty: true,
        for: BasicTest.Api
      )
    end

    it "accepts :prefix to prepend to URLs" do
      assert %MaruSwagger.ConfigStruct{
          module: MaruSwaggerTest.BasicTest.Api,
          path: ["swagger", "v1"],
          prefix: ["longish", "prefix"],
          pretty: true,
          version: "v1"
        } == init(
        at: "swagger/v1",
        version: "v1",
        pretty: true,
        prefix: ["longish", "prefix"],
        for: BasicTest.Api
      )
    end
  end
end
