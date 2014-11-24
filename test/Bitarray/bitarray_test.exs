defmodule BitarrayTest do
  use ExUnit.Case

  test "bitarray creation" do
    ba = Bloomex.BitArray.new(1)
    assert :array.is_array(ba)
  end

  test "bitarray set and get" do
    ba = Bloomex.BitArray.new(1009)
    ba = Bloomex.BitArray.set(ba, 1024)
    assert Bloomex.BitArray.get(ba, 1024) == true
  end

  test "bitarray value not set" do
    ba = Bloomex.BitArray.new(1)
    assert Bloomex.BitArray.get(ba, 5) == false
  end
end
