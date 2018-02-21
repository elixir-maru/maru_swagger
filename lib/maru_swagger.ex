defmodule MaruSwagger do
  defmacro __using__(_) do
    quote do
      import MaruSwagger.DSL
    end
  end
end
