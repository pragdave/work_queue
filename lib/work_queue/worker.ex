defmodule WorkQueue.Worker do

  use     GenServer
  require Logger

  #######
  # API #
  #######
   
  def process(params, scheduler_pid, item) do
    Task.Supervisor.start_child(params.supervisor_pid, __MODULE__, :do_process,
                                [params, scheduler_pid, item])
  end

  ##################
  # Implementation #
  ##################

  def do_process(params, scheduler_pid, item) do
    {:ok, result} = params.worker_fn.(item, params.opts.worker_args)
    send(scheduler_pid, {:processed, self, {:ok, {item, result}}})
  end

end
