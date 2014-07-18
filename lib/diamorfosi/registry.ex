defmodule Diamorfosi.Registry do
	def atom_open(atomname, _default_value \\ nil) do
		worker_name = "Diamorfosi.#{atomname}" |> :erlang.binary_to_atom(:utf8)
		:supervisor.start_child(
			Diamorfosi.Supervisor,
			Supervisor.Behaviour.worker(Diamorfosi.Registry.Worker, [atomname], [worker_name])
		)
	end

	def atom_close(_atomname, _delete \\ true) do

	end

	def atom_get(atomname) do
		:ets.lookup(:diamorfosi_registry, atomname)
	end

	def atom_set(atomname, value) do
		Diamorfosi.set "/refs/#{atomname}", Diamorfosi.Serialize.serialize(value)
	end
end

defmodule Diamorfosi.Registry.Worker do
	use ExActor.GenServer
	require Lager

	def init(atomname) do
		{:ok, %{atom: atomname}, 0}
	end

	definfo :timeout, state: state = %{atom: atomname} do
		Lager.info "Fetching new value for atom #{inspect atomname}"
		{:noreply, state, 1000}
	end
end
