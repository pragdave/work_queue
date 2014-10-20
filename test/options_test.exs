defmodule OptionsTest do
  use ExUnit.Case
  import WorkQueue.Options, only: [analyze: 2, processing_units: 0]

  defp defaults(overrides \\ %{}) do
    %{
      worker_count:             4,
      report_each_result_to:    :rrt,
      report_progress_to:       :rpt,
      report_progress_interval: 123,
      worker_args:              [],
    }
    |> Dict.merge(overrides)
  end

  test "no options returns defaults" do
    given  = %{ opts: [] }
    expect = { :ok, %{ opts: defaults } }
    assert expect == analyze(given, defaults)
  end

  test "can override report_each_result_to" do
    callback = fn _ -> 0 end
    given  = %{ opts: [ report_each_result_to: callback ] }
    expect = { :ok, %{ opts: defaults(report_each_result_to: callback)  } }
    assert expect == analyze(given, defaults)
  end
  
  test "can override report_progress_to" do
    callback = fn _ -> 0 end
    given  = %{ opts: [ report_progress_to: callback ] }
    expect = { :ok, %{ opts: defaults(report_progress_to: callback)  } }
    assert expect == analyze(given, defaults)
  end

  test "can override report_progress_interval" do
    given  = %{ opts: [ report_progress_interval: 1234 ] }
    expect = { :ok, %{ opts: defaults(report_progress_interval: 1234)  } }
    assert expect == analyze(given, defaults)
  end

  test "worker_args accepts list" do
    given  = %{ opts: [ worker_args: [1,2,3] ] }
    expect = { :ok, %{ opts: defaults(worker_args: [1,2,3])  } }
    assert expect == analyze(given, defaults)
  end

  test "worker_args accepts single term" do
    given  = %{ opts: [ worker_args: 123 ] }
    expect = { :ok, %{ opts: defaults(worker_args: [123])  } }
    assert expect == analyze(given, defaults)
  end

  test "absolute worker count can be set" do
    given  = %{ opts: [ worker_count: 12 ] }
    expect = { :ok, %{ opts: defaults(worker_count: 12)  } }
    assert expect == analyze(given, defaults)
  end

  test "ratio worker count can be given" do
    given  = %{ opts: [ worker_count: 2.0 ] }
    expect = { :ok, %{ opts: defaults(worker_count: 2 * processing_units)  } }
    assert expect == analyze(given, defaults)
  end

  test "cpu_bound returns full house of workers" do
    given  = %{ opts: [ worker_count: :cpu_bound ] }
    expect = { :ok, %{ opts: defaults(worker_count: processing_units)  } }
    assert expect == analyze(given, defaults)
  end
  
  test "io_bound returns overcommits workers by a factor of 10" do
    given  = %{ opts: [ worker_count: :io_bound ] }
    expect = { :ok, %{ opts: defaults(worker_count: 10*processing_units)  } }
    assert expect == analyze(given, defaults)
  end
  
  test "invalid option is rejected" do
    given  = %{ opts: [ invalid: 1234 ] }
    expect = { :error, "Invalid option [ invalid: 1234 ] to Elixir.WorkQueue.Options"}
    assert expect == analyze(given, defaults)
  end

  test "zero worker cout\nt is rejected" do
    given  = %{ opts: [ worker_count: 0 ] }
    expect = { :error, "Invalid option [ worker_count: 0 ] to Elixir.WorkQueue.Options"}
    assert expect == analyze(given, defaults)
  end

  test "negative worker cout\nt is rejected" do
    given  = %{ opts: [ worker_count: -1.5 ] }
    expect = { :error, "Invalid option [ worker_count: -1.5 ] to Elixir.WorkQueue.Options"}
    assert expect == analyze(given, defaults)
  end
  
end
