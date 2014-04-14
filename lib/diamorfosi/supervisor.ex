defmodule Diamorfosi.Supervisor do
  use Supervisor.Behaviour

  def start_link do
    :supervisor.start_link({:local, __MODULE__}, __MODULE__, [])
  end

  def init([]) do
    children = [
      # Define workers and child supervisors to be supervised
      # worker(Diamorfosi.Worker, [])
    ]
    supervise(children, strategy: :one_for_one, max_restarts: 500)
  end
end
