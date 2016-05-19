defmodule MaruSwagger.PlugTest do
  use ExSpec, async: true
  doctest MaruSwagger
  import TestHelper
  alias MaruSwagger.ConfigStruct


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
      mount MaruSwagger.PlugTest.BasicTest.Homepage
    end


    it "includes the required params" do
      %ConfigStruct{module: MaruSwagger.PlugTest.BasicTest.Api}
      |> MaruSwagger.Plug.generate
      |> assert_route_info("/",
        %{ "get" => %{
             description: "hello world action",
             parameters: [
               %{description: "", in: "query", name: :id, required: true, type: "integer"}
             ],
             responses: %{"200" => %{description: "ok"}},
             tags: ["DEFAULT"],
           }
        }
      )
    end
  end

end
