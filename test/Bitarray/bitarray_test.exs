defmodule BitarrayTest do
  use ExUnit.Case

  test "bitarray creation" do
    ba = Bloomex.Bitarray.new(1)
    assert :array.is_array(ba)
  end

  test "bitarray set and get" do
    ba = Bloomex.Bitarray.new(1009)
    ba = Bloomex.Bitarray.set(ba, 1024)
    assert Bloomex.Bitarray.get(ba, 1024) == true
  end

  test "bitarray value not set" do
    ba = Bloomex.Bitarray.new(1)
    assert Bloomex.Bitarray.get(ba, 5) == false
  end
end
