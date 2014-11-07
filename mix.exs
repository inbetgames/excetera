defmodule Excetera.Mixfile do
  use Mix.Project

  def project do
    [
      app: :excetera,
      version: "0.0.1",
      elixir: "~> 1.0.0",
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
      {:httpoison, "~> 0.5.0"},
      {:jazz, "~> 0.2.1"}
    ]
  end
end
