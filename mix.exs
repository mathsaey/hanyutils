defmodule Hanyutils.MixProject do
  use Mix.Project

  def project do
    [
      app: :hanyutils,
      version: "0.1.0",
      elixir: "~> 1.9",
      description: description(),
      package: package(),
      deps: deps()
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.21", only: :dev, runtime: false}
    ]
  end

  defp description do
    "Utilities for dealing with Chinese characters and pinyin."
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{github: "https://github.com/mathsaey/hanyutils"},
      source_url: "https://github.com/mathsaey/hanyutils"
    ]
  end
end
