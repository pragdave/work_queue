defmodule WorkQueue.Mixfile do
  use Mix.Project

  def project do
    [app:     :work_queue,
     version: "0.0.1",
     elixir:  ">= 1.0.0",
     deps: deps]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [
        pipe_while_ok: ">0.0.0"
    ]
  end
end
