defmodule WorkQueueTest do
  use ExUnit.Case

  test "doesn't crash!" do
    WorkQueue.start_link(
      &double/2,        # worker
      [ 1, 2, 3 ],      # work items to process
      &traverse_list/1) # func to get next work item
  end

  defp double(value, _), do: value * 2
  
  defp traverse_list([]),    do: {nil, []}
  defp traverse_list([h|t]), do: {h, t}
  
end
