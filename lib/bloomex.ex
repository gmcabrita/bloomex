defmodule Bloomex do
  @moduledoc """
  This module implements a [Scalable Bloom Filter](http://asc.di.fct.unl.pt/~nmp/pubs/ref--04.pdf).

  ## Examples

      iex> bf = Bloomex.scalable(1000, 0.1, 0.1, 2)
      %Bloomex.ScalableBloom...

      iex> bf = Bloomex.add(bf, 5)
      %Bloomex.ScalableBloom...

      iex> Bloomex.member?(bf, 5)
      true

      iex> bf = Bloomex.add(bf, 100)
      %Bloomex.ScalableBloom...

      iex> Bloomex.member?(bf, 100)
      true

      iex> Bloomex.member?(bf, 105)
      false

      iex> Bloomex.member?(bf, 101) # false positive
      true

  """

  @type t :: Bloomex.Bloom.t | Bloomex.ScalableBloom.t

  use Bitwise

  defmodule Bloom do
    @moduledoc """
    A plain bloom filter.

    * :error_prob - error probability
    * :max - maximum number of elements
    * :mb - 2^mb = m, the size of each slice (bitvector)
    * :size - number of elements
    * :bv - list of bitvectors
    * :hash_func - hash function to use
    """
    defstruct [
            :error_prob,
            :max,
            :mb,
            :size,
            :bv,
            :hash_func
        ]

    @type t ::
    %Bloom{
            error_prob: float,
            max: pos_integer,
            mb: pos_integer,
            size: pos_integer,
            bv: [Bloomex.BitArray.t],
            hash_func: (term -> pos_integer)
        }
  end

  defmodule ScalableBloom do
    @moduledoc """
    A scalable bloom filter.

    * :error_prob - error probability
    * :error_prob_ratio - error probability ratio
    * :growth - log 2 of growth ratio
    * :size - number of elements
    * :b - list of plain bloom filters
    * :hash_func - hash function to use
    """
    defstruct [
            :error_prob,
            :error_prob_ratio,
            :growth,
            :size,
            :b,
            :hash_func
        ]

    @type t ::
    %ScalableBloom{
            error_prob: float,
            error_prob_ratio: float,
            growth: pos_integer,
            size: pos_integer,
            b: [Bloom.t],
            hash_func: (term -> pos_integer)
        }
  end

  @doc """
  Returns a scalable Bloom filter based on the provided arguments:
  * `capacity`, the initial capacity before expanding
  * `error`, the error probability
  * `error_ratio`, the error probability ratio
  * `growth`, the growth ratio when full
  * `hash_func`, a hashing function

  If a hash function is not provided then `:erlang.phash2/2` will be used with
  the maximum range possible `(2^32)`.

  Restrictions:
  * `capacity` must be a positive integer
  * `error` must be a float between `0` and `1`
  * `error_ratio` must be a float between `0` and `1`
  * `growth` must be a positive integer between `1` and `3`
  * `hash_func` must be a function of type `term -> pos_integer`

  The function follows a rule of thumb due to double hashing where
  `capacity >= 4 / (error * (1 - error_ratio))` must hold true.
  """
  @spec scalable(pos_integer, float, float, 1 | 2 | 3, (term -> pos_integer)) :: ScalableBloom.t
  def scalable(capacity, error, error_ratio, growth, hash_func \\ fn x -> :erlang.phash2(x, 1 <<< 32) end)
  when is_number(capacity) and capacity > 0 and is_float(error) and error > 0
  and error < 1 and is_integer(growth) and growth > 0 and growth < 4
  and is_float(error_ratio) and error_ratio > 0 and error_ratio < 1
  and capacity >= 4 / (error * (1 - error_ratio)) do
    %ScalableBloom{
            error_prob: error, error_prob_ratio: error_ratio, growth: growth, size: 0,
            b: [plain(capacity, error * (1 - error_ratio), hash_func)],
            hash_func: hash_func
        }
  end


  @doc """
  Returns a plain Bloom filter based on the provided arguments:
  * `capacity`, used to calculate the size of each bitvector slice
  * `error`, the error probability
  * `hash_func`, a hashing function

  If a hash function is not provided then `:erlang.phash2/2` will be used with
  the maximum range possible `(2^32)`.

  Restrictions:
  * `capacity` must be a positive integer
  * `error` must be a float between `0` and `1`
  * `hash_func` must be a function of type `term -> pos_integer`

  The function follows a rule of thumb due to double hashing where
  `capacity >= 4 / error` must hold true.
  """
  @spec plain(pos_integer, float, (term -> pos_integer)) :: Bloom.t
  def plain(capacity, error, hash_func \\ fn x -> :erlang.phash2(x, 1 <<< 32) end)
  when is_number(error) and capacity > 0 and is_float(error) and error > 0
  and error < 1 and capacity >= 4 / error do
    plain(:size, capacity, error, hash_func)
  end

  @spec plain(atom, pos_integer, float, (term -> pos_integer)) :: Bloom.t
  defp plain(mode, capacity, e, hash_func) do
    k = 1 + trunc(log2(1 / e))
    p = :math.pow(e, 1 / k)

    case mode do
      :size -> mb = 1 + trunc(-log2(1 - :math.pow(1 - p, 1 / e)))
      :bits -> mb = capacity
    end

    m = 1 <<< mb
    n = trunc(:math.log(1 - p) / :math.log(1 - 1 / m))

    %Bloom{
            error_prob: e, max: n, mb: mb, size: 0,
            bv: (for _ <- 1..k, do: Bloomex.BitArray.new(1 <<< mb)), hash_func: hash_func
        }
  end

  @doc """
  Returns the number of elements currently in the bloom filter.
  """
  @spec size(t) :: pos_integer
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
  Returns `true` if the element `e` exists in the bloom filter, otherwise returns `false`.

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
    mask = (1 <<< mb) - 1
    {i1, i0} = make_indexes(mask, hashes)

    all_set(mask, i1, i0, bv)
  end

  defp hash_member(hashes, %ScalableBloom{b: b}) do
    Enum.any?(b, &hash_member(hashes, &1))
  end

  @spec make_hashes(pos_integer, any, (term -> pos_integer)) :: pos_integer | {pos_integer, pos_integer}
  defp make_hashes(mb, e, hash_func) when mb <= 16 do
    hash_func.({e})
  end

  defp make_hashes(mb, e, hash_func) when mb <= 32 do
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

  @spec all_set(pos_integer, pos_integer, pos_integer, [Bloomex.BitArray.t]) :: boolean
  defp all_set(_, _, _, []), do: true
  defp all_set(mask, i1, i, [h | t]) do
    case Bloomex.BitArray.get(h, i) do
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
                b = plain(:bits, mb + g, err * r, hash_func) |> add e
                %{bloom | size: size + 1, b: [b | bs]}
          end
    end
  end

  @spec hash_add(pos_integer, Bloom.t) :: Bloom.t
  defp hash_add(hashes, %Bloom{mb: mb, bv: bv, size: size} = b) do
    mask = (1 <<< mb) - 1
    {i1, i0} = make_indexes(mask, hashes)

    case all_set(mask, i1, i0, bv) do
      true  -> b
      false -> %{b | size: size + 1, bv: set_bits(mask, i1, i0, bv, [])}
    end
  end

  @spec set_bits(pos_integer, pos_integer, pos_integer, [Bloomex.BitArray.t], [Bloomex.BitArray.t]) :: [Bloomex.BitArray.t]
  defp set_bits(_, _, _, [], acc), do: Enum.reverse acc
  defp set_bits(mask, i1, i, [h | t], acc) do
    set_bits(mask, i1, (i + i1) &&& mask, t, [Bloomex.BitArray.set(h, i) | acc])
  end

  @spec log2(float) :: float
  defp log2(x) do
    :math.log(x) / :math.log(2)
  end
end
