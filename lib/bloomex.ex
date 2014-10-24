defmodule Bloomex do
  @moduledoc """
  This module implements a Scalable Bloom Filter.
  """

  @type t :: Bloom.t | ScalableBloom.t

  use Bitwise

  defmodule Bloom do
    @moduledoc """
    A plain bloom filter.
    """
    defstruct [
      :error_prob,  # error probability
      :max,         # maximum number of elements
      :mb,          # 2^mb = m, the size of each slice (bitvector)
      :size,        # number of elements
      :bv,          # list of bitvectors
      :hash_func    # hash function to use
    ]

    @type t ::
    %Bloom{
      error_prob: float,
      max: pos_integer,
      mb: pos_integer,
      size: pos_integer,
      bv: [Bitarray.t],
      hash_func: Fun
    }
  end

  defmodule ScalableBloom do
    @moduledoc """
    A scalable bloom filter.
    """
    defstruct [
      :error_prob,        # error probability
      :error_prob_ratio,  # error probability ratio
      :growth,            # log 2 of growth ratio
      :size,              # number of elements
      :b,                 # list of plain bloom filters
      :hash_func          # hash function to use
    ]

    @type t ::
    %ScalableBloom{
      error_prob: float,
      error_prob_ratio: float,
      growth: pos_integer,
      size: pos_integer,
      b: [Bloom.t],
      hash_func: Fun
    }
  end

  @doc """
  Returns a new plain bloom filter with:
    * capacity `n`
    * error probability `e`

  The bloom filter will use the provided hash function `hash_func` which is
  expected to be of type `hash_func(atom) :: pos_integer`.
  """
  @spec new_plain_bloom(pos_integer, float, Fun) :: Bloom.t
  def new_plain_bloom(n, e \\ 0.001, hash_func \\ &(:erlang.phash2(&1, 1 <<< 32))) when is_number(e) and n > 0
  and is_float(e) and e > 0 and e < 1 and n >= 4 / e do
    bloom(:size, n, e, hash_func)
  end


  @spec bloom(Atom, pos_integer, float, Fun) :: Bloom.t
  defp bloom(mode, capacity, e, hash_func) do
    k = 1 + trunc(log2(1 / e))
    p = :math.pow(e, 1 / k)

    case mode do
      :size -> mb = 1 + trunc(-log2(1 - :math.pow(1 - p, 1 / e)))
      :bits -> mb = capacity
    end

    m = 1 <<< mb
    n = trunc(:math.log(1 - p) / :math.log(1 - 1 / m))

    %Bloom{error_prob: e, max: n, mb: mb, size: 0,
      bv: (for _ <- 1..k, do: Bitarray.new(1 <<< mb)),
      hash_func: hash_func
    }
  end

  @doc """
  Returns a new scalable bloom filter with:
    * initial capacity `n`
    * error probability `e`
    * growth ratio `1`

  When using this function the error probability ratio is provided for you.
  """
  @spec new(pos_integer, float) :: ScalableBloom.t
  def new(n, e \\ 0.001), do: new(n, e, 1)

  @doc """
  Returns a new scalable bloom filter with:
    * initial capacity `n`
    * error probability `e`
    * the specified growth ratio, which can be `1`, `2` or `3`

  When using this function the error probability ratio is provided for you.
  """
  @spec new(pos_integer, float, pos_integer) :: ScalableBloom.t
  def new(n, e, 1), do: new(n, e, 1, 0.85)
  def new(n, e, 2), do: new(n, e, 2, 0.75)
  def new(n, e, 3), do: new(n, e, 3, 0.65)

  @doc """
  Returns a new scalable bloom filter with:
    * initial capacity `n`
    * error proability `e`
    * growth ratio `g`, `g` can be `1`, `2` or `3`
    * error probability ratio `r`

  The bloom filter will use the provided hash function `hash_func` which is
  expected to be of type `hash_func(atom) :: pos_integer`.
  """
  @spec new(pos_integer, float, pos_integer, float, Fun) :: ScalableBloom.t
  def new(n, e, g, r, hash_func \\ &(:erlang.phash2(&1, 1 <<< 32))) when is_number(n) and n > 0 and is_float(e)
  and e > 0 and e < 1 and is_integer(g) and g > 0 and g < 4 and is_float(r)
  and r > 0 and r < 1 and n >= 4 / (e * (1 - r)) do
    %ScalableBloom{error_prob: e, error_prob_ratio: r, growth: g, size: 0,
      b: [new_plain_bloom(n, e * (1 - r))],
      hash_func: hash_func
    }
  end

  @doc """
  Returns the number of elements currently in the bloom filter.
  """
  @spec size(Bloomex.t) :: pos_integer
  def size(%Bloom{size: size}), do: size
  def size(%ScalableBloom{size: size}), do: size

  @doc """
  Returns the capacity of the bloom filter.
  A plain bloom filter will always have a fixed capacity, while a scalable one
  will always have a theoretically infite capacity.
  """
  @spec capacity(Bloomex.t) :: pos_integer | :infinity
  def capacity(%Bloom{max: n}), do: n
  def capacity(%ScalableBloom{}), do: :infinity

  @doc """
  Returns `true` if the `e` exists in the bloom filter, otherwise returns `false`.

  Keep in mind that you may get false positives, but never false negatives.
  """
  @spec member?(Bloomex.t, any) :: boolean
  def member?(%Bloom{mb: mb, hash_func: hash_func} = bloom, e) do
    hashes = make_hashes(mb, e, hash_func)
    hash_member(hashes, bloom)
  end

  def member?(%ScalableBloom{b: [%Bloom{mb: mb, hash_func: hash_func} | _]} = bloom, e) do
    hashes = make_hashes(mb, e, hash_func)
    hash_member(hashes, bloom)
  end

  @spec hash_member(pos_integer, Bloomex.t) :: boolean
  defp hash_member(hashes, %Bloom{mb: mb, bv: bv}) do
    mask = 1 <<< mb - 1
    {i1, i0} = make_indexes(mask, hashes)

    all_set(mask, i1, i0, bv)
  end

  defp hash_member(hashes, %ScalableBloom{b: b}) do
    Enum.any?(b, &hash_member(hashes, &1))
  end

  @spec make_hashes(pos_integer, any, Fun) :: pos_integer | {pos_integer, pos_integer}
  defp make_hashes(mb, e, hash_func) when mb <= 16 do
    hash_func.({e})
  end

  defp make_hashes(mb, e, hash_func) when mb >= 32 do
    {hash_func.({e}), hash_func.([e])}
  end

  @spec make_indexes(pos_integer, {pos_integer, pos_integer}) :: {pos_integer, pos_integer}
  defp make_indexes(mask, {h0, h1}) when mask > 1 <<< 16 do
    masked_pair(mask, h0, h1)
  end

  defp make_indexes(mask, {h0, _}) do
    make_indexes(mask, h0)
  end

  @spec make_indexes(pos_integer, pos_integer) :: {pos_integer, pos_integer}
  defp make_indexes(mask, h0) do
    masked_pair(mask, h0 >>> 16, h0)
  end

  @spec masked_pair(pos_integer, pos_integer, pos_integer) :: {pos_integer, pos_integer}
  defp masked_pair(mask, x, y), do: {x &&& mask, y &&& mask}

  @spec all_set(pos_integer, pos_integer, pos_integer, [Bloom.t]) :: boolean
  defp all_set(_, _, _, []), do: true
  defp all_set(mask, i1, i, [h | t]) do
    case Bitarray.get(h, i) do
      true  -> all_set(mask, i1, (i + i1) &&& mask, t)
      false -> false
    end
  end

  @doc """
  Returns a bloom filter with the element `e` added.
  """
  @spec add(Bloomex.t, any) :: Bloomex.t
  def add(%Bloom{mb: mb, hash_func: hash_func} = bloom, e) do
    hashes = make_hashes(mb, e, hash_func)
    hash_add(hashes, bloom)
  end

  def add(%ScalableBloom{error_prob_ratio: r, size: size, growth: g, b: [h | t] = bs} = bloom, e) do
    %Bloom{mb: mb, error_prob: err, max: n, size: head_size, hash_func: hash_func} = h
    hashes = make_hashes(mb, e, hash_func)
    case hash_member(hashes, bloom) do
      true  -> bloom
      false ->
        case head_size < n do
          true  -> %{bloom | size: size + 1, b: [hash_add(hashes, h) | t]}
          false ->
            b = bloom(:bits, mb + g, err * r, hash_func) |> add e
            %{bloom | size: size + 1, b: [b | bs]}
        end
    end
  end

  @spec hash_add(pos_integer, Bloom.t) :: Bloom.t
  defp hash_add(hashes, %Bloom{mb: mb, bv: bv, size: size} = b) do
    mask = 1 <<< mb - 1
    {i1, i0} = make_indexes(mask, hashes)

    case all_set(mask, i1, i0, bv) do
      true  -> b
      false -> %{b | size: size + 1, bv: set_bits(mask, i1, i0, bv, [])}
    end
  end

  @spec set_bits(pos_integer, pos_integer, pos_integer, [Bitarray.t], [Bitarray.t]) :: [Bitarray.t]
  defp set_bits(_, _, _, [], acc), do: Enum.reverse acc
  defp set_bits(mask, i1, i, [h | t], acc) do
    set_bits(mask, i1, (i + i1) &&& mask, t, [Bitarray.set(h, i) | acc])
  end

  @spec log2(number) :: number
  defp log2(x) do
    :math.log(x) / :math.log(2)
  end
end
