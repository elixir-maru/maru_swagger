defmodule MaruSwagger.Mixfile do
  use Mix.Project

  def project do
    [ app: :maru_swagger,
      version: "0.8.2",
      elixir: "~> 1.3 or ~> 1.4",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),
      description: "Add swagger compliant documentation to your maru API",
      source_url: "https://github.com/Skipper1992/maru_swagger",
      package: package(),
      docs: [
        extras: ["README.md"],
        main: "readme",
      ]
    ]
  end

  def application do
    []
  end

  defp deps do
    [ { :maru,   github: "Skipper1992/maru" },
      { :ex_doc, "~> 0.14", only: :docs },
    ]
  end

  defp package do
    %{ maintainers: ["Xiangrong Hao", "Roman Heinrich", "Cifer"],
       licenses: ["BSD 3-Clause"],
       links: %{"Github" => "https://github.com/Skipper1992/maru_swagger"}
     }
  end
end
