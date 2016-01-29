MaruSwagger
===========

[![hex.pm Version](https://img.shields.io/hexpm/v/maru_swagger.svg)](https://hex.pm/packages/maru_swagger)

## Usage

NOTE: `maru_swagger` is only works for `:dev`

Please keep `MaruSwagger` plug out of `version` dsl.

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
      version: "v1",
      at:      "/swagger/v1",
      pretty:  true
  end

  mount Router
end
```

and then you can get json response from `curl http://127.0.0.1:4000/swagger/v1`.

open [Swagger Petstore](http://petstore.swagger.io) in your borwser and fill in `http://127.0.0.1:4000/swagger/v1` and enjoy maru_swagger.


## TODO
- [ ] unit test
- [x] multi version support
- [x] beautifier json response

## Thanks

* [Cifer](https://github.com/Cifer-Y)
