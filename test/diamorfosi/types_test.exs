defmodule DiamorfosiTest.TypesTest do
  use ExUnit.Case

  import DiamorfosiTest.Helpers

  setup_all do
    on_exit fn -> cleanup("/types_test") end
    cleanup("/types_test")
  end
end
