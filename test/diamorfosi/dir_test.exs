defmodule DiamorfosiTest.DirTest do
  use ExUnit.Case

  import DiamorfosiTest.Helpers

  setup_all do
    on_exit fn -> cleanup("/dir_test") end
    cleanup("/dir_test")
  end

end
