defmodule BloomexTest do
  use ExUnit.Case

  test "scalable add, check membership and size" do
    bloom = Bloomex.scalable(1000, 0.01, 0.25, 2)
    assert Bloomex.member?(bloom, 100) == false

    bloom = Bloomex.add(bloom, 100)
    assert Bloomex.member?(bloom, 100) == true

    assert Bloomex.size(bloom) == 1
  end

  test "plain check membership, check capacity and size" do
    bloom = Bloomex.plain(50, 0.10)
    assert Bloomex.member?(bloom, 5) == false

    assert Bloomex.capacity(bloom) == 52
    assert Bloomex.size(bloom) == 0

    bloom = Bloomex.add(bloom, 2) |> Bloomex.add(3) |> Bloomex.add(2) |> Bloomex.add(10)
    assert Bloomex.member?(bloom, 10) == true
  end

  test "plain add" do
    bloom = Bloomex.plain(1_000_000, 0.001) |> Bloomex.add(5)
    assert Bloomex.member?(bloom, 5) == true
  end

  test "scalable with lots of additions" do
    bloom = Bloomex.scalable(6000, 0.001, 0.001, 3)

    bloom = Enum.reduce(1..10000, bloom, fn x, acc -> Bloomex.add(acc, x) end)
    assert Bloomex.size(bloom) == 9998
  end

  test "scalable force mb to be bigger than 16" do
    bloom = Bloomex.scalable(100, 0.1, 0.1, 3)

    bloom = Enum.reduce(1..90000, bloom, fn x, acc -> Bloomex.add(acc, x) end)
    assert Bloomex.member?(bloom, 1) == true
    assert Bloomex.size(bloom) == 80253
  end

  test "scalable serialization" do
    bloom =
      Bloomex.scalable(1000, 0.01, 0.25, 2)
      |> Bloomex.add(1000)

    deserialized_bloom =
      Bloomex.serialize(bloom)
      |> Bloomex.deserialize()

    assert Bloomex.member?(deserialized_bloom, 1000)
  end

  test "plain serialization" do
    bloom =
      Bloomex.plain(1000, 0.10)
      |> Bloomex.add(1000)

    deserialized_bloom =
      Bloomex.serialize(bloom)
      |> Bloomex.deserialize()

    assert Bloomex.member?(deserialized_bloom, 1000)
  end
end
