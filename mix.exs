defmodule WorkQueue.Mixfile do
  use Mix.Project

  def project do
    [app:         :work_queue,
     version:     "0.0.1",
     elixir:      ">= 1.0.0",
     deps:        deps,
     description: description,
     package:     package,
    ]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [
        pipe_while_ok: ">0.0.0"
    ]
  end

  defp description do
    """
    A simple implement of the Hungry Consumer model of concurrent servers.
    """
  end

  defp package do
    [
      files:        [ "lib", "mix.exs", "README.md", "LICENSE.md" ],
      contributors: [ "Dave Thomas <dave@pragprog.org>"],
      licenses:     [ "MIT. See LICENSE.md" ],
      links:        %{
                       "GitHub" => "https://github.com/pragdave/work_queue",
                    }
    ]
  end
end
