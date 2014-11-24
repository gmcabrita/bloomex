defmodule Bloomex.Bitarray do
  @moduledoc """
  This module implements a bit array using Erlang's `:array` module.
  """

  use Bitwise

  @type t :: :array.array()

  @w 24

  @doc """
  Returns a new bitarray of size `n`.
  """
  @spec new(pos_integer) :: t
  def new(n) do
    div(n - 1, @w) + 1 |> :array.new {:default, 0}
  end

  @doc """
  Returns an updated bitarray where the `i`th bit is set.
  """
  @spec set(t, non_neg_integer) :: t
  def set(a, i) do
    ai = div i, @w
    v = :array.get ai, a
    v = v ||| 1 <<< (rem i, @w)
    :array.set ai, v, a
  end

  @doc """
  Returns `true` if the bitarray has the `i`th bit set,
  otherwise returns `false`.
  """
  @spec get(t, non_neg_integer) :: boolean
  def get(a, i) do
    ai = div i, @w
    v = :array.get ai, a
    (v &&& 1 <<< (rem i, @w)) !== 0
  end
end
