defmodule DiamorfosiTest.MiscTest do
  use ExUnit.Case

  import DiamorfosiTest.Helpers

  setup_all do
    cleanup("/misc_test")
  end

  setup do
    on_exit fn -> cleanup("/misc_test") end
  end

  test "waiting" do
  end

  test "compare and swap" do
    assert {:error, "Key not found"} = Diamorfosi.set("/misc_test/a", "1", condition: [prevExist: true])
    assert :ok = Diamorfosi.set("/misc_test/a", "1", condition: [prevExist: false])
    assert {:error, "Key already exists"} = Diamorfosi.set("/misc_test/a", "2", condition: [prevExist: false])
    assert {:error, "Compare failed"} = Diamorfosi.set("/misc_test/a", "2", condition: [prevValue: "2"])
    assert :ok = Diamorfosi.set("/misc_test/a", "2", condition: [prevValue: "1"])
  end

  test "compare and delete" do
    :ok = Diamorfosi.set("/misc_test/a/b", "1")
    assert {:error, "Not a file"} = Diamorfosi.delete("/misc_test/a", condition: [prevValue: "1"])
    assert {:error, "Compare failed"} = Diamorfosi.delete("/misc_test/a/b", condition: [prevValue: "2"])
    assert :ok = Diamorfosi.delete("/misc_test/a/b", condition: [prevValue: "1"])
    assert {:error, "Key not found"} = Diamorfosi.fetch("/misc_test/a/b")
  end
end
