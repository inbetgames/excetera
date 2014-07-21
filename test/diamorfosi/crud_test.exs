defmodule DiamorfosiTest.CrudTest do
  use ExUnit.Case

  import DiamorfosiTest.Helpers

  setup_all do
    on_exit fn -> cleanup("/crud_test") end
    cleanup("/crud_test")
  end

  test "setting values" do
    Diamorfosi.set "/crud_test", "A node"
    assert Diamorfosi.fetch!("/crud_test") == "A node"
  end

  test "setting complex values" do
    Diamorfosi.set "/crud_test_complex", %{some: "value"}, type: :json
    assert Diamorfosi.fetch!("/crud_test_complex", type: :json) == %{"some" => "value"}
  end

  test "setting with TTL" do
    Diamorfosi.set "/crud_test_ttl", "valuex", [ttl: 1]
    :timer.sleep 1500
    assert Diamorfosi.get("/crud_test_ttl", false) == false
  end
end
