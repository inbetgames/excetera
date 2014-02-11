defmodule DiamorfosiTest do
  use ExUnit.Case

  test "setting values" do
    Diamorfosi.set "/test", "value"
    assert Diamorfosi.get("/test") == "value"
  end

  test "setting complex values" do
  	Diamorfosi.set "/test", [{"some", "value"}]
  	assert Diamorfosi.get("/test") == [{"some", "value"}]
  end

  test "setting with TTL" do
  	Diamorfosi.set "/test", "valuex", [ttl: 1]
  	:timer.sleep 1500
  	assert Diamorfosi.get("/test") == false
  end
end
