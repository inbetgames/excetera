defmodule Diamorfosi do
  use Application.Behaviour

  @etcd "http://my.host.name:8080/v2/keys"
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

  def get(path, options \\ []) do
    case get_with_details(path, options) do
      false -> false
      details -> 
        case details["node"]["dir"] do
          true -> details["node"]["nodes"]
          nil -> 
            value = details["node"]["value"]
            case JSON.decode(value) do
              {:ok, json} -> json
              _ -> value
            end
        end
    end
  end
  
  def get_with_details(path, options \\ []) do
  	timeout = Keyword.get options, :timeout, @timeout
  	case HTTPoison.get "#{@etcd}#{path}", [], [timeout: timeout] do
  		HTTPoison.Response[status_code: 200, body: body] -> body |> JSON.decode!
  		_ -> false
  	end
  end
  
  def set(path, value), do: set(path, value, [])
  def set(path, value, options) when is_binary(value) do
  	timeout = Keyword.get options, :timeout, @timeout
  	options = Keyword.delete options, :timeout
  	case HTTPoison.request :put, "#{@etcd}#{path}", body_encode([value: value] ++ options), [{"Content-Type", "application/x-www-form-urlencoded"}], [timeout: timeout] do
  		HTTPoison.Response[status_code: code, body: body] when code in [200, 201] -> body |> JSON.decode!
  		HTTPoison.Response[status_code: 307] -> set path, value, options
      _ -> false
  	end
  end
  def set(path, value, options) do
    set(path, JSON.encode!(value), options)
  end

  def wait(path, options \\ []) do 
  	case options[:waitIndex] do
  		nil -> 
		  	get("#{path}", options)
		  	|> (fn reply ->
		  		wait path, Keyword.update(options, :waitIndex, (reply["modifiedIndex"] + 1), &(&1))
		  	end).()
		 value when is_integer(value) ->
		 	options = Keyword.delete options, :waitIndex
		 	get("#{path}?wait=true&waitIndex=#{value}", options)
	end
  end


  def atomic(dataset_name, func) do
    case Diamorfosi.set("/atoms/#{dataset_name}", JSON.encode!([processing: true]), [prevExist: false]) do
      false -> {:error, dataset_name}
      _set_result ->
        result = func.()
        Diamorfosi.set("/atoms/#{dataset_name}", JSON.encode!([processing: false]), [prevExist: true, ttl: 1])
        result
    end
  end

end
