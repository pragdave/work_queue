defmodule WorkQueueTest do
  use ExUnit.Case
  require Logger
  
  @tag timeout: 5000
  
  test "basic queue" do
    results = [ 1, 2, 3 ] |> WorkQueue.process( &double/2 )
    assert length(results) == 3
    for {input, output} <- results, do: assert(output == input * 2)
  end

  test "basic queue with anon function" do
    results = [ 1, 2, 3 ] |> WorkQueue.process(
      fn (val, _) -> {:ok, val*2} end
    )
    assert length(results) == 3
    for {input, output} <- results, do: assert(output == input * 2)
  end
  
  # one worker waits for 100mS. Meanwhile the other two workers
  # process the rest. The elapsed time shouldn't be much more
  # than 100mS
  test "scheduling is hungry" do
    {time, results} = :timer.tc fn ->
       [ 100, 10, 10, 10, 50, 10, 10 ] |> WorkQueue.process( &sleep/2 )
    end
    assert length(results) == 7
    assert time < 120_000
  end

  test "notifications of results" do
    [ 1, 2, 3 ] 
      |> WorkQueue.process( 
        &double/2 ,        # worker
        report_each_result_to:
          fn {input, output} -> assert(output == input*2) end
      )
  end

  test "periodic notifications" do
    {:ok, memory} = Agent.start_link(fn -> [] end)
    [ 10, 10, 100, 100, 100 ] 
      |> WorkQueue.process(
        &sleep/2,
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

  test "scale up worker pool" do
    {:ok, memory} = Agent.start_link(fn -> [] end)
    [ 12, 12, 12 ]
      |> WorkQueue.process(
        &sleep/2,
        update_worker_count:
          fn _, _, max ->
            Agent.update(memory, fn mem -> [max|mem] end)
            {:ok, 10}
          end,
        worker_count: 1,
        update_worker_count_interval: 10
      )
    
    updates = Agent.get(memory, &(&1))
    # If a second process didn't spawn, then the result would be 3.
    assert 2 = Enum.count(updates)
  end
  
  test "scale down worker pool" do
    {:ok, memory} = Agent.start_link(fn -> [] end)
    [ 12, 12, 12, 12 ]
      |> WorkQueue.process(
        &sleep/2,
        update_worker_count:
          fn _, _, max ->
            Agent.update(memory, fn mem -> [max|mem] end)
            {:ok, 1}
          end,
        worker_count: 2,
        update_worker_count_interval: 10
      )
    
    updates = Agent.get(memory, &(&1))
    # If we didn't scale down, this could complete in 2 updates.
    assert 3 = Enum.count(updates)
  end
  
  defp double(value, _) do 
    { :ok, value * 2 }
  end

  defp sleep(interval, _) do
    { :ok, :timer.sleep(interval) }
  end

end
