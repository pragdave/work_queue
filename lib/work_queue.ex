defmodule WorkQueue do

  use PipeWhileOk
  
  alias WorkQueue.Options
  
  def start_link(worker_fn, work_to_process, get_next_item_fn, extra_opts \\ []) do
    pipe_while_ok do
      package_parameters(worker_fn, work_to_process, get_next_item_fn, extra_opts)
      |> Options.analyze
      |> start_workers
      |> schedule_work
    end
  end

  defp package_parameters(worker_fn, work_to_process, get_next_item_fn, extra_opts) do
    { :ok,
      %{
          worker_fn:        worker_fn,
          work_to_process:  work_to_process,
          get_next_item_fn: get_next_item_fn,
          opts:             extra_opts,
          result_count:     0,
          running_workers:  0,
       }
    }
  end
    
  defp start_workers(params) do
    WorkerQueue.WorkerSupervisor.start_link(params)
  end

  defp schedule_work(params) do
    params.report_progress_to.({:starting})
    params = Dict.put(params, :running_workers, params.opts.worker_count)

    count = if params.report_progress_interval do
              loop_with_ticker(params)
            else
              loop(params)
            end

    params.report_progress_to.({:finished, count})
  end

  defp loop_with_ticker(params) do
    {:ok, ticker} = :timer.send_interval(params.report_progress_interval, self, :tick)
    count = loop(params)
    :timer.cancel(ticker)
    count
  end

  defp loop(params) do
    require Logger
    
    receive do
      { :send_work, worker } ->
        {params, next_item} = get_next_item(params)
        WorkQueue.Worker.process(worker, next_item)
        loop(params)

      { :processed, worker, { :ok, result } } ->
        params = update_in(params[:result_count], &(&1+1))
        params.report_each_result_to.(result)
        {params, next_item} = get_next_item(params)
        WorkQueue.Worker.process(worker, next_item)
        loop(params)

      { :shutdown, _worker } ->
        if params.running_workers > 1 do
          loop(%{params | running_workers: params.running_workers - 1})
        else
          params.result_count
        end

      :tick ->
        params.report_progress_to.({:progress, params.result_count})
        loop(params)

      other ->
        Logger.error("Unknown message in work queue scheduler: #{inspect other}")
    end
  end


  defp get_next_item(params) do
    {item, new_state}  = params.get_next_item_fn(params.work_to_process)
    {Dict.put(params, :work_to_process, new_state), item}
  end
  
end
