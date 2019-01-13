defmodule WorkQueue do

  use Exlibris.PipeWhileOk
  use Exlibris.BeforeReturning

  require Logger

  alias WorkQueue.Options

  @doc File.read!("README.md")

  def process(worker_fn, item_source, extra_opts \\ []) do
    pipe_while_ok do
      package_parameters(worker_fn, item_source, extra_opts)
      |> Options.analyze
      |> start_workers
      |> schedule_work
    end
  end

  defp package_parameters(worker_fn, item_source, extra_opts) do
    { :ok,
      %{
          worker_fn:        worker_fn,
          item_source:      item_source,
          opts:             extra_opts,
          results:          []
       }
    }
  end

  defp start_workers(params) do
    WorkQueue.WorkerSupervisor.start_link(params)
  end

  defp schedule_work(params) do
    params.opts.report_progress_to.({:started, nil})

    results = if params.opts.report_progress_interval do
                loop_with_ticker(params, [], params.opts.worker_count)
              else
                loop(params, [], params.opts.worker_count)
              end

    before_returning results do
      results -> params.opts.report_progress_to.({:finished, results})
    end
  end

  defp loop_with_ticker(params, running, max) do
    {:ok, ticker} = :timer.send_interval(params.opts.report_progress_interval,
                                         self(), :tick)
    before_returning loop(params, running, max) do
      _ -> :timer.cancel(ticker)
    end
  end

  defp loop(params, running, max) when length(running) < max do
    case get_next_item(params) do
      {:done, params, _} when running == [] ->
        Process.unlink(params.supervisor_pid)
        Process.exit(params.supervisor_pid, :shutdown)
        params.results

      {:done, params, _} ->
        wait_for_answers(params, running, max)

      {:ok, params, item} ->
        {:ok, worker} = WorkQueue.Worker.process(params, self(), item)
        loop(params, [worker|running], max)
    end
  end

  defp loop(params, running, max) do
    wait_for_answers(params, running, max)
  end

  defp wait_for_answers(params, running, max) do
    receive do
      :tick ->
        params.opts.report_progress_to.({:progress, length(params.results)})
        wait_for_answers(params, running, max)

      { :processed, worker, { :ok, result } } ->
        if worker in running do
          params = update_in(params.results, &[result|&1])
          loop(params, List.delete(running, worker), max)
        else
          loop(params, running, max)
        end
    end
  end

  defp get_next_item(params) do
    {status, item, new_state}  = params.opts.get_next_item.(params.item_source)
    {status, Map.put(params, :item_source, new_state), item}
  end
end
