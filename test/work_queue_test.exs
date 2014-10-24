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

  test "notifications of results" do
    results = WorkQueue.start_link(
                &double/2,        # worker
                [ 1, 2, 3 ],      # work items to process
                &traverse_list/1,
                report_each_result_to: fn {input, output} -> assert(output == input*2) end
    )
    
  end

  
  defp double(value, _) do 
    { :ok, value * 2 }
  end
  
  defp traverse_list([]),    do: {nil, []}
  defp traverse_list([h|t]), do: {h, t}

end
