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
    Diamorfosi.set "/dir_test/a", "1"
    Diamorfosi.set "/dir_test/dir/b", "2"
    Diamorfosi.set "/dir_test/dir/c", "3"
    Diamorfosi.set "/dir_test/dir/d/e", "4"
    Diamorfosi.set "/dir_test/dir/d/f", "5"

    assert Diamorfosi.lsdir("/dir_test/0") == {:error, :not_found}
    assert Diamorfosi.lsdir("/dir_test/a") == {:error, :not_a_dir}
    assert Diamorfosi.lsdir("/dir_test/dir") ==
           {:ok, %{"b" => "2", "c" => "3", "d" => %{}}}
    assert Diamorfosi.lsdir("/dir_test/dir", recursive: true) ==
           {:ok, %{"b" => "2", "c" => "3", "d" => %{"e" => "4", "f" => "5"}}}
  end
end
