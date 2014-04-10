defmodule Diamorfosi.Mixfile do
  use Mix.Project

  def project do
    [ app: :diamorfosi,
      version: "0.0.1",
      deps: deps ]
  end

  def application do
    [
      mod: { Diamorfosi, [] },
      applications: [:httpoison, :jazz]
    ]
  end

  defp deps do
    [
      {:httpoison, github: "edgurgel/httpoison"},
      {:jazz, github: "meh/jazz"}
    ]
  end
end
