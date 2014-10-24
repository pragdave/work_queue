defmodule WorkQueue.WorkerSupervisor do

  use     Supervisor
  require Logger
  
  def start_link(params) do
    { :ok, supervisor_pid } = Supervisor.start_link(__MODULE__, [params, self])
    start_children(params, supervisor_pid)
    { :ok, Dict.put(params, :supervisor_pid, supervisor_pid) }
  end

  def init([params, scheduler_pid]) do
    workers = [
      worker(WorkQueue.Worker, [params, scheduler_pid], restart: :temporary)
    ]
    supervise(workers, strategy: :simple_one_for_one)
  end

  defp start_children(params, supervisor_pid) do
    1..params.opts.worker_count
    |> Enum.each(&(Supervisor.start_child(supervisor_pid, [&1])))
  end  
end
