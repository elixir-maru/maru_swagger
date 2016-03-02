MaruSwagger
===========

[![Build status](https://travis-ci.org/falood/maru_swagger.svg "Build status")](https://travis-ci.org/falood/maru_swagger)
[![hex.pm Version](https://img.shields.io/hexpm/v/maru_swagger.svg)](https://hex.pm/packages/maru_swagger)
![Hex downloads](https://img.shields.io/hexpm/dt/maru_swagger.svg "Hex downloads")


## Usage

NOTE: `maru_swagger` is only works for `:dev`

GOTCHA: Please keep `MaruSwagger` plug out of `version` DSL!

```elixir
def deps do
  [ {:maru_swagger, "~> 0.7", only: :dev} ]
end

defmodule Router do
  version "v1"
  ...
end

defmodule API do
  use Maru.Router

  plug Plug.Logger
  if Mix.env == :dev do
    plug MaruSwagger,
      at:      "/swagger/v1.json", # (required) the mount point for the URL
      for:     Router,             # (required) if missing is taken from config.exs
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

  mount Router
end
```

and then you can get json response from `curl http://127.0.0.1:4000/swagger/v1`.

open [Swagger Petstore](http://petstore.swagger.io) in your borwser and fill in `http://127.0.0.1:4000/swagger/v1` and enjoy maru_swagger.


## Thanks

* [Cifer](https://github.com/Cifer-Y)
* [Roman Heinrich](https://github.com/mindreframer)
