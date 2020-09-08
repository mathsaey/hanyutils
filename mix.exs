defmodule Hanyutils.MixProject do
  use Mix.Project

  def project do
    [
      app: :hanyutils,
      version: "0.2.1",
      elixir: "~> 1.9",
      deps: deps(),
      package: package(),
      description: description(),
      source_url: "https://github.com/mathsaey/hanyutils"
    ]
  end

  defp deps do
    [
      {:nimble_parsec, "~> 0.6"},
      {:ex_doc, "~> 0.22", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false}
    ]
  end

  defp description do
    "Utilities for dealing with Chinese characters and pinyin."
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{github: "https://github.com/mathsaey/hanyutils"}
    ]
  end
end
