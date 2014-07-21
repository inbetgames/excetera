defmodule DiamorfosiTest.ApiTest do
  use ExUnit.Case

  import DiamorfosiTest.Helpers
  alias Diamorfosi.API

  setup_all do
    cleanup("/api_test")
  end

  setup do
    on_exit fn -> cleanup("/api_test") end
  end

  test "get bad option" do
    API.put("/api_test/a", "hello", [])
    assert {:ok, %{"action" => "get"}} = API.get("/api_test/a", [donut: false])

    #assert_raise Diamorfosi.OptionError, "Bad option: {:donut, false}", fn ->
    #  API.get("/api_test", [], donut: false)
    #end
  end

  test "get file and dir" do
    assert {:error, 404, %{"message" => "Key not found"}}
           = API.get("/api_test", [])
    assert {:error, 404, nil} = API.get("/api_test", [], decode_body: false)

    API.put("/api_test/a", "hello", [])

    assert {:ok, %{"action" => "get", "node" => %{}}} = API.get("/api_test/a", [])
    assert {:ok, nil} = API.get("/api_test/a", [], decode_body: false)
    assert {:ok, %{"action" => "get", "node" => %{"dir" => true, "nodes" => [%{"value" => "hello"}]}}}
           = API.get("/api_test", [])
  end

  test "wait" do
  end

  test "put file and dir" do
    assert {:ok, %{"action" => "set", "node" => %{"value" => "hello"}}}
           = API.put("/api_test/a", "hello", [])
    assert {:ok, %{"action" => "set", "node" => %{"dir" => true}, "prevNode" => %{"value" => "hello"}}}
           = API.put("/api_test/a", nil, dir: true)

    assert {:ok, nil} = API.put("/api_test/b", "hello", [], decode_body: false)
    assert {:ok, nil} = API.put("/api_test/a/b/c", "hello", [], decode_body: false)
    assert {:ok, %{"node" => %{"value" => "hello"}}} = API.get("/api_test/a/b/c", [])
  end

  test "put prevIndex" do
  end

  test "compare and swap" do
  end

  test "compare and delete" do
  end

  test "post dir" do
  end

  test "delete file" do
  end

  test "delete dir" do
  end
end
