defmodule ExceteraTest.CrudTest do
  use ExUnit.Case

  import ExceteraTest.Helpers

  setup_all do
    cleanup("/crud_test")
  end

  setup do
    on_exit fn -> cleanup("/crud_test") end
  end

  test "setting and getting values" do
    :ok = Excetera.set "/crud_test/a", "A node"
    :ok = Excetera.set! "/crud_test/dir/b", "B node"
    assert Excetera.fetch("/crud_test/a") == {:ok, "A node"}
    assert Excetera.fetch!("/crud_test/dir/b") == "B node"
    assert Excetera.get("/crud_test/dir/b", :def) == "B node"
    assert Excetera.get("/crud_test/dir/c", :def) == :def
  end

  test "raising fetch" do
    assert {:error, "Key not found"} = Excetera.fetch("/crud_test/a")
    assert_raise Excetera.KeyError, "fetch /crud_test/a: Key not found", fn ->
      Excetera.fetch!("/crud_test/a")
    end
  end

  test "get directory" do
    :ok = Excetera.set "/crud_test/dir/a", "A node"
    :ok = Excetera.set "/crud_test/dir/b", "B node"
    assert_raise Excetera.KeyError, "get /crud_test/dir: Not a file", fn ->
      Excetera.get("/crud_test/dir", nil)
    end
    assert %{"a" => "A node", "b" => "B node"} = Excetera.get("/crud_test/dir", nil, dir: true)
  end

  test "set directory" do
    :ok = Excetera.set "/crud_test/dir/a", "A node"
    assert {:error, "Not a file"} = Excetera.set("/crud_test/dir", "value")
    assert_raise Excetera.KeyError, "set /crud_test/dir: Not a file", fn ->
      Excetera.set!("/crud_test/dir", "value")
    end
  end

  test "delete" do
    :ok = Excetera.set "/crud_test/a", "A node"
    assert Excetera.fetch!("/crud_test/a") == "A node"
    assert :ok = Excetera.delete "/crud_test/a"
    assert {:error, "Key not found"} = Excetera.fetch "/crud_test/a"
  end

  test "delete dir" do
    :ok = Excetera.set "/crud_test/a/b/c/d", "D node"
    assert {:error, "Not a file"} = Excetera.delete "/crud_test/a/b/c"
    assert_raise Excetera.KeyError, "delete /crud_test/a/b/c: Not a file", fn ->
      Excetera.delete! "/crud_test/a/b/c"
    end
    assert {:error, "Directory not empty"} = Excetera.rmdir "/crud_test/a/b/c"
    :ok = Excetera.delete "/crud_test/a/b/c/d"
    assert :ok = Excetera.rmdir "/crud_test/a/b/c"
    assert :ok = Excetera.delete "/crud_test/a", recursive: true
  end

  test "implicit dir" do
    :ok = Excetera.set "/crud_test/dir/a", "A node"
    :ok = Excetera.set "/crud_test/dir/b", "B node"
    assert Excetera.fetch("/crud_test/dir") == {:error, "Not a file"}
    assert Excetera.fetch("/crud_test/dir", dir: true) ==
           {:ok, %{"a" => "A node", "b" => "B node"}}
  end

  test "setting json" do
    :ok = Excetera.set "/crud_test/complex", %{some: "value"}, type: :json
    assert Excetera.fetch!("/crud_test/complex", type: :json) == %{"some" => "value"}
  end

  test "setting terms" do
    value = %{some: "value", with: {:a, 0.13, 'tuple'}}
    :ok = Excetera.set_term "/crud_test/term", value
    assert Excetera.get_term("/crud_test/term", nil) === value
    assert Excetera.fetch!("/crud_test/term", type: :term) === value
  end
end
