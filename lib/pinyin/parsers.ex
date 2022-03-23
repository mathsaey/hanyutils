defmodule Pinyin.Parsers do
  @moduledoc false
  # Parsing logic for pinyin strings

  import NimbleParsec

  # ------ #
  # Pinyin #
  # ------ #

  # The following constants define the various initials and finals that can be used to make up
  # pinyin words. They are used to generate the parsers in this module.

  # Initials
  # Based on https://en.wikipedia.org/wiki/Pinyin#Initials
  initials = ~w(
    b  p  m  f
    d  t  n  l
    g  k  h
    j  q  x
    zh ch sh r
    z  c  s
  )

  # Finals
  # Please be careful when reformatting these entries.
  # Based on https://en.wikipedia.org/wiki/Pinyin#Finals
  #
  # Finals are split into finals which are combined with an initial and finals which can be used
  # standalone. This is done to avoid parsing something like "i" as a valid pinyin word.

  # Finals which need to be combined with an initial
  #
  # uo becomes o after b, p, m and f, so we add o.
  # ü is sometimes written as v, and is written as u after, y, j, q and x, so we add v and u
  # versions for each of its entries.
  #
  combination_finals = ~w(
    i  e  a ei  ai ou  ao    en  an      ong eng  ang
    i ie ia        iu iao in    ian ing iong     iang
    u uo ua ui uai           un uan              uang
       o
    ü üe                  ün    üan
    v ve                  vn    van
    u ue                  un    uan
  )

  # Finals which are used standalone
  #
  # The last row contains elements which do not appear in wikipedia's final table, but which do
  # occur in the Unihan_Readings database with different tones.
  standalone_finals = ~w(
         e  a  ei  ai  ou  ao     en   an            eng  ang
    yi  ye ya         you yao yin     yan ying yong      yang
    wu  wo wa wei wai             wen wan           weng wang
    yu yue                    yun yuan
    er
    ê o yo n ng wong m
  )

  # Standalone finals which are not tone marked.
  #
  # These finals occur in the Unihan_Readings database, but are never marked with tones.
  unmarked_finals = ~w(hng hm)

  # ----------------------- #
  # Parse results -> Pinyin #
  # ----------------------- #

  defp char_to_integer(c), do: c - ?0

  defp create(initial, final, tone) do
    final = String.replace(final, "ü", "v")
    %Pinyin{initial: initial, final: final, tone: tone}
  end

  defp numbered_to_pinyin([initial, final, tone]), do: create(initial, final, tone)
  defp numbered_to_pinyin([initial, final]) when is_binary(final), do: create(initial, final, 0)
  defp numbered_to_pinyin([final, tone]) when is_integer(tone), do: create("", final, tone)
  defp numbered_to_pinyin([final]) when is_binary(final), do: create("", final, 0)

  defp marked_to_pinyin([initial, final]) do
    {final, tone} = extract_tone(final)
    create(initial, final, tone)
  end

  defp marked_to_pinyin([final]) do
    {final, tone} = extract_tone(final)
    create("", final, tone)
  end

  defp extract_tone(binary) do
    binary = String.normalize(binary, :nfd)
    # Start from offset one, since the first character cannot be a tone marker
    {unmarked, tone} = do_extract_tone(binary, 1)
    {String.normalize(unmarked, :nfc), tone}
  end

  defp do_extract_tone(binary, offset) when offset > byte_size(binary), do: {binary, 0}

  defp do_extract_tone(binary, offset) do
    case binary do
      <<pre::binary-size(offset), 0x0304::utf8, rem::binary>> -> {pre <> rem, 1}
      <<pre::binary-size(offset), 0x0301::utf8, rem::binary>> -> {pre <> rem, 2}
      <<pre::binary-size(offset), 0x030C::utf8, rem::binary>> -> {pre <> rem, 3}
      <<pre::binary-size(offset), 0x0300::utf8, rem::binary>> -> {pre <> rem, 4}
      _ -> do_extract_tone(binary, offset + 1)
    end
  end

  # --------- #
  # Utilities #
  # --------- #

  defmodule Utils do
    @moduledoc false
    # Reusable parts of the pinyin parsers.
    import NimbleParsec

    @split_chars [?\s, ?\t, ?\n, ?,, ?., ?;, ??, ?!]
    @not_split_chars Enum.map(@split_chars, &{:not, &1})

    def split do
      @split_chars
      |> utf8_char()
      |> times(min: 1)
      |> reduce({Kernel, :to_string, []})
    end

    def not_split do
      @not_split_chars
      |> utf8_char()
      |> times(min: 1)
      |> reduce({Kernel, :to_string, []})
    end

    def not_split_until(parser) do
      times(lookahead_not(parser) |> utf8_char(@not_split_chars), min: 1)
      |> reduce({Kernel, :to_string, []})
    end

    def word(parser), do: parser |> times(min: 1) |> lookahead_not(not_split())

    def only(parser), do: choice([word(parser), split()]) |> repeat() |> eos()
    def words(parser), do: choice([word(parser), word(not_split()), split()]) |> repeat() |> eos()

    def mixed(parser) do
      choice([times(parser, min: 1), not_split_until(parser), split()]) |> repeat() |> eos()
    end
  end

  defmodule Wordlist do
    @moduledoc false
    # Helper module to handle lists of strings.
    import NimbleParsec

    # - We remove duplicated values, this enables us to duplicate values in the pinyin tables when
    #   this helps readability.
    # - We sort items from longest to shortest to ensure longer entries are matched first.
    def to_parser(list) do
      list
      |> Enum.uniq()
      |> Enum.sort(&(String.length(&1) >= String.length(&2)))
      |> Enum.map(&string/1)
      |> choice()
    end

    def concat_parser(l, r), do: concat(to_parser(l), to_parser(r))
    def merged_parser(list), do: list |> Enum.concat() |> to_parser()

    defp merge_transform(list, transform) do
      transformed = transform.(list)
      list ++ transformed
    end

    def capitalize(list), do: list |> Enum.map(&String.capitalize/1)
    def allcaps(list), do: list |> Enum.map(&String.upcase/1)

    def mixed_caps(list), do: merge_transform(list, &capitalize/1)

    def mark(list) do
      for t <- 1..4, f <- list, do: Pinyin.marked(%Pinyin{initial: "", final: f, tone: t})
    end
  end

  # ------- #
  # Parsers #
  # ------- #

  # Allcaps:
  initials_upper = Wordlist.allcaps(initials)
  combination_finals_upper = Wordlist.allcaps(combination_finals)
  standalone_finals_upper = Wordlist.allcaps(standalone_finals)
  unmarked_finals_upper = Wordlist.allcaps(unmarked_finals)

  # Lowercase + capitalised:
  initials_mixed = Wordlist.mixed_caps(initials)
  standalone_finals_mixed = Wordlist.mixed_caps(standalone_finals)
  unmarked_finals_mixed = Wordlist.mixed_caps(unmarked_finals)

  # Marked versions of the pinyin tables:
  combination_finals_marked = Wordlist.mark(combination_finals)
  combination_finals_marked_upper = Wordlist.mark(combination_finals_upper)
  standalone_finals_marked_mixed = Wordlist.mark(standalone_finals_mixed)
  standalone_finals_marked_upper = Wordlist.mark(standalone_finals_upper)

  # Syllable Parsers
  # ----------------

  unmarked =
    choice([
      Wordlist.concat_parser(initials_mixed, combination_finals),
      Wordlist.concat_parser(initials_upper, combination_finals_upper),
      Wordlist.merged_parser([
        standalone_finals_mixed,
        standalone_finals_upper,
        unmarked_finals_mixed,
        unmarked_finals_upper
      ])
    ])

  marked =
    choice([
      Wordlist.concat_parser(initials_mixed, combination_finals_marked),
      Wordlist.concat_parser(initials_upper, combination_finals_marked_upper),
      Wordlist.merged_parser([
        standalone_finals_marked_mixed,
        standalone_finals_marked_upper,
        unmarked_finals_mixed,
        unmarked_finals_upper
      ])
    ])

  # Parsers
  # -------

  tone_mark = ascii_char([?0..?4]) |> map({:char_to_integer, []})
  numbered_parser = concat(unmarked, optional(tone_mark)) |> reduce({:numbered_to_pinyin, []})

  marked = marked |> reduce({:marked_to_pinyin, []})
  unmarked = unmarked |> reduce({:numbered_to_pinyin, []})

  marked_parser = choice([marked, unmarked])
  syllable_parser = choice([marked, numbered_parser])

  # Single syllable
  defparsec(:numbered_syllable, numbered_parser |> eos(), inline: true)
  defparsec(:marked_syllable, marked_parser |> eos(), inline: true)
  defparsec(:syllable, syllable_parser |> eos(), inline: true)

  # Pinyin only
  defparsec(:numbered_only, Utils.only(numbered_parser), inline: true)
  defparsec(:marked_only, Utils.only(marked_parser), inline: true)
  defparsec(:pinyin_only, Utils.only(syllable_parser), inline: true)

  # Pinyin words mixed with regular words
  defparsec(:numbered_words, Utils.words(numbered_parser), inline: true)
  defparsec(:marked_words, Utils.words(marked_parser), inline: true)
  defparsec(:pinyin_words, Utils.words(syllable_parser), inline: true)

  # Mixed pinyin and regular words
  defparsec(:numbered_mix, Utils.mixed(numbered_parser), inline: true)
  defparsec(:marked_mix, Utils.mixed(marked_parser), inline: true)
  defparsec(:pinyin_mix, Utils.mixed(syllable_parser), inline: true)
end
