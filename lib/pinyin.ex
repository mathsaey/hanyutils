defmodule Pinyin do
  @moduledoc """
  Utilities to deal with pinyin.
  """

  tone_map = %{
    "a" => ~w(ā á ǎ à),
    "e" => ~w(ē é ě è),
    "i" => ~w(ī í ǐ ì),
    "o" => ~w(ō ó ǒ ò),
    "u" => ~w(ū ú ǔ ù),
    "ü" => ~w(ǖ ǘ ǚ ǜ),
    "v" => ~w(ǖ ǘ ǚ ǜ)
  }

  # Use the tone_map to create the `add_tone` function.
  for {original, mapped_chars} <- tone_map do
    mapped_chars
    |> Enum.with_index(1)
    |> Enum.map(fn {mapped, idx} ->
      defp char_with_tone(unquote(original), unquote(idx)), do: unquote(mapped)
    end)
  end

  @doc """
  Replace easy-to-type pinyin with easy-to-read pinyin

  This function performs the following transformations to make pinyin easy to
  read:

  - Each pinyin syllable followed by a tone number is converted into a marked
  syllable. This is done based on the rules defined by `add_tone/2`.
  - Each "v" is transformed into a "ü".

  Note that this function expects to receive valid pinyin as input. If
  non-pinyin text is passed it may lead to errors or unpredictable results.

  ## Examples

      iex> Pinyin.prettify("ni3hao3")
      "nǐhǎo"
      iex> Pinyin.prettify("lve4")
      "lüè"
      iex> Pinyin.prettify("ni5")
      ** (FunctionClauseError) no function clause matching in Pinyin.add_tone/2

  """
  @spec prettify(String.t()) :: String.t()
  def prettify(string) do
    string
    |> String.replace("v", "ü")
    |> String.replace(~r/([^\d\s]+)(\d)/, &split_and_add_tone/1)
  end

  defp split_and_add_tone(word) do
    {word, digit} = String.split_at(word, -1)
    add_tone(word, String.to_integer(digit))
  end

  @doc """
  Add a tone to a pinyin word

  Adds a given tone to a word of pinyin. It respects the precedence rules for
  tone placement.

  ## Dealing with v/ü

  It is fairly common to use "v" to represent ü. If this procedure needs to
  place a tone mark on a "v", it will automatically convert it into a "ü" prior
  to the placement of the tone mark.

  ## Examples

      iex> Pinyin.add_tone("hao", 3)
      "hǎo"
      iex> Pinyin.add_tone("lei", 2)
      "léi"
      iex> Pinyin.add_tone("huai", 4)
      "huài"
      iex> Pinyin.add_tone("tui", 2)
      "tuí"
      iex> Pinyin.add_tone("xiu", 4)
      "xiù"
  """
  @spec add_tone(String.t(), 1..4) :: String.t()
  def add_tone(word, tone) when tone in 0..4 do
    vowel = word |> String.codepoints() |> Enum.reduce(nil, &select_max/2)
    String.replace(word, vowel, char_with_tone(vowel, tone))
  end

  # Pinyin precedence rules
  # -----------------------

  defp select_max(new, prev)

  # a always wins
  defp select_max("a", _), do: "a"
  defp select_max(_, "a"), do: "a"

  # e never occurs with a and always wins
  defp select_max("e", _), do: "e"
  defp select_max(_, "e"), do: "e"

  # o always wins if there is no a present
  defp select_max("o", "a"), do: "a"
  defp select_max("o", _),   do: "o"
  defp select_max(_, "o"),   do: "o"

  # in the case of ui, the second letter takes the mark
  # Keep in mind the "left" argument is the new letter, this is done to make
  # it easy to pass the function to reduce.
  defp select_max("i", "u"), do: "i"
  defp select_max("u", "i"), do: "u"

  # If none of the above match whichever vowel is present takes the mark
  defp select_max(v, _) when v in ["a", "e", "i", "o", "u", "ü", "v"], do: v
  # If there is no vowel, stay with previous selection
  defp select_max(_, p), do: p

end
