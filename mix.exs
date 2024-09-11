defmodule Flint.MixProject do
  use Mix.Project

  def project do
    [
      app: :flint,
      name: "Flint",
      version: "0.3.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description:
        "Declarative Ecto embedded schemas for data validation, coercion, and manipulation.",
      source_url: "https://github.com/acalejos/flint",
      homepage_url: "https://github.com/acalejos/flint",
      package: package(),
      docs: docs(),
      preferred_cli_env: [
        docs: :docs,
        "hex.publish": :docs
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ecto, "~> 3.12"},
      {:jason, "~> 1.4", optional: true},
      {:ex_doc, "~> 0.31.0", only: :docs}
    ]
  end

  defp package do
    [
      maintainers: ["Andres Alejos"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/acalejos/flint"}
    ]
  end

  defp docs do
    [
      main: "Flint",
      groups_for_extras: [
        Notebooks: Path.wildcard("notebooks/*.livemd")
      ]
    ]
  end
end
