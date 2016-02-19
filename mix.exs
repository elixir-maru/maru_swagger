defmodule MaruSwagger.Mixfile do
  use Mix.Project

  def project do
    [ app: :maru_swagger,
      version: "0.7.1",
      elixir: "~> 1.0",
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
    [ { :maru, "~> 0.9"} ]
  end

  defp package do
    %{ licenses: ["BSD 3-Clause"],
       links: %{"Github" => "https://github.com/falood/maru_swagger"}
     }
  end
end
