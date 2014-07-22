defmodule Excetera.API.Error do
  defstruct errorCode: 0, message: "", cause: "", index: 0
end

defmodule Excetera.API do
  @body_headers [{"Content-Type", "application/x-www-form-urlencoded"}]

  def get("/"<>_=path, api_options, options \\ []) do
    url = build_url(path, api_options)
    if api_options[:wait] && not Keyword.has_key?(options, :timeout) do
      # set timeout to :infinity unless it was set explicitly
      options = Keyword.update(options, :timeout, :infinity, & &1)
    end
    request(:get, url, [], "", options)
  end

  def put("/"<>_=path, value, api_options, options \\ []) do
    url = build_url(path, api_options)

    {ttl, api_options} = Keyword.pop(api_options, :ttl, nil)
    if api_options[:dir], do: value = nil
    body_params = [value: value, ttl: ttl] |> filter_nil
    body = params_to_query_string(body_params)

    request(:put, url, @body_headers, body, options)
  end

  def post("/"<>_=path, value, options) do
    {timeout, options} = Keyword.pop(options, :timeout, default_timeout)

    url = build_url(path, [])
    body = encode_body([value: value] ++ options)  # FIXME: do we really need to encode options?

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
    |> filter_nil
    |> Enum.map(fn {name, val} -> "#{name}=#{val}" end)
    |> Enum.join("&")
  end

  defp filter_nil(kwlist) do
    Enum.reject(kwlist, fn {_, val} -> val == nil end)
  end

  defp request(type, url, headers, body, options) do
    timeout = Keyword.get(options, :timeout, default_timeout)

    case HTTPoison.request(type, url, body, headers, [timeout: timeout]) do
      %HTTPoison.Response{status_code: code, body: body} when code in [200, 201] ->
        {:ok, decode_body(:ok, body, options)}

      %HTTPoison.Response{status_code: 307} ->
        # try again, die hard mode
        request(type, url, headers, body, options)

      %HTTPoison.Response{status_code: status, body: body} ->
        {:error, decode_body(:error, body, options) || status}
    end
  end

  defp decode_body(:ok, body, options) do
    case Keyword.get(options, :decode_body, true) do
      succ when succ in [true, :success] -> Jazz.decode!(body)
      _ -> nil
    end
  end

  defp decode_body(:error, body, options) do
    case Keyword.get(options, :decode_body, true) do
      err when err in [true, :error] ->
        Jazz.decode!(body, as: Excetera.API.Error)
      _ -> nil
    end
  end

  defp encode_body(list) do
    list
    |> Enum.map(fn {key, val} -> "#{key}=#{val}" end)
    |> Enum.join("&")
  end

  defp etcd_url, do: Application.get_env(:excetera, :etcd_url)
  defp default_timeout, do: Application.get_env(:excetera, :timeout, 5000)
end
