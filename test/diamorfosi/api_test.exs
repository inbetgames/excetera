defmodule DiamorfosiTest.ApiTest do
  use ExUnit.Case

  import DiamorfosiTest.Helpers

  setup_all do
    on_exit fn -> cleanup("/api_test") end
    cleanup("/api_test")
  end

end
