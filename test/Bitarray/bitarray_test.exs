defmodule BitarrayTest do
  use ExUnit.Case

  test "bitarray creation" do
    ba = Bitarray.new(1)
    assert :array.is_array(ba)
  end

  test "bitarray set and get" do
    ba = Bitarray.new(1009)
    ba = Bitarray.set(ba, 1024)
    assert Bitarray.get(ba, 1024) == true
  end

  test "bitarray value not set" do
    ba = Bitarray.new(1)
    assert Bitarray.get(ba, 5) == false
  end
end
