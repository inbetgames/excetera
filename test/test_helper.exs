ExUnit.start exclude: [:slowpoke]

defmodule DiamorfosiTest.Helpers do
  def cleanup(root) do
    case Diamorfosi.API.delete root, [recursive: true], decode_body: false do
      {:ok, _} -> :ok
      {:error, 404} -> :ok
      other -> other
    end
  end
end
