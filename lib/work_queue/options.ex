defmodule WorkQueue.Options do

  def analyze(params, defaults \\ default_options) do
    Enum.reduce(params.opts, {:ok, defaults}, &option/2)
    |> case do
         error = {:error,_} -> error
         {:ok, new_options} -> {:ok, %{ params | opts: new_options} }
       end
  end

  defp default_options do
    %{
        worker_count:             round(processing_units*0.667),
        report_each_result_to:    fn _ -> end,
        report_progress_to:       fn _ -> end,
        report_progress_interval: false,
        worker_args:              [],
     }
  end

  # Once we have an error, ignore further options
  defp option(_, result = {:error, _}), do: result
  
  defp option({:report_progress_interval, n}, result)
  when is_integer(n),
  do:  update(result, :report_progress_interval, n)
  
  defp option({:report_progress_to, func}, result)
  when is_function(func),
  do:  update(result, :report_progress_to, func)

  defp option({:report_each_result_to, func}, result)
  when is_function(func),
  do:  update(result, :report_each_result_to, func)

  defp option({:worker_args, args}, result)
  when is_list(args),
  do:  update(result, :worker_args, args)
  
  defp option({:worker_args, arg}, result),
  do:  option({:worker_args, [arg]}, result)
  
  defp option({:worker_count, n}, result)
  when is_integer(n) and n > 0,
  do:  update(result, :worker_count, n)

  defp option({:worker_count, ratio}, result)
  when is_float(ratio) and ratio >= 0.5,
  do:  option({:worker_count, round(ratio*processing_units)}, result)

  defp option({:worker_count, :cpu_bound}, result),
  do:  option({:worker_count, processing_units}, result)

  defp option({:worker_count, :io_bound}, result),
  do:  option({:worker_count, 10.0}, result)
  
  defp option({option, value}, _result) do
    { :error, "Invalid option [ #{option}: #{inspect value} ] to #{__MODULE__}" }
  end

  defp update({:ok, result}, key, val) do
    { :ok, Dict.put(result, key, val) }
  end
  
  def processing_units, do: :erlang.system_info(:logical_processors)

end
