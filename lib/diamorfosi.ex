defmodule Diamorfosi do
  use Application

  @doc false
  def start(_type, _args) do
    Diamorfosi.Supervisor.start_link
  end

  alias Diamorfosi.API

  @doc """
  """
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
    case API.get(path, options) do
      {:ok, value} -> value
      :error -> false
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
    case API.put(path, value, options) do
      :ok -> :ok
      :error -> false
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
end
