defmodule DiamorfosiTest.CrudTest do
  use ExUnit.Case

  import DiamorfosiTest.Helpers

  setup_all do
    cleanup("/crud_test")
  end

  setup do
    on_exit fn -> cleanup("/crud_test") end
  end

  test "setting and getting values" do
    Diamorfosi.set "/crud_test/a", "A node"
    Diamorfosi.set "/crud_test/dir/b", "B node"
    assert Diamorfosi.fetch("/crud_test/a") == {:ok, "A node"}
    assert Diamorfosi.fetch!("/crud_test/dir/b") == "B node"
    assert Diamorfosi.get("/crud_test/dir/b", :def) == "B node"
    assert Diamorfosi.get("/crud_test/dir/c", :def) == :def
  end

  test "implicit dir" do
    Diamorfosi.set "/crud_test/dir/a", "A node"
    Diamorfosi.set "/crud_test/dir/b", "B node"
    assert Diamorfosi.fetch("/crud_test/dir") == {:error, :is_dir}
    assert Diamorfosi.fetch("/crud_test/dir", list: true) ==
           {:ok, %{"a" => "A node", "b" => "B node"}}
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
