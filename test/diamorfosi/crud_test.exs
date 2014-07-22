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
    :ok = Diamorfosi.set "/crud_test/a", "A node"
    :ok = Diamorfosi.set "/crud_test/dir/b", "B node"
    assert Diamorfosi.fetch("/crud_test/a") == {:ok, "A node"}
    assert Diamorfosi.fetch!("/crud_test/dir/b") == "B node"
    assert Diamorfosi.get("/crud_test/dir/b", :def) == "B node"
    assert Diamorfosi.get("/crud_test/dir/c", :def) == :def
  end

  test "delete" do
    :ok = Diamorfosi.set "/crud_test/a", "A node"
    assert Diamorfosi.fetch!("/crud_test/a") == "A node"
    assert :ok = Diamorfosi.delete "/crud_test/a"
    assert {:error, "Key not found"} = Diamorfosi.fetch "/crud_test/a"
  end

  test "delete dir" do
    :ok = Diamorfosi.set "/crud_test/a/b/c/d", "D node"
    assert {:error, "Not a file"} = Diamorfosi.delete "/crud_test/a/b/c"
    assert {:error, "Directory not empty"} = Diamorfosi.rmdir "/crud_test/a/b/c"
    :ok = Diamorfosi.delete "/crud_test/a/b/c/d"
    assert :ok = Diamorfosi.rmdir "/crud_test/a/b/c"
    assert :ok = Diamorfosi.delete "/crud_test/a", recursive: true
  end

  test "implicit dir" do
    :ok = Diamorfosi.set "/crud_test/dir/a", "A node"
    :ok = Diamorfosi.set "/crud_test/dir/b", "B node"
    assert Diamorfosi.fetch("/crud_test/dir") == {:error, :is_dir}
    assert Diamorfosi.fetch("/crud_test/dir", list: true) ==
           {:ok, %{"a" => "A node", "b" => "B node"}}
  end

  test "setting json" do
    :ok = Diamorfosi.set "/crud_test/complex", %{some: "value"}, type: :json
    assert Diamorfosi.fetch!("/crud_test/complex", type: :json) == %{"some" => "value"}
  end

  test "setting terms" do
    value = %{some: "value", with: {:a, 'tuple'}}
    :ok = Diamorfosi.set_term "/crud_test/term", value
    assert Diamorfosi.get_term("/crud_test/term", nil) == value
    assert Diamorfosi.fetch!("/crud_test/term", type: :term) == value
  end
end
