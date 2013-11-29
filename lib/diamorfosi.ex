defmodule Diamorfosi do
  use Application.Behaviour

  @etcd "http://my.host.name:4001/v1/keys"

  # See http://elixir-lang.org/docs/stable/Application.Behaviour.html
  # for more information on OTP Applications
  def start(_type, _args) do
    Diamorfosi.Supervisor.start_link
  end

  defp body_encode(list) do
  	Keyword.keys(list) 
  		|> Enum.map(fn key ->
  			"#{key}=#{list[key]}"
  		end)
  		|> Enum.join("&")
  end

  def get(path) do
  	case HTTPotion.get "#{@etcd}#{path}" do
  		HTTPotion.Response[status_code: 200, body: body] -> body |> JSEX.decode!
  		_ -> false
  	end
  end
  def set(path, value, options // []) do
  	IO.puts "body: #{body_encode([value: value] ++ options)}"
  	case HTTPotion.request :put, "#{@etcd}#{path}", body_encode([value: value] ++ options), [{:'Content-Type', "application/x-www-form-urlencoded"}], [timeout: 1000] do
  		HTTPotion.Response[status_code: 200, body: body] -> body |> JSEX.decode!
  		_ -> false
  	end
  end
end
