ExUnit.start

defmodule DiamorfosiTest.Helpers do
  def cleanup(root) do
    case Diamorfosi.API.delete root, recursive: true do
      :ok -> :ok
      {:error, :not_found} -> :ok
      other -> other
    end
  end
end
