defmodule Hanzi do
  @moduledoc """
  Pinyin conversions and character utilities.
  """

  @doc """
  Convert a character to its pinyin representation.

  This function can only deal with a single character at a time. Use
  `to_pinyin/2` for a function that can deal with complete strings.

  If a non-recognized character is provided it is returned unmodified.

  ## Examples

  The intended use of this function.

      iex> Hanzi.char_to_pinyin("你")
      "nǐ"

  Calling `char_to_pinyin/1` with a non-recognized character. The second
  example shows what happens when multiple Chinese characters are provided at
  once.

      iex> Hanzi.char_to_pinyin("✓")
      "✓"
      iex> Hanzi.char_to_pinyin("你好")
      "你好"
  """
  @spec char_to_pinyin(String.t()) :: String.t()
  def char_to_pinyin(char)

  @doc """
  Check if a string is a single character.

  Checks if a string consists of a single character. Use `only_characters?/1`
  to check if an entire string consists of only characters.

  ## Examples

      iex> Hanzi.is_character?("你")
      true
      iex> Hanzi.is_character?("✓")
      false
      iex> Hanzi.is_character?("你好")
      false
  """
  @spec is_character?(String.t()) :: boolean()
  def is_character?(char)

  # Use the char_to_pinyin file to autogenerate the `char_to_pinyin/1` and
  # `is_character?/1` functions.
  __DIR__
  |> Path.join("hanzi/pinyin.map")
  |> File.stream!()
  |> Stream.reject(&String.starts_with?(&1, ["#", "\n"]))
  |> Stream.map(fn line ->
    [code, pinyin] = String.split(line)
    codepoint = String.to_integer(code, 16)
    char = <<codepoint :: utf8>>

    def char_to_pinyin(unquote(char)), do: unquote(pinyin)
    def is_character?(unquote(char)), do: true

  end)
  |> Stream.run()

  # Fallback implementations
  def char_to_pinyin(any), do: any
  def is_character?(_), do: false


  @doc """
  Convert each string in a list with `char_to_pinyin/1`

  ## Examples

      iex> Hanzi.to_pinyin(["你", "好"])
      ["nǐ", "hǎo"]

  """
  @spec to_pinyin([String.t()]) :: [String.t()]
  def to_pinyin(word) when is_list(word), do: Enum.map(word, &char_to_pinyin/1)

  @doc """
  Convert a character string into pinyin.

  Converts each Chinese character in a string to pinyin; other charachters are
  returned unmodified. `sep` can be used to add additional spacing between the
  generated pinyin. By default, sep is empty to avoid messing up the formatting
  of regular string elements. Avoid using `sep` unless you are sure `word` only
  contains characters.

  ## Examples

      iex> Hanzi.to_pinyin("你好")
      "nǐhǎo"
      iex> Hanzi.to_pinyin("你好", " ")
      "nǐ hǎo"
      iex> Hanzi.to_pinyin("你好, how is everybody?")
      "nǐhǎo, how is everybody?"
      iex> Hanzi.to_pinyin("你好, how is everybody?", " ")
      "nǐ hǎo ,   h o w   i s   e v e r y b o d y ?"
  """
  @spec to_pinyin(String.t(), String.t()) :: String.t()
  def to_pinyin(word, sep \\ "") when is_binary(word) do
    word
    |> String.graphemes()
    |> to_pinyin()
    |> Enum.join(sep)
  end

  @doc """
  Verify if a list or string contains only characters.

  Notice that whitespaces are not counted as characters.

  ## Examples

  iex> Hanzi.only_characters?(["你", "好"])
  true
  iex> Hanzi.only_characters?(["你", "boo", "好"])
  false
  iex> Hanzi.only_characters?("你好")
  true
  iex> Hanzi.only_characters?("你 好")
  false
  """
  @spec only_characters?(String.t() | [String.t]) :: boolean()
  def only_characters?(l) when is_list(l), do: Enum.all?(l, &is_character?/1)

  def only_characters?(str) when is_binary(str) do
    str
    |> String.graphemes()
    |> only_characters?()
  end
end
