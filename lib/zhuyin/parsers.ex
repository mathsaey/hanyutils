defmodule Zhuyin.Parsers do
  @moduledoc false
  # Parsing logic for Zhuyin strings

  import NimbleParsec
  alias Pinyin.Parsers.Utils
  alias Pinyin.Parsers.Wordlist

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

  defp to_zhuyin([initial, final, tone]), do: Zhuyin.create(initial, final, tone)
  defp to_zhuyin([final, tone]), do: Zhuyin.create(final, tone)

  syllable_parser =
    choice([
      finals_parser,
      concat(initials_parser, finals_parser),
      standalone_initials_parser
    ])
    |> concat(optional(tone_parser))
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
