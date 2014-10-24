defmodule WorkQueue.Worker do

  use     GenServer
  require Logger

  #######
  # API #
  #######

 
  def start_link(params, scheduler_pid, my_index) do
    GenServer.start_link(__MODULE__, %{params: params, scheduler_pid: scheduler_pid})
  end
   
  def process(me, work_item) do
    GenServer.cast(me, {:process, work_item})
  end

  ##################
  # Implementation #
  ##################

  def init(state) do
    send(state.scheduler_pid, {:send_work, self})
    { :ok, state }
  end

  def handle_cast({:process, nil}, state) do
    send(state.scheduler_pid, { :shutdown, self })
    { :noreply, state }
  end

  def handle_cast({:process, work_item}, state = %{ params: params }) do
    {:ok, result} = params.worker_fn.(work_item, params.opts.worker_args)
    send(state.scheduler_pid, { :processed, self, {:ok, {work_item, result}}})
    { :noreply, state }
  end

end
