defmodule Bitarray do

  use Bitwise

  @w 24

  @doc """
  Returns a new bitarray of size `n`.
  """
  @spec new(Integer) :: :array.array()
  def new(n) do
    div(n - 1, @w) + 1 |> :array.new {:default, 0}
  end

  @doc """
  Returns an updated bitarray where the `i`th bit is set.
  """
  @spec set(Integer, :array.array()) :: :array.array()
  def set(i, a) do
    ai = div i, @w
    v = :array.get ai, a
    v = v ||| 1 <<< (rem i, @w)
    :array.set ai, v, a
  end

  @doc """
  Returns `true` if the bitarray has the `i`th bit set,
  otherwise returns `false`.
  """
  @spec get(Integer, :array.array()) :: boolean
  def get(i, a) do
    ai = div i, @w
    v = :array.get ai, a
    (v &&& 1 <<< (rem i, @w)) !== 0
  end
end
