defmodule DiamorfosiTest do
  use ExUnit.Case

  test "setting values" do
    Diamorfosi.set "/test", "value"
    assert Diamorfosi.get("/test") == "value"
  end

  test "setting complex values" do
  	Diamorfosi.set "/test_complex", %{"some" => "value"}
  	assert Diamorfosi.get("/test_complex") == %{"some" => "value"}
  end

  test "setting with TTL" do
  	Diamorfosi.set "/test_ttl", "valuex", [ttl: 1]
  	:timer.sleep 1500
  	assert Diamorfosi.get("/test_ttl") == false
  end

  test "serializing works" do
    assert Diamorfosi.Serialize.unserialize(Diamorfosi.Serialize.serialize(%{some: :value}))
  end
end
