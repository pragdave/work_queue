defmodule WorkQueueTest do
  use ExUnit.Case
  require Logger
  
  @tag timeout: 5000
  
  test "basic queue" do
    results = WorkQueue.start_link(
      &double/2,        # worker
      [ 1, 2, 3 ],      # work items to process
      &traverse_list/1
    )
    assert length(results) == 3
    for {input, output} <- results, do: assert(output == input * 2)
  end

  # one worker waits for 100mS. Meanwhile the other two workers
  # process the rest. The elapsed time shouldn't be much more
  # than 100mS
  test "scheduling is hungry" do
    {time, results} = :timer.tc fn ->
       WorkQueue.start_link(
        &sleep/2, 
        [ 100, 10, 10, 10, 50, 10, 10 ],
        &traverse_list/1
      )
    end
    assert length(results) == 7
    assert time < 120_000 
  end

  test "notifications of results" do
    WorkQueue.start_link(
      &double/2,        # worker
      [ 1, 2, 3 ],      # work items to process
      &traverse_list/1,
      report_each_result_to:
      fn {input, output} -> assert(output == input*2) end
    )
  end

  
  defp double(value, _) do 
    { :ok, value * 2 }
  end

  defp sleep(interval, _) do
    { :ok, :timer.sleep(interval) }
  end
  
  defp traverse_list([]),    do: {nil, []}
  defp traverse_list([h|t]), do: {h, t}

end
