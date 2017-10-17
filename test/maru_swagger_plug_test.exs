defmodule MaruSwagger.PlugTest do
  use ExUnit.Case, async: true
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
        _ = params
        conn |> json(%{ hello: :world })
      end
    end


    defmodule BasicTest.Api do
      use Maru.Router

      mount MaruSwagger.PlugTest.BasicTest.Homepage
    end


    test "includes the required params" do
      %ConfigStruct{module: MaruSwagger.PlugTest.BasicTest.Api}
      |> MaruSwagger.Plug.generate
      |> assert_route_info("/",
        %{ "get" => %{
             summary: "hello world action",
             description: "",
             parameters: [
               %{description: "", in: "query", name: "id", required: true, type: "integer"}
             ],
             responses: %{"200" => %{description: "ok"}},
             tags: ["DEFAULT"],
           }
        }
      )
    end
  end

end
