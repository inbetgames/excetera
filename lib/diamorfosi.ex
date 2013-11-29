defmodule Diamorfosi do
  use Application.Behaviour

  @etcd "http://my.host.name:4001/v2/keys"
  @timeout 5000
  # See http://elixir-lang.org/docs/stable/Application.Behaviour.html
  # for more information on OTP Applications
  def start(_type, _args) do
    Diamorfosi.Supervisor.start_link
  end

  defp body_encode(list) do
  	Keyword.keys(list) 
  		|> Stream.map(fn key ->
  			"#{key}=#{list[key]}"
  		end)
  		|> Enum.join("&")
  end

  def get(path, options // []) do
  	timeout = Keyword.get options, :timeout, @timeout
  	options = Keyword.delete options, :timeout
  	IO.puts "calling #{@etcd}#{path} with timeout #{timeout}"
  	case HTTPotion.get "#{@etcd}#{path}", [], [timeout: timeout] do
  		HTTPotion.Response[status_code: 200, body: body] -> body |> JSEX.decode!
  		_ -> false
  	end
  end
  def set(path, value, options // []) do
  	timeout = Keyword.get options, :timeout, @timeout
  	options = Keyword.delete options, :timeout
  	case HTTPotion.request :put, "#{@etcd}#{path}", body_encode([value: value] ++ options), [{:'Content-Type', "application/x-www-form-urlencoded"}], [timeout: timeout] do
  		HTTPotion.Response[status_code: 200, body: body] -> body |> JSEX.decode!
  		_ -> false
  	end
  end
  def wait(path, options // []) do 
  	case options[:waitIndex] do
  		nil -> 
		  	get("#{path}", options)
		  	|> (fn reply ->
		  		wait path, Keyword.update(options, :waitIndex, (reply["modifiedIndex"] + 1), &(&1))
		  	end).()
		 value when is_integer(value) ->
		 	get("#{path}?wait=true&waitIndex=#{value}", options)
	end
  end
  #def wait(path, index, options // []) do
  #	get("#{path}?wait=true&waitIndex=#{index}")
  #end
end
