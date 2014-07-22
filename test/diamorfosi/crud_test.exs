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

  test "setting complex values" do
    :ok = Diamorfosi.set "/crud_test_complex", %{some: "value"}, type: :json
    assert Diamorfosi.fetch!("/crud_test_complex", type: :json) == %{"some" => "value"}
  end
end
