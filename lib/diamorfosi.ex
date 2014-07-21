defmodule Diamorfosi do
  alias Diamorfosi.API

  @doc """
  Get the value at `path`.

  If the value is not available or failed to parse `default` will be returned.

  If `path` points to a directory, it will return its contents (if `list: true`
  option is passed) or raise.

  Reference: https://coreos.com/docs/distributed-configuration/etcd-api/#toc_5
  """
  # options: [timeout: ..., type: ...]
  def get(path, default, options \\ []) do
    case fetch(path, options) do
      {:ok, value} -> value
      {:error, :is_dir} -> raise Diamorfosi.KeyError, message: "Tried to fetch a directory"
      {:error, _reason} -> default
    end
  end

  @doc """
  Synonym for `get(path, default, [type: :term])`.
  """
  def get_term(path, default, options \\ []) do
    get(path, default, [type: :term] ++ options)
  end

  @doc """
  Get the value at `path` and return `{:ok, <value>}` or `{:error, <reason>}`.

  If type is specified, it will try to parse the value and will return
  `{:error, :bad_type}` in case of failure. By default, the argument is
  interpreted as a string.

  If `path` points to a directory, `{:error, :is_dir}` will be returned unless
  `list: true` option is passed.
  """
  # options: [type: :int, timeout: ...]
  # options: [type: fn(x) -> ... end]
  def fetch(path, options \\ []) do
    case API.get(path, options) do
      {:error, _, reason} -> {:error, reason}
      {:ok, value} -> process_api_value(value, options)
    end
  end

  @doc """
  Get the value at `path` and raise in case of failure.

  See `fetch/2` for details.
  """
  def fetch!(path, options \\ []) do
    case fetch(path, options) do
      {:ok, value} -> value
      {:error, reason} -> raise Diamorfosi.KeyError, message: inspect(reason)
    end
  end

  @doc """
  Set the value for key at `path`.

  ## Options

  Reference: https://coreos.com/docs/distributed-configuration/etcd-api/#toc_3
  """
  # options: [type: :num]
  # options: [condition: %{...}, update: true]  # compareAndSwap
  # options: [in_order: true]
  def set(path, value, options \\ []) do
    api_val = encode_value(value, Keyword.get(options, :type, :str))
    case API.put(path, api_val, options) do
      :ok -> :ok
      {:error, _, reason} -> {:error, reason}
    end
  end

  @doc """
  Synonym for `set(path, value, [type: :term])`.
  """
  def set_term(path, value, options \\ []) do
    set(path, value, [type: :term] ++ options)
  end

  @doc """
  Creates a new key in directory at `path` in order.

  Returns `{:ok, <key>}` with the new key in case of success or `{:error,
  <reason>}` in case of failure.

  Reference: https://coreos.com/docs/distributed-configuration/etcd-api/#toc_10
  """
  def put(path, value, options \\ []) do
    api_val = encode_value(value, Keyword.get(options, :type, :str))
    case API.post(path, api_val, options) do
      {:ok, %{"node" => %{"key" => key}}} -> {:ok, trunc_key(key)}
      {:error, _, reason} -> {:error, reason}
    end
  end

  @doc """
  Same as `put/3` except it returns just `<key>` or raises.
  """
  def put!(path, value, options \\ []) do
    case put(path, value, options) do
      {:ok, key} -> key
      {:error, reason} -> raise Diamorfosi.KeyError, message: inspect(reason)
    end
  end

  @doc """
  Delete the value at `path`.

  Returns `:ok` in case of success.

  If `path` was not found, returns `{:error, :not_found}`.

  If `path` points to a directory, removes it if `recursive: true` options is
  passed, otherwise returns `{:error, :is_dir}`.

  Reference: https://coreos.com/docs/distributed-configuration/etcd-api/#toc_7,
             https://coreos.com/docs/distributed-configuration/etcd-api/#toc_16
  """
  # options: [condition: %{...}]  # compareAndDelete
  # options: [recursive: true]
  def delete(path, options \\ []) do
    case API.delete(path, options) do
      {:ok, _value} -> :ok
      {:error, _, %{"message" => message}} -> {:error, message}
    end
  end

  @doc """
  Create a new directory at `path`.

  Reference: https://coreos.com/docs/distributed-configuration/etcd-api/#toc_14
  """
  def mkdir(path, options \\ []) do
    case API.put(path, nil, [dir: true] ++ options) do
      :ok -> :ok
      {:error, 403, _} -> {:error, "Key already exists"}
      {:error, _, %{"message" => message}} -> {:error, message}
    end
  end

  @doc """
  List directory contents at `path`.

  recursive: true

  Reference: https://coreos.com/docs/distributed-configuration/etcd-api/#toc_15
  """
  def lsdir(path, options \\ []) do
    case API.get(path, options) do
      {:ok, %{"node" => %{"dir" => true}=node}} ->
        {:ok, process_dir_listing(node["nodes"], options)}
      {:ok, _} -> {:error, "Not a directory"}
      {:error, _, %{"message" => message}} -> {:error, message}
    end
  end

  @doc """
  Wait for the value at `path` to change.

  Reference: https://coreos.com/docs/distributed-configuration/etcd-api/#toc_9
  """
  def wait(path, options \\ []) do
    case API.get(path, [wait: true] ++ options) do
      {:ok, value} -> process_api_value(value, options)
      {:error, ...} -> ...
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

  ###

  defp process_api_value(value, options) do
    node = value["node"]
    case {node["dir"], Keyword.get(options, :list, false)} do
      {true, true} -> {:ok, process_dir_listing(node["nodes"], options)}
      {true, false} -> {:error, :is_dir}
      {nil, _} -> decode_api_node(node, options)
    end
  end

  defp decode_api_node(node, options) do
    value = node["value"]
    try do
      {:ok, decode_value(value, Keyword.get(options, :type, :str))}
    rescue
      # FIXME: this may hide programming bugs
      _ -> {:error, :bad_type}
    end
  end

  defp process_dir_listing(nodes, options) do
    list = Enum.reduce(nodes, [], fn
      %{"key" => key, "dir" => true}=node, acc ->
        value = if options[:recursive] do
          process_dir_listing(node["nodes"], options)
        else
          # FIXME: these defaults might not be the best choice
          if options[:sort], do: [], else: %{}
        end
        [{trunc_key(key), value}|acc]

      %{"key" => key, "value" => value}, acc ->
        [{trunc_key(key), value}|acc]
    end)
    if options[:sort], do: Enum.reverse(list), else: Enum.into(list, %{})
  end

  defp trunc_key(key) do
    [_, last] = Regex.run(~r"/([^/]+)$", key)
    last
  end

  # These 2 functions implement a trick to make it possible to define
  # encoding and decoding functions for a single type side by side
  defp encode_value(val, typ), do: code_value(:en, val, typ)
  defp decode_value(val, typ), do: code_value(:de, val, typ)

  defp code_value(:en, val, :str) do
    val |> URI.encode_www_form
  end
  defp code_value(:de, val, :str) do
    val |> URI.decode_www_form
  end

  defp code_value(:en, val, :term) do
    val |> :erlang.term_to_binary |> Base.url_encode64
  end
  defp code_value(:de, val, :term) do
    val |> Base.url_decode64! |> :erlang.binary_to_term
  end

  defp code_value(:en, val, :json) do
    val |> Jazz.encode!
  end
  defp code_value(:de, val, :json) do
    val |> Jazz.decode!
  end
end
