defmodule Excetera.Mixfile do
  use Mix.Project

  def project do
    [
      app: :excetera,
      version: "0.0.1",
      elixir: "~> 0.14.0",
      deps: deps
    ]
  end

  def application do
    [
      mod: { Excetera.Application, [] },
      applications: [:httpoison, :jazz],
      env: [etcd_url: "http://127.0.0.1:4001/v2/keys"],
    ]
  end

  defp deps do
    [
      {:httpoison, github: "edgurgel/httpoison"},
      {:jazz, github: "meh/jazz"}
    ]
  end
end
