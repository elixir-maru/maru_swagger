defmodule MaruSwagger.Mixfile do
  use Mix.Project

  def project do
    [ app: :maru_swagger,
      version: "0.8.0-dev",
      elixir: "~> 1.1",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps,
      description: "Add swagger compliant documentation to your maru API",
      source_url: "https://github.com/falood/maru_swagger",
      package: package,
    ]
  end

  def application do
    []
  end

  defp deps do
    [ { :maru,    "~> 0.10-dev"},
      { :ex_spec, "~> 1.0", only: :test },
    ]
  end

  defp package do
    %{ licenses: ["BSD 3-Clause"],
       links: %{"Github" => "https://github.com/falood/maru_swagger"}
     }
  end
end
