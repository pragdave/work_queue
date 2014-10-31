defmodule WorkQueueTest do
  use ExUnit.Case
  require Logger
  
  @tag timeout: 5000
  
  test "basic queue" do
    results = WorkQueue.process(
      &double/2,        # worker
      [ 1, 2, 3 ]       # work items to process
    )
    assert length(results) == 3
    for {input, output} <- results, do: assert(output == input * 2)
  end

  test "basic queue with anon function" do
    results = WorkQueue.process(
      fn (val, _) -> {:ok, val*2} end,
      [ 1, 2, 3 ]
    )
    assert length(results) == 3
    for {input, output} <- results, do: assert(output == input * 2)
  end
  
  # one worker waits for 100mS. Meanwhile the other two workers
  # process the rest. The elapsed time shouldn't be much more
  # than 100mS
  test "scheduling is hungry" do
    {time, results} = :timer.tc fn ->
       WorkQueue.process(
        &sleep/2, 
        [ 100, 10, 10, 10, 50, 10, 10 ]
      )
    end
    assert length(results) == 7
    assert time < 120_000
  end

  test "notifications of results" do
    WorkQueue.process(
      &double/2,        # worker
      [ 1, 2, 3 ],      # work items to process
      report_each_result_to:
        fn {input, output} -> assert(output == input*2) end
    )
  end

  test "periodic notifications" do
    {:ok, memory} = Agent.start_link(fn -> [] end)
    WorkQueue.process(
      &sleep/2,       
      [ 10, 10, 100, 100, 100 ],
      report_progress_interval: 20,
      report_progress_to:
        fn report ->
          Agent.update(memory, fn mem ->  [report|mem] end)
        end
    )
    [last | reports] = Agent.get(memory, &(&1))
    assert { :finished, _results } = last
    [ first | ticks ] = Enum.reverse reports
    assert { :started, nil } = first
    assert { :progress, _n } = hd(ticks)
  end

  
  defp double(value, _) do 
    { :ok, value * 2 }
  end

  defp sleep(interval, _) do
    { :ok, :timer.sleep(interval) }
  end

end
