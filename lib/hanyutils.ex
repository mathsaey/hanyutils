defmodule Hanyutils do
  @moduledoc """
  Utilities for dealing with Chinese characters (Hanzi) and Pinyin.

  This module contains several functions which deal with strings containing Han characters or
  Pinyin. Specifically, the following functionality is present:

      iex> Hanyutils.to_marked_pinyin("你好")
      "nǐhǎo"

      iex> Hanyutils.to_numbered_pinyin("你好")
      "ni3hao3"

      iex> Hanyutils.characters?("你好")
      true

      iex> Hanyutils.mark_pinyin("ni3hao3")
      "nǐhǎo"

      iex> Hanyutils.number_pinyin("nǐhǎo")
      "ni3hao3"

  All of these functions are built based on the functionality found in the `Hanzi` and
  `Pinyin` modules. If this module does not contain the required functionality you need, it is
  possible it can be built manually based on the abstractions in these modules. For instance, the
  `to_marked_pinyin` function could be implemented as follows:

      def to_marked_pinyin(string) do
        string
        |> Hanzi.read()
        |> Hanzi.to_pinyin()
        |> Pinyin.marked()
      end

  Please refer to the documentation of the `Hanzi` and `Pinyin` modules for more information.
  """

  defdelegate characters?(c), to: Hanzi

  @doc """
  Convert a string containing Han characters to marked Pinyin.

  For more information about `converter`, please refer to `Hanzi.to_pinyin/2`.

  ## Examples

      iex> Hanyutils.to_marked_pinyin("你好")
      "nǐhǎo"

      iex> Hanyutils.to_marked_pinyin("你好", &Hanzi.all_pronunciations/1)
      "nǐ[ hǎo | hào ]"

  """
  @spec to_marked_pinyin(String.t(), (Hanzi.t() -> Pinyin.pinyin_list())) :: String.t()
  def to_marked_pinyin(string, converter \\ &Hanzi.common_pronunciation/1) do
    string
    |> Hanzi.read()
    |> Hanzi.to_pinyin(converter)
    |> Pinyin.marked()
  end

  @doc """
  Convert a string containing Han characters to numbered Pinyin.

  For more information about `converter`, please refer to `Hanzi.to_pinyin/2`.

  ## Examples

      iex> Hanyutils.to_numbered_pinyin("你好")
      "ni3hao3"

      iex> Hanyutils.to_numbered_pinyin("你好", &Hanzi.all_pronunciations/1)
      "ni3[ hao3 | hao4 ]"

  """
  def to_numbered_pinyin(string, converter \\ &Hanzi.common_pronunciation/1) do
    string
    |> Hanzi.read()
    |> Hanzi.to_pinyin(converter)
    |> Pinyin.numbered()
  end

  @doc """
  Convert a string with numbered Pinyin to marked Pinyin.

  Parses the input using `Pinyin.read!/1` (in `:words` mode), and converts the result with
  `Pinyin.marked/1`. Please refer to the documentation of `Pinyin.read/2` if you required details
  on how the input is parsed.

  ## Examples

      iex> Hanyutils.mark_pinyin("ni3hǎo")
      "nǐhǎo"

  """
  @spec mark_pinyin(String.t()) :: String.t()
  def mark_pinyin(string) do
    string
    |> Pinyin.read!(:words)
    |> Pinyin.marked()
  end

  @doc """
  Convert a string with marked Pinyin to numbered Pinyin.

  Parses the input using `Pinyin.read!/1` (in `:words` mode), and converts the result with
  `Pinyin.numbered/1`. Please refer to the documentation of `Pinyin.read/2` if you required
  details on how the input is parsed. It is worth noting that the `Pinyin.read/2` parser is
  sensitive to the location of the tone marker.

  ## Examples

      iex> Hanyutils.number_pinyin("ni3hǎo")
      "ni3hao3"

  """
  @spec number_pinyin(String.t()) :: String.t()
  def number_pinyin(string) do
    string
    |> Pinyin.read!(:words)
    |> Pinyin.numbered()
  end
end
