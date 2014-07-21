defmodule DiamorfosiTest.SerializeTest do
  use ExUnit.Case

  import Diamorfosi.Serialize

  test "serializing works" do
    val = %{some: :value}
    assert val == (val |> serialize |> unserialize)
  end
end
