defmodule Hanyutils.MixProject do
  use Mix.Project

  @source_url "https://github.com/mathsaey/hanyutils"

  def project do
    [
      app: :hanyutils,
      version: "0.3.0",
      elixir: "~> 1.9",
      deps: deps(),
      package: package(),
      description: description(),
      docs: docs()
    ]
  end

  defp deps do
    [
      {:nimble_parsec, "~> 1.2"},
      {:ex_doc, "~> 0.28", only: :dev, runtime: false},
      {:dialyxir, "~> 1.2", only: [:dev], runtime: false}
    ]
  end

  defp description do
    """
    Flexible, modular, utilities for dealing with Chinese characters and pinyin.
    """
  end

  defp docs do
    [
      main: "readme",
      source_url: @source_url,
      extras: [
        "README.md"
      ]
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{GitHub: @source_url}
    ]
  end
end
