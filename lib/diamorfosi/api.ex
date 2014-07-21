defmodule Diamorfosi.API do
  @moduledoc false

  @default_timeout 5000

  alias HTTPoison.Response, as: HttpResp

  def get("/"<>_=keypath, options) do
    timeout = Keyword.get(options, :timeout, @default_timeout)
    {recursive, options} = Keyword.pop(options, :recursive, nil)
    {sorted, options} = Keyword.pop(options, :sort, nil)

    params =
      [{"recursive", recursive}, {"sorted", sorted}]
      |> Enum.reject(fn {_, val} -> val == nil end)
      |> Enum.map(fn {name, val} -> "#{name}=#{val}" end)
      |> Enum.join("&")
    if params != "", do: params = "?" <> params

    headers = []
    url = "#{etcd_url}#{keypath}#{params}"

    #    case options[:waitIndex] do
    #      nil ->
    #        get("#{path}", options)
    #        |> (fn reply ->
    #          wait path, Keyword.update(options, :waitIndex, (reply["modifiedIndex"] + 1), &(&1))
    #        end).()
    #      value when is_integer(value) ->
    #        options = Keyword.delete options, :waitIndex
    #        get("#{path}?wait=true&waitIndex=#{value}", options)
    #    end

    case HTTPoison.get(url, headers, [timeout: timeout]) do
      %HttpResp{status_code: 200, body: body} ->
        {:ok, body |> Jazz.decode!}

      %HttpResp{status_code: 404, body: _body} ->
        {:error, :not_found}

      _ ->
        {:error, :unknown}
    end
  end

  def put("/"<>_=keypath, value, options) do
    {timeout, options} = Keyword.pop(options, :timeout, @default_timeout)
    {return_body, options} = Keyword.pop(options, :return_body, false)

    headers = [{"Content-Type", "application/x-www-form-urlencoded"}]
    url = "#{etcd_url}#{keypath}"
    body = encode_body([value: value] ++ options)

    case HTTPoison.request(:put, url, body, headers, [timeout: timeout]) do
      %HttpResp{status_code: code, body: body} when code in [200, 201] ->
        if return_body do
          {:ok, body |> Jazz.decode!}
        else
          :ok
        end
      %HttpResp{status_code: 307, headers: headers} ->
        IO.inspect headers
        put(keypath, value, options)
      _ -> :error
    end
  end

  def post("/"<>_=keypath, value, options) do
    {timeout, options} = Keyword.pop(options, :timeout, @default_timeout)

    headers = [{"Content-Type", "application/x-www-form-urlencoded"}]
    url = "#{etcd_url}#{keypath}"
    body = encode_body([value: value] ++ options)

    case HTTPoison.request(:post, url, body, headers, [timeout: timeout]) do
      %HttpResp{status_code: code, body: body} when code in [200, 201] ->
        {:ok, body |> Jazz.decode!}
      _ -> :error
    end
  end

  def delete("/"<>_=keypath, options) do
    {timeout, options} = Keyword.pop(options, :timeout, @default_timeout)
    {recursive, options} = Keyword.pop(options, :recursive, false)
    headers = []
    url = "#{etcd_url}#{keypath}?recursive=#{recursive}"

    case HTTPoison.request(:delete, url, "", headers, [timeout: timeout]) do
      %HttpResp{status_code: 200, body: body} ->
        :ok
      %HttpResp{status_code: 404, body: _body} ->
        {:error, :not_found}
      _=other ->
        IO.inspect other
        {:error, :unknown}
    end
  end

  defp encode_body(list) do
    list
    |> Enum.map(fn {key, val} -> "#{key}=#{val}" end)
    |> Enum.join("&")
  end

  defp etcd_url, do: Application.get_env(:diamorfosi, :etcd_url)
end
