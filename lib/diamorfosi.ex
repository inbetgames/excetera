defmodule Diamorfosi do
  alias Diamorfosi.API

  @moduledoc """
  Simpler interface on top of Diamorfosi.API.

  In all the functions here that take `path`, it should be a string beginning
  with a slash (`/`).

  See `Diamorfosi.API` docs for the list of common available options.
  """

  @doc """
  Get the value at `path`.

  If the value is not available, or a timeout was triggered, or it failed to
  parse, `default` will be returned.

  If `path` points to a directory, it will return its contents if `dir: true`
  option is passed; will raise `Diamorfosi.KeyError` otherwise.

  See `fetch/2` for details.

  Reference: https://coreos.com/docs/distributed-configuration/etcd-api/#toc_5
  """
  def get(path, default, options \\ []) do
    case fetch(path, options) do
      {:ok, value} -> value
      {:error, "Not a file"=reason} -> raise Diamorfosi.KeyError, message: "get #{path}: #{reason}"
      {:error, _reason} -> default
    end
  end

  @doc """
  Synonym for `get(path, default, [type: :term] ++ options)`.
  """
  def get_term(path, default, options \\ []) do
    get(path, default, [type: :term] ++ options)
  end

  @doc """
  Get the value at `path` and return `{:ok, <value>}` or `{:error, <reason>}`.

  If `type: <type>` option is passed, it will try to parse the value and will
  raise `Diamorfosi.ValueError` in case of failure. By default, the argument is
  interpreted as a string and returned as is.

  If `path` points to a directory, `{:error, "Not a file"}` will be returned
  unless `dir: true` option is passed.

  ## Options

    * `type: <type>` - specifies how to parse the obtained value
    * `dir: <bool>` - if `true`, return the contents of the directory as a map
    * `timeout: <int>` - request timeout in milliseconds

  ## Types

    * `:str` (default) - do not transform the value in any way
    * `:json` - the value is decoded as JSON
    * `:term` - the value is decoded with `:erlang.binary_to_term`
    * `<function>` - the value is passed through the provided function of one
      argument

  ## etcd options

    * `wait: <bool>` - if `true`, waits for the value at `path` to change; the
      timeout is reset to `:infinity` unless overriden explicitly

    * `waitIndex: <int>` - specify the point in etcd's timeline to start
      waiting from

  """
  def fetch(path, options \\ []) do
    {api_options, options} = split_options(options, [:type, :dir, :timeout])
    case API.get(path, api_options, options) do
      {:ok, value} -> process_api_value(value, options)
      {:error, _, %{"message" => message}} -> {:error, message}
    end
  end

  @doc """
  Get the value at `path` and raise in case of failure.

  See `fetch/2` for details.
  """
  def fetch!(path, options \\ []) do
    case fetch(path, options) do
      {:ok, value} -> value
      {:error, message} -> raise Diamorfosi.KeyError, message: "fetch #{path}: #{message}"
    end
  end

  @doc """
  Set the value at `path`.

  If `type: <type>` option is passed, it will try to encode the value and will
  raise `Diamorfosi.ValueError` in case of failure. By default, the argument
  is passed through `to_string()`.

  If `path` points to a directory, `{:error, "Not a file"}` will be returned.

  ## Options

    * `type: <type>` - specifies how to encode the value before sending
    * `condition: [...]` - a list of predicates, effectively performs atomic
      compare-and-swap in etcd terms
    * `timeout: <int>` - request timeout in milliseconds

  ## Types

    * `:str` (default) - pass the value through `to_string()`
    * `:json` - the value is encoded as JSON
    * `:term` - the value is encoded with `:erlang.binary_to_term`
    * `<function>` - the value is passed through the provided function of one
      argument that should return a string

  ## etcd options

    * `ttl: <int>` - set the time-to-live for the value in seconds

  Reference: https://coreos.com/docs/distributed-configuration/etcd-api/#toc_3,
             https://coreos.com/docs/distributed-configuration/etcd-api/#toc_12
  """
  def set(path, value, options \\ []) do
    {api_options, options} = split_options(options, [:type, :condition, :timeout])
    {type, options} = Keyword.pop(options, :type, :str)
    api_val = encode_value(value, type)
    case API.put(path, api_val, api_options, [decode_body: :error] ++ options) do
      {:ok, nil} -> :ok
      {:error, _, %{"message" => message}} -> {:error, message}
    end
  end

  @doc """
  Set the value at `path` and raise in case of failure.

  See `set/3` for details.
  """
  def set!(path, value, options \\ []) do
    case set(path, value, options) do
      :ok -> :ok
      {:error, message} ->
        raise Diamorfosi.KeyError, message: "set #{path}: #{message}"
    end
  end

  @doc """
  Synonym for `set(path, value, [type: :term] ++ options)`.
  """
  def set_term(path, value, options \\ []) do
    set(path, value, [type: :term] ++ options)
  end

  @doc """
  Delete the value at `path`.

  Returns `:ok` in case of success.

  If `path` was not found, returns `{:error, "Key not found"}`.

  If `path` points to a directory, removes it if `recursive: true` option is
  passed, otherwise returns `{:error, "Not a file"}`.

  ## Options

    * `condition: [...]` - a list of predicates, effectively performs atomic
      compare-and-delete in etcd terms
    * `timeout: <int>` - request timeout in milliseconds

  ## etcd options

    * `recursive: <bool>` - if `true`, and `path` points to a directory, delete
      the directory with its children

  Reference: https://coreos.com/docs/distributed-configuration/etcd-api/#toc_7,
             https://coreos.com/docs/distributed-configuration/etcd-api/#toc_16
  """
  def delete(path, options \\ []) do
    {api_options, options} = split_options(options, [:condition, :timeout])
    case API.delete(path, api_options, [decode_body: :error] ++ options) do
      {:ok, nil} -> :ok
      {:error, _, %{"message" => message}} -> {:error, message}
    end
  end

  @doc """
  Delete the value at `path`.

  Returns `:ok` in case of success, raises `Diamorfosi.KeyError` otherwise.

  See `delete/2` for details.
  """
  def delete!(path, options \\ []) do
    case delete(path, options) do
      :ok -> :ok
      {:error, message} ->
        raise Diamorfosi.KeyError, message: "delete #{path}: #{message}"
    end
  end

  @doc """
  Create a new directory at `path`.

  Accepts the same set of options as `set/3` except for the `:type` one.

  Returns `:ok` or `{:error, <reason>}`.

  Reference: https://coreos.com/docs/distributed-configuration/etcd-api/#toc_14
  """
  def mkdir(path, options \\ []) do
    {api_options, options} = split_options(options, [:condition, :timeout])
    case API.put(path, nil, [dir: true] ++ api_options, [decode_body: :error] ++ options) do
      {:ok, nil} -> :ok
      {:error, 403, %{"message" => "Not a file"}} ->
        {:error, "Key already exists"}  # nicer error message
      {:error, _, %{"message" => message}} -> {:error, message}
    end
  end

  @doc """
  Create a new directory at `path`.

  Returns `:ok` or raises `Diamorfosi.KeyError`.

  See `mkdir/2` for details.
  """
  def mkdir!(path, options \\ []) do
    case mkdir(path, options) do
      :ok -> :ok
      {:error, message} ->
        raise Diamorfosi.KeyError, message: "mkdir #{path}: #{message}"
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
  Remove an empty directory at `path`.
  """
  def rmdir(path, options \\ []) do
    case API.delete(path, [dir: true]++options, decode_body: :error) do
      {:ok, nil} -> :ok
      {:error, _, %{"message" => message}} -> {:error, message}
    end
  end

  @doc """
  Create a new in-order key in directory at `path`.

  Returns `{:ok, <key>}` with the new key in case of success or `{:error,
  <reason>}` in case of failure.

  Reference: https://coreos.com/docs/distributed-configuration/etcd-api/#toc_10

  ## Examples

      {:ok, key1} = Diamorfosi.put("/put_test/dir", "hello")
      key2 = Diamorfosi.put!("/put_test/dir", "world")
      "world" = Diamorfosi.fetch!("/put_test/dir/" <> key2)

  """
  def put(path, value, options \\ []) do
    api_val = encode_value(value, Keyword.get(options, :type, :str))
    case API.post(path, api_val, options) do
      {:ok, %{"node" => %{"key" => key}}} -> {:ok, trunc_key(key)}
      {:error, _, %{"message" => message}} -> {:error, message}
    end
  end

  @doc """
  Create a new in-order key in directory at `path`.

  Returns just the new key or raises.

  See `put/3` for details.
  """
  def put!(path, value, options \\ []) do
    case put(path, value, options) do
      {:ok, key} -> key
      {:error, message} ->
        raise Diamorfosi.KeyError, message: "put #{path}: #{message}"
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

  defp split_options(options, api_keys) do
    {options, api_options} = Enum.partition(options, fn {name, _} ->
      Enum.member?(api_keys, name)
    end)
    {api_options, options} = case Keyword.pop(options, :condition, nil) do
      {nil, options} -> {api_options, options}
      {condition, options} -> {condition ++ api_options, options}
    end
    {api_options, options}
  end

  defp process_api_value(value, options) do
    node = value["node"]
    case {node["dir"], Keyword.get(options, :dir, false)} do
      {true, true} -> {:ok, process_dir_listing(node["nodes"], options)}
      {true, false} -> {:error, "Not a file"}
      {nil, _} -> decode_api_node(node, options)
    end
  end

  defp decode_api_node(node, options) do
    value = node["value"]
    type = Keyword.get(options, :type, :str)
    try do
      {:ok, decode_value(value, type)}
    rescue
      # FIXME: this may hide programming bugs
      _ -> {:error, "Failed to parse #{value} as #{value}"}
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
