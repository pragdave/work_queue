defmodule WorkQueue.WorkerSupervisor do

  use Supervisor

  def start_link(params) do
    { :ok, pid } = Supervisor.start_link(__MODULE__, [params, self])
    { :ok, Dict.put(params, :supervisor_pid, pid) }
  end

  def init([params, scheduler_pid]) do
    workers = [ worker(WorkQueue.Worker, [params, scheduler_pid], restart: :temporary) ]
    {:ok, _} = supervise(workers, strategy: :simple_one_for_one)
    1..params.opts.worker_count
    |> Enum.each(&(Supervisor.start_child(self, [&1])))
  end  
end
