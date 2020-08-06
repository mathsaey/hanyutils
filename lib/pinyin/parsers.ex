defmodule Pinyin.Parsers do
  @moduledoc false
  # Parsing logic for parsing pinyin strings

  import NimbleParsec

  # ----------- #
  # Conversions #
  # ----------- #

  defp char_to_integer(c), do: [c] |> to_string() |> String.to_integer()

  defp numbered_to_pinyin([initial, final, tone]) do
    Pinyin.create(initial <> final, tone)
  end

  defp numbered_to_pinyin([final, tone]) when is_integer(tone) do
    Pinyin.create(final, tone)
  end

  defp numbered_to_pinyin([initial, final]) when is_binary(final) do
    Pinyin.create(initial <> final)
  end

  defp numbered_to_pinyin([final]) when is_binary(final) do
    Pinyin.create(final)
  end

  defp marked_to_pinyin([initial, final]) do
    Pinyin.from_marked(initial <> final)
  end

  defp marked_to_pinyin([final]) do
    Pinyin.from_marked(final)
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

    def not_split_until(p) do
      times(utf8_char(lookahead_not(p), @not_split_chars), min: 1)
      |> reduce({Kernel, :to_string, []})
    end

    def mark_all(list) do
      Enum.reduce(1..4, [], fn tone, res ->
        list
        |> Enum.reject(&(&1 in ["v", "ve", "vn", "van"]))
        |> Enum.map(&Pinyin.marked(%Pinyin{word: &1, tone: tone}))
        |> Enum.concat(res)
      end)
    end

    def wordlist_to_parser(list) do
      list |> Enum.map(&string/1) |> choice()
    end

    def wordlist_to_mixed_case_parser(list) do
      (list ++ Enum.map(list, &String.capitalize/1)) |> wordlist_to_parser()
    end

    def wordlist_to_upcase_parser(list) do
      list |> Enum.map(&String.upcase/1) |> wordlist_to_parser()
    end

    def tone_parser do
      ascii_char([?0..?4]) |> map({:char_to_integer, []})
    end

    def base_py_parser(initials, combination_finals, standalone_finals) do
      choice([
        concat(initials, combination_finals),
        standalone_finals
      ])
    end

    def num_py_parser(initials, combination_finals, standalone_finals) do
      concat(
        base_py_parser(initials, combination_finals, standalone_finals),
        optional(tone_parser())
      )
      |> reduce({:numbered_to_pinyin, []})
    end

    def mark_py_parser(initials, combination_finals, standalone_finals) do
      base_py_parser(initials, combination_finals, standalone_finals)
      |> reduce({:marked_to_pinyin, []})
    end

    def word_parser(parser) do
      parser |> times(min: 1) |> lookahead_not(not_split())
    end

    def repeat_choice_parser(choice) do
      choice |> choice() |> repeat() |> eos()
    end
  end

  # ------ #
  # Pinyin #
  # ------ #

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
  #
  # In both cases, the table needs to be sorted by length to ensure short elements don't prevent
  # longer ones from matching. (e.g "iang" needs to be tested before "ia").

  # Finals which need to be combined with an initial
  combination_finals = ~w(
    i  e  a ei  ai ou  ao en  an  ong eng  ang
      ie ia        iu iao in ian iong ing iang
    u uo ua ui uai        un uan          uang
    ü üe                  ün üan
    v ve                  vn van
  ) |> Enum.sort(&(String.length(&1) >= String.length(&2)))

  # Finals which are used standalone
  standalone_finals = ~w(
         e  a  ei  ai  ou  ao  en   an       eng  ang
    yi  ye ya         you yao yin  yan yong ying yang
    wu  wo wa wei wai         wen  wan      weng wang
    yu yue                    yun yuan
    er
  ) |> Enum.sort(&(String.length(&1) >= String.length(&2)))

  marked_combination_finals = Utils.mark_all(combination_finals)
  marked_standalone_finals = Utils.mark_all(standalone_finals)

  # Parsers
  # -------

  initials_upper = Utils.wordlist_to_mixed_case_parser(initials)
  initials = Utils.wordlist_to_mixed_case_parser(initials)

  combination_finals_upper = Utils.wordlist_to_upcase_parser(combination_finals)
  combination_finals = Utils.wordlist_to_parser(combination_finals)

  standalone_finals_upper = Utils.wordlist_to_upcase_parser(standalone_finals)
  standalone_finals = Utils.wordlist_to_mixed_case_parser(standalone_finals)

  marked_combination_finals_upper = Utils.wordlist_to_upcase_parser(marked_combination_finals)

  marked_combination_finals = Utils.wordlist_to_parser(marked_combination_finals)

  marked_standalone_finals_upper = Utils.wordlist_to_upcase_parser(marked_standalone_finals)

  marked_standalone_finals = Utils.wordlist_to_mixed_case_parser(marked_standalone_finals)

  numbered_pinyin_syllable =
    Utils.num_py_parser(
      initials,
      combination_finals,
      standalone_finals
    )

  numbered_pinyin_syllable_upper =
    Utils.num_py_parser(
      initials_upper,
      combination_finals_upper,
      standalone_finals_upper
    )

  marked_pinyin_syllable =
    Utils.mark_py_parser(
      initials,
      marked_combination_finals,
      marked_standalone_finals
    )

  marked_pinyin_syllable_upper =
    Utils.mark_py_parser(
      initials_upper,
      marked_combination_finals_upper,
      marked_standalone_finals_upper
    )

  numbered_pinyin_syllable = choice([numbered_pinyin_syllable, numbered_pinyin_syllable_upper])

  marked_pinyin_syllable = choice([marked_pinyin_syllable, marked_pinyin_syllable_upper])

  # Order matters here, marked must go first, or numbered may consume a shorter valid pinyin word
  pinyin_syllable = choice([marked_pinyin_syllable, numbered_pinyin_syllable])
  pinyin_word = pinyin_syllable |> Utils.word_parser()

  defparsec(
    :pinyin_only,
    Utils.repeat_choice_parser([pinyin_word, Utils.split()]),
    inline: true
  )

  defparsec(
    :pinyin_words,
    Utils.repeat_choice_parser([
      pinyin_word,
      Utils.split(),
      Utils.not_split()
    ]),
    inline: true
  )

  defparsec(
    :mixed_words,
    Utils.repeat_choice_parser([
      pinyin_syllable,
      Utils.split(),
      Utils.not_split_until(numbered_pinyin_syllable)
    ]),
    inline: true
  )
end
