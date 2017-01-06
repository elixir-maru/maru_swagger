MaruSwagger
===========

[![Build status](https://img.shields.io/travis/elixir-maru/maru_swagger.svg?style=flat-square)](https://travis-ci.org/elixir-maru/maru_swagger)
[![hex.pm Version](https://img.shields.io/hexpm/v/maru_swagger.svg?style=flat-square)](https://hex.pm/packages/maru_swagger)
[![Hex downloads](https://img.shields.io/hexpm/dt/maru_swagger.svg?style=flat-square)](https://hex.pm/packages/maru_swagger)

## Usage

GOTCHA: Please keep `swagger` DSL out of `version`!

```elixir
def deps do
  [ {:maru_swagger, github: "elixir-maru/maru_swagger"} ]
end

defmodule Router do
  version "v1"
  ...
end

defmodule API do
  use Maru.Router
  use MaruSwagger

  plug Plug.Logger

  swagger at:         "/swagger",      # (required) the mount point for the URL
          pretty:     true,            # (optional) should JSON be pretty-printed?
          only:       [:dev],          # (optional) the environments swagger works
          except:     [:prod],         # (optional) the environments swagger NOT works
          force_json: true,            # (optional) force JSON for all params instead of formData

          swagger_inject: [            # (optional) this will be directly injected into the root Swagger JSON
            host: "myapi.com",
            basePath: "/api",
            schemes:  [ "http" ],
            consumes: [ "application/json" ],
            produces: [
              "application/json",
              "application/vnd.api+json"
            ]
          ]

  mount Router
end
```

and then you can get json response from `curl http://127.0.0.1:4000/swagger`.

open [Swagger Petstore](http://petstore.swagger.io) in your borwser and fill in `http://127.0.0.1:4000/swagger` and enjoy maru_swagger.


## Thanks

* [Cifer](https://github.com/Cifer-Y)
* [Roman Heinrich](https://github.com/mindreframer)
