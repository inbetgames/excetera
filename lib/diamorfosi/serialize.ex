defmodule Diamorfosi.Serialize do
  defp key, do: "abcdefghabcdefgh"
  defp iv,  do: "init some vector"

  @cipher_type :aes_cfb128

  def serialize(term) do
    text = :erlang.term_to_binary(term)
    cipher = :crypto.block_encrypt(@cipher_type, key, iv, text)
    Base.url_encode64(cipher)
  end

  def unserialize(term) when is_binary(term) do
    cipher = Base.url_decode64!(term)
    text = :crypto.block_decrypt(@cipher_type, key, iv, cipher)
    :erlang.binary_to_term(text)
  end
end
