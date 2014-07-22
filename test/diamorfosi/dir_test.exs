defmodule DiamorfosiTest.DirTest do
  use ExUnit.Case

  import DiamorfosiTest.Helpers

  setup_all do
    cleanup("/dir_test")
  end

  setup do
    on_exit fn -> cleanup("/dir_test") end
  end

  test "list directory" do
    assert Diamorfosi.lsdir("/dir_test/dir") == {:error, "Key not found"}

    Diamorfosi.set "/dir_test/a", "1"
    Diamorfosi.set "/dir_test/dir/b", "2"
    Diamorfosi.set "/dir_test/dir/c", "3"
    Diamorfosi.set "/dir_test/dir/d/e", "4"
    Diamorfosi.set "/dir_test/dir/d/f", "5"

    assert Diamorfosi.lsdir("/dir_test/a") == {:error, "Not a directory"}
    assert Diamorfosi.lsdir("/dir_test/dir") ==
           {:ok, %{"b" => "2", "c" => "3", "d" => %{}}}
    assert Diamorfosi.lsdir("/dir_test/dir", recursive: true) ==
           {:ok, %{"b" => "2", "c" => "3", "d" => %{"e" => "4", "f" => "5"}}}
  end

  test "put dir" do
    assert Diamorfosi.fetch("/dir_test/ord") == {:error, "Key not found"}

    {:ok, key1} = Diamorfosi.put "/dir_test/ord", "hello"
    key2 = Diamorfosi.put! "/dir_test/ord", "world"

    assert {:error, "Not a directory"} = Diamorfosi.put "/dir_test/ord/"<>key1, "hi"
    assert_raise Diamorfosi.KeyError, "put /dir_test/ord/#{key2}: Not a directory", fn ->
      Diamorfosi.put! "/dir_test/ord/"<>key2, "hi"
    end

    assert "hello" = Diamorfosi.fetch!("/dir_test/ord/"<>key1)
    assert "world" = Diamorfosi.fetch!("/dir_test/ord/"<>key2)
  end

  test "in-order keys" do
    assert Diamorfosi.lsdir("/dir_test/ord") == {:error, "Key not found"}

    key1 = Diamorfosi.put! "/dir_test/ord", "hello"
    key2 = Diamorfosi.put! "/dir_test/ord", "world"
    key3 = Diamorfosi.put! "/dir_test/ord/sub", "it's"
    key4 = Diamorfosi.put! "/dir_test/ord/sub", "me"

    map = [{key1, "hello"}, {key2, "world"}, {"sub", %{}}] |> Enum.into(%{})
    assert Diamorfosi.lsdir("/dir_test/ord") == {:ok, map}

    listing = [{key1, "hello"}, {key2, "world"}, {"sub", []}]
    assert Diamorfosi.lsdir("/dir_test/ord", sort: true) == {:ok, listing}

    rec_listing = [
      {key1, "hello"}, {key2, "world"}, {"sub", [{key3, "it's"}, {key4, "me"}]}
    ]
    assert Diamorfosi.lsdir("/dir_test/ord", sort: true, recursive: true) ==
           {:ok, rec_listing}
  end

  test "create and delete" do
    assert Diamorfosi.lsdir("/dir_test/dir") == {:error, "Key not found"}

    assert :ok = Diamorfosi.mkdir("/dir_test/dir")
    assert {:error, "Key already exists"} = Diamorfosi.mkdir("/dir_test/dir")

    assert {:error, "Not a file"} = Diamorfosi.delete("/dir_test/dir")
    assert :ok = Diamorfosi.rmdir("/dir_test/dir")

    Diamorfosi.set "/dir_test/a/b", "hi"

    assert {:error, "Not a file"} = Diamorfosi.delete("/dir_test/a")
    assert {:error, "Directory not empty"} = Diamorfosi.rmdir("/dir_test/a")

    assert :ok = Diamorfosi.delete("/dir_test/a", recursive: true)
    assert Diamorfosi.lsdir("/dir_test/a") == {:error, "Key not found"}

    Diamorfosi.set "/dir_test/a/b", "hi"
    assert Diamorfosi.fetch!("/dir_test/a/b") == "hi"
    assert :ok = Diamorfosi.rmdir("/dir_test/a", recursive: true)
    assert Diamorfosi.lsdir("/dir_test/a") == {:error, "Key not found"}
  end
end
