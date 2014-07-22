defmodule ExceteraTest.MiscTest do
  use ExUnit.Case

  import ExceteraTest.Helpers

  setup_all do
    cleanup("/misc_test")
  end

  setup do
    on_exit fn -> cleanup("/misc_test") end
  end

  test "waiting" do
    pid = self()

    spawn_link(fn ->
      send(pid, {:done_waiting, Excetera.fetch!("/misc_test/a", wait: true)})
    end)
    refute_receive _

    :ok = Excetera.set "/misc_test/a", "1"
    assert_receive {:done_waiting, "1"}
  end

  test "get and fetch timeout" do
    # TODO: investigate hackney timeouts
  end

  test "set timeout" do
    # TODO: investigate hackney timeouts
  end

  test "wait timeout" do
    # TODO: investigate hackney timeouts
    #Application.put_env(:excetera, :timeout, 10)

    #pid = self()
    #spawn_link(fn ->
    #  send(pid, {:done_waiting, Excetera.fetch!("/misc_test/w", wait: true)})
    #end)
    #:timer.sleep(100)
    #refute_receive _

    #:ok = Excetera.set("/misc_test/w", "tadam!")
    #assert_receive {:done_waiting, "tadam!"}
  after
    :application.unset_env(:excetera, :timeout)
  end

  test "wait explicit timeout" do
    #pid = self()
    #spawn_link(fn ->
    #  send(pid, {:done_waiting, Excetera.fetch("/misc_test/w", wait: true, timeout: 10)})
    #end)
    #refute_receive _
    #:timer.sleep(100)
    #assert_receive {:done_waiting, {:error, "Timeout"}}
  end

  test "compare and swap" do
    assert {:error, "Key not found"} = Excetera.set("/misc_test/a", "1", condition: [prevExist: true])
    assert :ok = Excetera.set("/misc_test/a", "1", condition: [prevExist: false])
    assert {:error, "Key already exists"} = Excetera.set("/misc_test/a", "2", condition: [prevExist: false])
    assert {:error, "Compare failed"} = Excetera.set("/misc_test/a", "2", condition: [prevValue: "2"])
    assert :ok = Excetera.set("/misc_test/a", "2", condition: [prevValue: "1"])
  end

  test "compare and delete" do
    :ok = Excetera.set("/misc_test/a/b", "1")
    assert {:error, "Not a file"} = Excetera.delete("/misc_test/a", condition: [prevValue: "1"])
    assert {:error, "Compare failed"} = Excetera.delete("/misc_test/a/b", condition: [prevValue: "2"])
    assert :ok = Excetera.delete("/misc_test/a/b", condition: [prevValue: "1"])
    assert {:error, "Key not found"} = Excetera.fetch("/misc_test/a/b")
  end

  @tag :slowpoke
  test "setting with TTL" do
    :ok = Excetera.set "/crud_test_ttl", "valuex", [ttl: 1]
    :timer.sleep 1500
    assert Excetera.get("/crud_test_ttl", false) == false
  end

  @tag :slowpoke
  test "directory ttl" do
    :ok = Excetera.mkdir("/api_test/a", [ttl: 1])
    assert {:ok, key1} = Excetera.put("/api_test/a", "1")
    assert "1" = Excetera.fetch!("/api_test/a/#{key1}")
    :timer.sleep(1500)
    assert {:error, "Key not found"} = Excetera.fetch("/api_test/a/#{key1}")
    assert {:error, "Key not found"} = Excetera.fetch("/api_test/a")
  end
end
