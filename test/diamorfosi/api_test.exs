defmodule DiamorfosiTest.ApiTest do
  use ExUnit.Case

  # The purpose of the tests in this module is partially educational – to get
  # familiar with etcd API. In case it changes in the future, it'll probably be
  # more efficient to update tests in CrudTest and remove failing tests from
  # here.

  import DiamorfosiTest.Helpers
  alias Diamorfosi.API

  setup_all do
    cleanup("/api_test")
  end

  setup do
    on_exit fn -> cleanup("/api_test") end
  end

  test "get bad option" do
    {:ok, _} = API.put("/api_test/a", "hello", [])
    assert {:ok, %{"action" => "get"}} = API.get("/api_test/a", [donut: false])

    #assert_raise Diamorfosi.OptionError, "Bad option: {:donut, false}", fn ->
    #  API.get("/api_test", [], donut: false)
    #end
  end

  test "get file and dir" do
    assert {:error, 404, %{"message" => "Key not found"}}
           = API.get("/api_test", [])
    assert {:error, 404, nil} = API.get("/api_test", [], decode_body: false)

    {:ok, _} = API.put("/api_test/a", "hello", [])

    assert {:ok, %{"action" => "get", "node" => %{}}} = API.get("/api_test/a", [])
    assert {:ok, nil} = API.get("/api_test/a", [], decode_body: false)
    assert {:ok, %{"action" => "get", "node" => %{"dir" => true, "nodes" => [%{"value" => "hello"}]}}}
           = API.get("/api_test", [])
  end

  test "wait delete" do
    pid = self()

    # FIXME: set default timeout to a small value to test that waiting is not
    # affected by it

    spawn(fn ->
      send(pid, {:done_waiting, API.get("/api_test/a/b", wait: true)})
    end)
    refute_receive _

    {:ok, _} = API.put("/api_test/a", "...", [])
    refute_receive _

    {:ok, _} = API.put("/api_test/a", nil, dir: true)
    {:ok, _} = API.put("/api_test/a/b/c", "...", [])
    refute_receive _

    {:ok, _} = API.delete("/api_test/a/b", recursive: true)
    assert_receive {:done_waiting, {:ok, %{"action" => "delete", "node" => %{"key" => "/api_test/a/b", "dir" => true}}}}
  end

  test "wait set" do
    pid = self()

    spawn(fn ->
      send(pid, {:done_waiting, API.get("/api_test/a/b", wait: true)})
    end)
    refute_receive _

    {:ok, _} = API.put("/api_test/a/b", "done", [])
    assert_receive {:done_waiting, {:ok, %{"action" => "set", "node" => %{"key" => "/api_test/a/b", "value" => "done"}}}}
  end

  test "wait set dir" do
    pid = self()

    spawn(fn ->
      send(pid, {:done_waiting, API.get("/api_test/a/b", wait: true)})
    end)
    refute_receive _

    {:ok, _} = API.put("/api_test/a/b", nil, dir: true)
    assert_receive {:done_waiting, {:ok, %{"action" => "set", "node" => %{"key" => "/api_test/a/b", "dir" => true}}}}
  end

  test "recursive wait" do
    pid = self()

    spawn(fn ->
      send(pid, {:done_waiting, API.get("/api_test/a", wait: true, recursive: true)})
    end)
    refute_receive _

    {:ok, _} = API.put("/api_test/a/b/c", "1", [])
    assert_receive {:done_waiting, {:ok, %{"action" => "set", "node" => %{"key" => "/api_test/a/b/c", "value" => "1"}}}}
  end

  test "wait index" do
    {:ok, %{"node" => %{"createdIndex" => index}}} = API.put("/api_test/a", "hi", [])

    assert {:ok, %{"action" => "set", "node" => %{"key" => "/api_test/a", "value" => "hi"}}}
           = API.get("/api_test/a", wait: true, waitIndex: index)
  end

  test "put bad option" do
    {:ok, %{"action" => "set"}} = API.put("/api_test/a", "hello", [donut: false])

    #assert_raise Diamorfosi.OptionError, "Bad option: {:donut, false}", fn ->
    #  API.put("/api_test/a", "", [], donut: false)
    #end
  end

  test "put file and dir" do
    assert {:ok, %{"action" => "set", "node" => %{"value" => "hello"}}}
           = API.put("/api_test/a", "hello", [])
    assert {:error, _, %{"message" => "Not a directory"}}
           = API.put("/api_test/a/b", "...", [])
    assert {:error, _, %{"message" => "Not a directory"}}
           = API.put("/api_test/a/b", nil, dir: true)
    assert {:ok, %{"action" => "set", "node" => %{"dir" => true}, "prevNode" => %{"value" => "hello"}}}
           = API.put("/api_test/a", nil, dir: true)

    assert {:ok, nil} = API.put("/api_test/b", "hello", [], decode_body: false)
    assert {:ok, nil} = API.put("/api_test/a/b/c", "hello", [], decode_body: false)
    assert {:ok, %{"node" => %{"value" => "hello"}}} = API.get("/api_test/a/b/c", [])
  end

  test "compare and swap" do
    {:ok, %{"node" => %{"createdIndex" => index}}} = API.put("/api_test/a", "hello", [])
    assert {:error, _, %{"message" => "Compare failed"}}
           = API.put("/api_test/a", "bye", [prevIndex: index+1])
    assert {:error, _, %{"message" => "Compare failed"}}
           = API.put("/api_test/a", "bye", [prevIndex: index-1])
    assert {:ok, %{"action" => "compareAndSwap", "node" => %{"value" => "bye"}}}
           = API.put("/api_test/a", "bye", [prevIndex: index])

    assert {:error, 404, %{"message" => "Key not found"}}
           = API.put("/api_test/b", "...", [prevValue: "hello"])
    assert {:error, _, %{"message" => "Compare failed"}}
           = API.put("/api_test/a", "...", [prevValue: "hello"])
    assert {:ok, %{"action" => "compareAndSwap", "node" => %{"value" => "..."}}}
           = API.put("/api_test/a", "...", [prevValue: "bye"])

    assert {:error, 404, %{"message" => "Key not found"}}
           = API.put("/api_test/b", "ok", [prevExist: true])
    assert {:ok, %{"action" => "create", "node" => %{"value" => "ok"}}}
           = API.put("/api_test/b", "ok", [prevExist: false])
    assert {:ok, %{"action" => "update", "node" => %{"value" => "ko"}}}
           = API.put("/api_test/b", "ko", [prevExist: true])
  end

  test "compare and delete" do
    {:ok, _} = API.put("/api_test/a", "hello", [])
    assert {:error, _, %{"message" => "Compare failed"}}
           = API.delete("/api_test/a", [prevValue: "bye"])
    assert {:ok, %{"action" => "compareAndDelete",
              "node" => %{}, "prevNode" => %{"value" => "hello"}}}
           = API.delete("/api_test/a", [prevValue: "hello"])

    {:ok, %{"node" => %{"createdIndex" => index}}} = API.put("/api_test/a/b/c", "hi", [])
    assert {:error, _, %{"message" => "Not a file"}}
           = API.delete("/api_test/a", [prevIndex: index-1])
    assert {:error, _, %{"message" => "Not a file"}}
           = API.delete("/api_test/a", [prevIndex: index])
    assert {:error, _, %{"message" => "Not a file"}}
           = API.delete("/api_test/a", [prevIndex: index, recursive: true])
  end

  test "post dir" do
  end

  test "delete file" do
  end

  test "delete dir" do
  end

  test "time to live" do
  end
end
