defmodule Bloomex.Mixfile do
  use Mix.Project

  @description """
  Bloomex is a pure Elixir implementation of Scalable Bloom Filters.
  """

  def project do
    [app: :bloomex,
     version: "1.0.0",
     elixir: "~> 1.0",
     description: @description,
     package: package,
     deps: deps,
     aliases: [
        dialyze: "dialyze \
                    --unmatched-returns \
                    --error-handling \
                    --race-conditions \
                    --underspecs"
      ],
     test_coverage: [tool: ExCoveralls]]
  end

  def application do
    [applications: []]
  end

  defp deps do
    [{:excoveralls, "~> 0.3", only: :docs},
     {:earmark, "~> 0.1", only: :docs},
     {:ex_doc, "~> 0.10", only: :docs},
     {:inch_ex, only: :docs},
     {:dialyze, "~> 0.2.0", only: [:dev, :test]}
    ]
  end

  defp package do
    [files: ["lib", "mix.exs", "README.md", "LICENSE"],
     maintainers: ["Gonçalo Cabrita"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/gmcabrita/bloomex"}
    ]
  end
end
