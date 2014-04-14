defmodule Diamorfosi.Serialize do
	defp key, do: "abcdefghabcdefgh"
	defp iv,  do: "init some vector"
	def serialize(term) do
		text = :erlang.term_to_binary(term)
		crypt = :crypto.aes_cfb_128_encrypt(key, iv, text)
		Base.url_encode64(crypt)
	end
	def unserialize(term) when is_binary(term) do
		{:ok, body} = Base.url_decode64(term)
		decrypt = :crypto.aes_cfb_128_decrypt(key, iv, body)
		:erlang.binary_to_term(decrypt)
	end
end