defmodule DiamorfosiTest.TypesTest do
  use ExUnit.Case

  import DiamorfosiTest.Helpers

  setup_all do
    on_exit fn -> cleanup("/types_test") end
    cleanup("/types_test")
  end

  test "string" do
    str = "string with URL-unfriendliness // +=%13"

    :ok = Diamorfosi.set("/types_test/a", str)
    assert ^str = Diamorfosi.fetch!("/types_test/a")

    :ok = Diamorfosi.set("/types_test/a", str, type: :str)
    assert ^str = Diamorfosi.fetch!("/types_test/a", type: :str)
  end

  test "stringable types" do
    :ok = Diamorfosi.set("/types_test/int", 13)
    :ok = Diamorfosi.set("/types_test/float", 4.13e-65)
    :ok = Diamorfosi.set("/types_test/atom", :"atomic kitten")
    :ok = Diamorfosi.set("/types_test/charlist", 'printable list')
    :ok = Diamorfosi.set("/types_test/bool", true)

    assert "13" = Diamorfosi.fetch!("/types_test/int")
    assert "4.13e-65" = Diamorfosi.fetch!("/types_test/float")
    assert "atomic kitten" = Diamorfosi.fetch!("/types_test/atom")
    assert "printable list" = Diamorfosi.fetch!("/types_test/charlist")
    assert "true" = Diamorfosi.fetch!("/types_test/bool")
  end

  test "json" do
    :ok = Diamorfosi.set("/types_test/json", %{hello: "world", this: 42}, type: :json)
    assert %{"hello" => "world", "this" => 42} = Diamorfosi.fetch!("/types_test/json", type: :json)

    :ok = Diamorfosi.set("/types_test/json", 4, type: :json)
    assert 4 = Diamorfosi.fetch!("/types_test/json", type: :json)

    :ok = Diamorfosi.set("/types_test/json", ~s({"json": false}))
    assert %{"json" => false} = Diamorfosi.fetch!("/types_test/json", type: :json)
  end

  test "term" do
    map = %{hello: "world", this: 42}
    :ok = Diamorfosi.set("/types_test/term", map, type: :term)
    assert ^map = Diamorfosi.fetch!("/types_test/term", type: :term)

    tuple = {[1,-2.0,3], :tuple, make_ref()}
    :ok = Diamorfosi.set_term("/types_test/term", tuple)
    assert ^tuple = Diamorfosi.get_term("/types_test/term", nil)
  end

  test "custom" do
    list = [1, 2, 3, 4]
    encode = fn list -> Enum.reverse(list) |> :erlang.list_to_binary |> Base.url_encode64 end
    decode = fn data -> data |> Base.url_decode64! |> :erlang.binary_to_list end
    assert :ok = Diamorfosi.set("/types_test/list", list, type: encode)
    assert [4, 3, 2, 1] = Diamorfosi.get("/types_test/list", nil, type: decode)
  end
end
