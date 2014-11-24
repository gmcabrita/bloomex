defmodule Bloomex.Mixfile do
  use Mix.Project

  @description """
  Bloomex is a pure Elixir implementation of Scalable Bloom Filters.
  """

  def project do
    [app: :bloomex,
     version: "0.2.0",
     elixir: "~> 1.0",
     description: @description,
     package: package,
     deps: deps,
     test_coverage: [tool: ExCoveralls]]
  end

  def application do
    [applications: []]
  end

  defp deps do
    [
      {:excoveralls, "~> 0.3", only: :dev}
    ]
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE"],
      contributors: ["Gonçalo Cabrita"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/gmcabrita/bloomex"}
    ]
  end
end
