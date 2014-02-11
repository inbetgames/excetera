defmodule Diamorfosi.Cluster do
	use GenServer.Behaviour

	@startup_timeout	1000
	@renew_timeout		5000

	def start_link(name), do: :gen_server.start_link(__MODULE__, name, [])
	def init(name), do: {:ok, name, @startup_timeout}
	def handle_info(:timeout, name) do
		Diamorfosi.set "/#{name}/#{:erlang.node}", "#{:erlang.node}", [ttl: round((@renew_timeout+@startup_timeout*2)/1000)]
		case Diamorfosi.get "/#{name}/" do
			false -> :failed_to_list
			catalogue ->
				catalogue["node"]["nodes"]
					|> Stream.map(fn object -> object["value"] end)
					|> Enum.map(fn node ->
						:net_adm.ping :erlang.binary_to_atom(node, :utf8)
					end)
				:ok
		end
		{:noreply, name, @renew_timeout}
	end
end