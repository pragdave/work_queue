defmodule WorkQueue.WorkerSupervisor do
  require Logger

  def start_link(params) do
    { :ok, supervisor_pid } = Task.Supervisor.start_link()
    { :ok, Map.put(params, :supervisor_pid, supervisor_pid) }
  end
end
