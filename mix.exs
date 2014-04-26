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
      applications: [:lax, :httpoison, :jazz, :exlager]
    ]
  end

  defp deps do
    [
      {:idna, github: "benoitc/erlang-idna", override: true},
      {:hackney, github: "benoitc/hackney", override: true},
      {:hackney_lib, github: "benoitc/hackney_lib", override: true},
      {:lax, github: "d0rc/lax"},
      {:httpoison, github: "d0rc/httpoison"},
      {:exactor, github: "sasa1977/exactor"},
      {:exlager, github: "khia/exlager"},
      {:jazz, github: "meh/jazz"}
    ]
  end
end
