defmodule Diamorfosi.API do
  @default_timeout 5000
  @body_headers [{"Content-Type", "application/x-www-form-urlencoded"}]

  def get("/"<>_=path, api_options, options \\ []) do
    url = build_url(path, api_options)
    request(:get, url, [], "", options)
  end

  def put("/"<>_=path, value, api_options, options \\ []) do
    url = build_url(path, api_options)

    {ttl, api_options} = Keyword.pop(api_options, :ttl, nil)
    if api_options[:dir], do: value = nil
    body_params = [value: value, ttl: ttl] |> Enum.reject(fn {_, x} -> x == nil end)
    body = params_to_query_string(body_params)

    request(:put, url, @body_headers, body, options)
  end

  def post("/"<>_=path, value, options) do
    {timeout, options} = Keyword.pop(options, :timeout, @default_timeout)

    url = build_url(path, [])
    body = encode_body([value: value] ++ options)

    request(:post, url, @body_headers, body, [timeout: timeout])
  end

  def delete("/"<>_=path, api_options, options \\ []) do
    url = build_url(path, api_options)
    request(:delete, url, [], "", options)
  end

  ###

  defp build_url(path, []) do
    "#{etcd_url}#{path}"
  end

  defp build_url(path, options) do
    build_url(path, []) <> "?" <> params_to_query_string(options)
  end

  defp params_to_query_string(params) do
    params
    |> Enum.reject(fn {_, val} -> val == nil end)
    |> Enum.map(fn {name, val} -> "#{name}=#{val}" end)
    |> Enum.join("&")
  end

  defp request(type, url, headers, body, options) do
    timeout = Keyword.get(options, :timeout, @default_timeout)

    case HTTPoison.request(type, url, body, headers, [timeout: timeout]) do
      %HTTPoison.Response{status_code: code, body: body} when code in [200, 201] ->
        {:ok, decode_body(:ok, body, options)}

      %HTTPoison.Response{status_code: status, body: body} ->
        {:error, status, decode_body(:error, body, options)}
    end
  end

  defp decode_body(status, body, options) do
    case Keyword.get(options, :decode_body, true) do
      true -> Jazz.decode!(body)
      :success when status == :ok -> Jazz.decode!(body)
      :error when status == :error -> Jazz.decode!(body)
      _ -> nil
    end
  end

  defp encode_body(list) do
    list
    |> Enum.map(fn {key, val} -> "#{key}=#{val}" end)
    |> Enum.join("&")
  end

  defp etcd_url, do: Application.get_env(:diamorfosi, :etcd_url)
end
