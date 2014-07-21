defmodule Diamorfosi.API do
  @moduledoc false

  @default_timeout 5000

  alias HTTPoison.Response, as: HttpResp

  def get("/"<>_=keypath, api_options, options \\ []) do
    timeout = Keyword.get(options, :timeout, @default_timeout)

    headers = []
    url = "#{etcd_url}#{keypath}#{params_to_query_string(api_options)}"

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
        {:ok, decode_body(body, options)}

      %HttpResp{status_code: status, body: body} ->
        {:error, status, decode_body(body, options)}
    end
  end

  def put("/"<>_=keypath, value, api_options, options \\ []) do
    timeout = Keyword.get(options, :timeout, @default_timeout)

    {return_body, options} = Keyword.pop(options, :return_body, false)

    headers = [{"Content-Type", "application/x-www-form-urlencoded"}]
    url = "#{etcd_url}#{keypath}#{params_to_query_string(api_options)}"
    body = if api_options[:dir] do
      ""
    else
      "value=#{value}"
    end

    case HTTPoison.request(:put, url, body, headers, [timeout: timeout]) do
      %HttpResp{status_code: code, body: body} when code in [200, 201] ->
        {:ok, decode_body(body, options)}

      #%HttpResp{status_code: 307, headers: headers} ->
        #IO.inspect headers
        #put(keypath, value, options)

      %HttpResp{status_code: status, body: body} ->
        {:error, status, decode_body(body, options)}
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
      %HttpResp{status_code: status, body: body} ->
        {:error, status, Jazz.decode!(body)}
    end
  end

  def delete("/"<>_=keypath, options) do
    {timeout, options} = Keyword.pop(options, :timeout, @default_timeout)
    {recursive, options} = Keyword.pop(options, :recursive, false)
    {dir, options} = Keyword.pop(options, :dir, nil)

    params = [{"recursive", recursive}, {"dir", dir}]

    headers = []
    url = "#{etcd_url}#{keypath}#{params_to_query_string(params)}"

    case HTTPoison.request(:delete, url, "", headers, [timeout: timeout]) do
      %HttpResp{status_code: 200, body: body} ->
        :ok
      %HttpResp{status_code: status, body: body} ->
        {:error, status, Jazz.decode!(body)}
    end
  end

  defp params_to_query_string(params) do
    params =
      params
      |> Enum.reject(fn {_, val} -> val == nil end)
      |> Enum.map(fn {name, val} -> "#{name}=#{val}" end)
      |> Enum.join("&")
    if params != "", do: params = "?" <> params
    params
  end

  defp decode_body(body, options) do
    if Keyword.get(options, :decode_body, true) do
      Jazz.decode!(body)
    end
  end

  defp encode_body(list) do
    list
    |> Enum.map(fn {key, val} -> "#{key}=#{val}" end)
    |> Enum.join("&")
  end

  defp etcd_url, do: Application.get_env(:diamorfosi, :etcd_url)
end
