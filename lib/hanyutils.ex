defmodule Hanyutils do
  @moduledoc """
  Utilities for dealing with Chinese characters (Hanzi) and Pinyin.

  This module contains several functions which deal with strings containing Han characters or
  Pinyin. Specifically, the following functionality is present:

      iex> Hanyutils.to_marked_pinyin("你好")
      "nǐhǎo"

      iex> Hanyutils.to_numbered_pinyin("你好")
      "ni3hao3"

      iex> Hanyutils.to_zhuyin("你好")
      "ㄋㄧˇㄏㄠˇ"

      iex> Hanyutils.characters?("你好")
      true

      iex> Hanyutils.mark_pinyin("ni3hao3")
      "nǐhǎo"

      iex> Hanyutils.number_pinyin("nǐhǎo")
      "ni3hao3"

      iex> Hanyutils.zhuyin_to_numbered_pinyin("ㄋㄧˇㄏㄠˇ")
      "ni3hao3"

      iex> Hanyutils.zhuyin_to_marked_pinyin("ㄋㄧˇㄏㄠˇ")
      "nǐhǎo"

      iex> Hanyutils.pinyin_to_zhuyin("ni3hǎo")
      "ㄋㄧˇㄏㄠˇ"

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

  Please refer to the documentation of the `Hanzi`, `Pinyin`, and `Zhuyin` modules for more
  information.
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
  Convert a string containing Han characters to Zhuyin.

  For more information about `converter`, please refer to `Hanzi.to_pinyin/2`.
  Because the Unihan database provides only definitions of pinyin
  pronounciation we're converting first to pinyin and that to zhuyin.

  ## Examples

      iex> Hanyutils.to_zhuyin("你好")
      "ㄋㄧˇㄏㄠˇ"

      iex> Hanyutils.to_zhuyin("朱宇辰")
      "ㄓㄨㄩˇㄔㄣˊ"

      iex> Hanyutils.to_zhuyin("你好", &Hanzi.all_pronunciations/1)
      "ㄋㄧˇ[ ㄏㄠˇ | ㄏㄠˋ ]"

  """
  @spec to_zhuyin(String.t(), (Hanzi.t() -> Pinyin.pinyin_list())) :: String.t()
  def to_zhuyin(string, converter \\ &Hanzi.common_pronunciation/1) do
    string
    |> Hanzi.read()
    |> Hanzi.to_pinyin(converter)
    |> Zhuyin.from_pinyin()
    |> Enum.join()
    |> to_string()
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
  @spec mark_pinyin(String.t(), :exclusive | :words | :mixed) :: String.t()
  def mark_pinyin(string, mode \\ :words) when mode in [:exclusive, :words, :mixed] do
    string
    |> Pinyin.read!(mode)
    |> Pinyin.marked()
  end

  @doc """
  Convert a string with marked Pinyin to numbered Pinyin.

  Parses the input using `Pinyin.read!/1` (in `:words` mode), and converts the result with
  `Pinyin.numbered/1`. Please refer to the documentation of `Pinyin.read/2` if you require
  details on how the input is parsed. It is worth noting that the `Pinyin.read/2` parser is
  sensitive to the location of the tone marker.

  ## Examples

      iex> Hanyutils.number_pinyin("ni3hǎo")
      "ni3hao3"

  """
  @spec number_pinyin(String.t(), :exclusive | :words | :mixed) :: String.t()
  def number_pinyin(string, mode \\ :words) when mode in [:exclusive, :words, :mixed] do
    string
    |> Pinyin.read!(mode)
    |> Pinyin.numbered()
  end

  @doc """
  Convert a string with Pinyin to Zhuyin

  Parses the input using `Pinyin.read!/1` (in `:words` mode), and converts the result with
  `Zhuyin.from_pinyin/1`. Please refer to the documentation of `Pinyin.read/2` if you require
  details on how the input is parsed. It is worth noting that the `Pinyin.read/2` parser is
  sensitive to the location of the tone marker.

  ## Examples

      iex> Hanyutils.pinyin_to_zhuyin("ni3hǎo")
      "ㄋㄧˇㄏㄠˇ"

      iex> Hanyutils.pinyin_to_zhuyin("zhu1yu3chen2")
      "ㄓㄨㄩˇㄔㄣˊ"

  """
  @spec pinyin_to_zhuyin(String.t(), :exclusive | :words | :mixed) :: String.t()
  def pinyin_to_zhuyin(string, mode \\ :words) when mode in [:exclusive, :words, :mixed] do
    string
    |> Pinyin.read!(mode)
    |> Zhuyin.from_pinyin()
    |> Enum.join()
    |> to_string()
  end

  @doc """
  Convert a string with Zhuyin to marked Pinyin.

  Parses the input using `Zhuyin.read!/1` (in `:words` mode), and converts the result with
  `Pinyin.numbered/1`. Please refer to the documentation of `Zhuyin.read/2` if you required
  details on how the input is parsed.

  ## Examples

      iex> Hanyutils.zhuyin_to_marked_pinyin("ㄋㄧˇㄏㄠˇ")
      "nǐhǎo"

      iex> Hanyutils.zhuyin_to_marked_pinyin("ㄓㄨㄩˇㄔㄣˊ")
      "zhūyǔchén"

  """
  @spec zhuyin_to_marked_pinyin(String.t(), :exclusive | :words | :mixed) :: String.t()
  def zhuyin_to_marked_pinyin(string, mode \\ :words) when mode in [:exclusive, :words, :mixed] do
    string
    |> Zhuyin.read!(mode)
    |> Zhuyin.to_pinyin()
    |> Pinyin.marked()
  end

  @doc """
  Convert a string with Zhuyin to numbered Pinyin.

  Parses the input using `Zhuyin.read!/1` (in `:words` mode), and converts the result with
  `Pinyin.numbered/1`. Please refer to the documentation of `Zhuyin.read/2` if you required
  details on how the input is parsed.

  ## Examples

      iex> Hanyutils.zhuyin_to_numbered_pinyin("ㄋㄧˇㄏㄠˇ")
      "ni3hao3"

      iex> Hanyutils.zhuyin_to_numbered_pinyin("ㄓㄨㄩˇㄔㄣˊ")
      "zhu1yu3chen2"

  """
  @spec zhuyin_to_numbered_pinyin(String.t(), :exclusive | :words | :mixed) :: String.t()
  def zhuyin_to_numbered_pinyin(string, mode \\ :words)
      when mode in [:exclusive, :words, :mixed] do
    string
    |> Zhuyin.read!(mode)
    |> Zhuyin.to_pinyin()
    |> Pinyin.numbered()
  end
end
