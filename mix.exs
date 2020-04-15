defmodule Bloomex.Mixfile do
  use Mix.Project

  @description """
  Bloomex is a pure Elixir implementation of Scalable Bloom Filters.
  """
  @github "https://github.com/gmcabrita/bloomex"

  def project() do
    [
      app: :bloomex,
      name: "Bloomex",
      source_url: @github,
      homepage_url: nil,
      version: "1.2.0",
      elixir: "~> 1.6",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      description: @description,
      package: package(),
      deps: deps(),
      aliases: aliases(),
      preferred_cli_env: [
        ci: :test
      ],
      test_coverage: [tool: ExCoveralls],
      docs: docs(),
      dialyzer_ignored_warnings: [
        {:warn_contract_supertype, :_, {:extra_range, [:_, :__protocol__, 1, :_, :_]}}
      ]
    ]
  end

  def application() do
    []
  end

  defp docs() do
    [
      main: "readme",
      logo: nil,
      extras: ["README.md"]
    ]
  end

  defp deps() do
    [
      {:excoveralls, "~> 0.10", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.16", only: [:dev, :docs], runtime: false},
      {:dialyzex, "~> 1.2.0", only: [:dev, :test], runtime: false},
      {:jason, "~> 1.1"}
    ]
  end

  defp package() do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE"],
      maintainers: ["Gonçalo Cabrita"],
      licenses: ["MIT"],
      links: %{"GitHub" => @github}
    ]
  end

  defp aliases do
    [
      ci: [
        "format --check-formatted",
        "test",
        "dialyzer"
      ]
    ]
  end
end
