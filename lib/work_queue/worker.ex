defmodule WorkQueue.Worker do

  use GenServer

  #######
  # API #
  #######
  
  def process(me, work_item) do
    GenServer.cast(me, {:process, work_item})
  end

  ##################
  # Implementation #
  ##################
  
  def init(state = [params, scheduler_pid]) do
    send(scheduler_pid, {:send_work, self})
    { :ok, state }
  end

  def handle_cast({:process, nil}, state) do
    send(state.scheduler_pid, { :shutdown, self })
    { :stop, :normal, state }
  end

  def handle_cast({:process, work_item}, state = %{ params: params }) do
    result = params.worker_fn(work_item, params.opts.worker_args)
    send(params.scheduler_pid, { :processed, self, result})
    { :noreply, state }
  end
  
end
