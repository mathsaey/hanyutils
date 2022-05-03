defmodule Zhuyin.Parsers do
  @moduledoc false
  # Parsing logic for Zhuyin strings

  import NimbleParsec
  alias Pinyin.Parsers.Utils
  alias Pinyin.Parsers.Wordlist

  # ----------------- #
  # Utility Functions #
  # ----------------- #

  # Function to get the tone number of a standalone tone marker.
  # All valid function invocations are generated at compile time.
  @spec tone_index(String.t()) :: 0..4
  defp tone_index(tone_char)

  for {marker, idx} <- Enum.with_index(Zhuyin._zhuyin_tones(), 0) do
    defp tone_index(unquote(marker)), do: unquote(idx)
  end

  defp create(initial, final, tone) do
    %Zhuyin{initial: initial, final: final, tone: tone_index(tone)}
  end

  defp create(final, tone) do
    %Zhuyin{final: final, tone: tone_index(tone)}
  end

  # ------- #
  # Parsers #
  # ------- #

  # Empty tone must be last for parsing to work
  zhuyin_tones = ["˙", "ˊ", "ˇ", "ˋ", ""]

  initials = ~w(
    ㄅ ㄆ ㄇ ㄈ
    ㄉ ㄊ ㄋ ㄌ
    ㄍ ㄎ ㄏ
    ㄐ ㄑ ㄒ
  )

  standalone_initials = ~w(
    ㄓ ㄔ ㄕ ㄖ
    ㄗ ㄘ ㄙ
  )

  two_finals = ~w(
    ㄧㄚ
    ㄨㄚ
    ㄧㄥ
    ㄧㄤ
    ㄧㄝ
    ㄨㄛ
    ㄨㄥ
    ㄨㄤ
    ㄧㄠ
    ㄨㄞ
    ㄩㄝ
    ㄩㄥ
    ㄧㄡ
    ㄨㄟ
    ㄩㄝ
    ㄧㄢ
    ㄨㄢ
    ㄩㄢ
    ㄧㄣ
    ㄨㄣ
    ㄩㄣ
  )
  single_finals = ~w(
    ㄧ ㄨ ㄩ
    ㄚ ㄛ ㄜ ㄦ
    ㄞ ㄟ ㄠ ㄡ
    ㄢ ㄣ ㄤ ㄥ
  )

  initials_parser =
    choice([
      initials |> Wordlist.to_parser(),
      # Standalone initials can never be combined with the ㄧ final
      standalone_initials |> Wordlist.to_parser() |> lookahead_not(string("ㄧ"))
    ])

  standalone_initials_parser = standalone_initials |> Wordlist.to_parser()

  finals_parser =
    choice([
      two_finals |> Wordlist.to_parser(),
      single_finals |> Wordlist.to_parser()
    ])

  tone_parser = zhuyin_tones |> Wordlist.to_parser()

  defp to_zhuyin([initial, final, tone]), do: create(initial, final, tone)
  defp to_zhuyin([final, tone]), do: create(final, tone)

  syllable_parser =
    choice([
      finals_parser,
      concat(initials_parser, finals_parser),
      standalone_initials_parser
    ])
    |> concat(tone_parser)
    |> reduce({:to_zhuyin, []})

  # Single syllable
  defparsec(:syllable, syllable_parser |> eos(), inline: true)

  # Zhuyin only
  defparsec(:zhuyin_only, Utils.only(syllable_parser), inline: true)

  # Zhuyin words mixed with regular words
  defparsec(:zhuyin_words, Utils.words(syllable_parser), inline: true)

  # Mixed zhuyin and regular words
  defparsec(:zhuyin_mix, Utils.mixed(syllable_parser), inline: true)
end
