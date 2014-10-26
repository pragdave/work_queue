defmodule OptionsTest do
  use ExUnit.Case
  import WorkQueue.Options, only: [analyze: 2, processing_units: 0]

  defp default_options(overrides \\ %{}) do
    %{
      worker_count:             4,
      report_each_result_to:    :rrt,
      report_progress_to:       :rpt,
      report_progress_interval: 123,
      worker_args:              [],
    }
    |> Dict.merge(overrides)
  end

  defp params(overrides \\ []) do
    %{
       item_source: [ 333, 444, 555 ]
     } |> Dict.merge(overrides)
  end
  
  test "no options returns opts" do
    given  = params(opts: [])
    assert {:ok, %{ opts: opts }} = analyze(given, default_options)
    assert Dict.delete(opts, :get_next_item) == default_options
  end

  test "can override report_each_result_to" do
    callback = fn _ -> 0 end
    given  = params(opts: [ report_each_result_to: callback ])
    assert {:ok, %{opts: opts}} = analyze(given, default_options)
    assert Dict.delete(opts, :get_next_item) == default_options(report_each_result_to: callback)
  end

  test "can override report_progress_to" do
    callback = fn _ -> 0 end
    given  = params(opts: [ report_progress_to: callback ])
    assert {:ok, %{opts: opts}} = analyze(given, default_options)
    assert Dict.delete(opts, :get_next_item) == default_options(report_progress_to: callback)
  end

  test "can override report_progress_interval" do
    given  = params(opts: [ report_progress_interval: 1234 ])
    assert {:ok, %{opts: opts}} = analyze(given, default_options)
    assert Dict.delete(opts, :get_next_item) == default_options(report_progress_interval: 1234)
  end

  test "worker_args accepts list" do
    given  = params(opts: [ worker_args: [1,2,3] ])
    assert {:ok, %{opts: opts}} = analyze(given, default_options)
    assert Dict.delete(opts, :get_next_item) == default_options(worker_args: [1,2,3])
  end

  test "worker_args accepts single term" do
    given  = params(opts: [ worker_args: 123 ])
    assert {:ok, %{opts: opts}} = analyze(given, default_options)
    assert Dict.delete(opts, :get_next_item) == default_options(worker_args: [123])
  end

  test "absolute worker count can be set" do
    given  = params(opts: [ worker_count: 12 ])
    assert {:ok, %{opts: opts}} = analyze(given, default_options)
    assert Dict.delete(opts, :get_next_item) == default_options(worker_count: 12)
  end

  test "ratio worker count can be given" do
    given  = params(opts: [ worker_count: 2.0 ])
    assert {:ok, %{opts: opts}} = analyze(given, default_options)
    assert Dict.delete(opts, :get_next_item) == default_options(worker_count: 2 * processing_units)
  end

  test "cpu_bound returns full house of workers" do
    given  = params(opts: [ worker_count: :cpu_bound ])
    assert {:ok, %{opts: opts}} = analyze(given, default_options)
    assert Dict.delete(opts, :get_next_item) == default_options(worker_count: processing_units)
  end
  
  test "io_bound returns overcommits workers by a factor of 10" do
    given  = params(opts: [ worker_count: :io_bound ])
    assert {:ok, %{opts: opts}} = analyze(given, default_options)
    assert Dict.delete(opts, :get_next_item) == default_options(worker_count: 10*processing_units)
  end
  
  test "invalid option is rejected" do
    given  = params(opts: [ invalid: 1234 ])
    expect = { :error, "Invalid option [ invalid: 1234 ] to Elixir.WorkQueue.Options"}
    assert expect == analyze(given, default_options)
  end

  test "zero worker count is rejected" do
    given  = params(opts: [ worker_count: 0 ])
    expect = { :error, "Invalid option [ worker_count: 0 ] to Elixir.WorkQueue.Options"}
    assert expect == analyze(given, default_options)
  end

  test "negative worker count is rejected" do
    given  = params(opts: [ worker_count: -1.5 ])
    expect = { :error, "Invalid option [ worker_count: -1.5 ] to Elixir.WorkQueue.Options"}
    assert expect == analyze(given, default_options)
  end

  test "automatically supplied next item function" do
    result = analyze(params, default_options)
    assert {:ok, %{opts: %{ get_next_item: get_next_item }}} = result

    work = params.item_source
    assert [333, 444, 555] == work
    assert {:ok, 333, work=[444, 555]} = get_next_item.(work)
    assert {:ok, 444, work=[555]}      = get_next_item.(work)
    assert {:ok, 555, work=[]}         = get_next_item.(work)
    assert {:done, _, work=[]}         = get_next_item.(work)
    assert {:done, _, _work=[]}        = get_next_item.(work)
  end
end
