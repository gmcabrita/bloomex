defmodule BitarrayTest do
  use ExUnit.Case

  test "bitarray creation" do
    ba = Bitarray.new(1)
    assert :array.is_array(ba)
  end

  test "bitarray set and get" do
    ba = Bitarray.new(1009)
    ba = Bitarray.set(1024, ba)
    assert Bitarray.get(1024, ba) == true
  end

  test "bitarray value not set" do
    ba = Bitarray.new(1)
    assert Bitarray.get(5, ba) == false
  end
end
