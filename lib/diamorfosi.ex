defmodule Diamorfosi do
  use Application

  @timeout 5000

  def start(_type, _args) do
    Diamorfosi.Supervisor.start_link
  end

  defmacrop body_encode(list) do
    quote do
      for {key, value} <- unquote(list), into: "" do
        "#{key}=#{value}&"
      end
    end
  end

  def get(path, options \\ []) do
    case get_with_details(path, options) do
      false -> false
      details ->
        node = details["node"]
        case node["dir"] do
          true -> node["nodes"]
          nil ->
            value = node["value"]
            case Jazz.decode(value) do
              {:ok, json} -> json
              _ -> value
            end
        end
    end
  end

  def get_with_details(path, options \\ []) do
    timeout = Keyword.get options, :timeout, @timeout
    case HTTPoison.get "#{etcd_url}#{path}", [], [timeout: timeout] do
      %HTTPoison.Response{status_code: 200, body: body} -> body |> Jazz.decode!
      _ -> false
    end
  end

  def set_term(path, value) do
    set(path, value |> :erlang.term_to_binary |> :base64.encode |> URI.encode_www_form)
  end
  def get_term(path) do
    case get(path) do
      false -> false
      val -> val |> :base64.decode |> :erlang.binary_to_term
    end
  end

  def set(path, value), do: set(path, value, [])
  def set(path, value, options) when is_binary(value) do
    timeout = Keyword.get options, :timeout, @timeout
    options = Keyword.delete options, :timeout
    case HTTPoison.request :put, "#{etcd_url}#{path}", body_encode([value: value] ++ options), [{"Content-Type", "application/x-www-form-urlencoded"}], [timeout: timeout] do
      %HTTPoison.Response{status_code: code, body: body} when code in [200, 201] -> body |> Jazz.decode!
      %HTTPoison.Response{status_code: 307} -> set path, value, options
      _ -> false
    end
  end
  def set(path, value, options) do
    set(path, Jazz.encode!(value), options)
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


  defmacro serial(dataset_name, code) do
    quote do
      case Diamorfosi.set("/atoms/#{unquote(dataset_name)}", Jazz.encode!([processing: true]), [prevExist: false]) do
        false -> {:error, unquote(dataset_name)}
        _set_result ->
          result = unquote(code)
          Diamorfosi.set("/atoms/#{unquote(dataset_name)}", Jazz.encode!([processing: false]), [prevExist: true, ttl: 1])
          result
      end
    end
  end

  defp etcd_url, do: Application.get_env(:diamorfosi, :etcd_url)
end
