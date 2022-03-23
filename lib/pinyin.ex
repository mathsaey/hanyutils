defmodule Pinyin do
  @moduledoc """
  Utilities to deal with pinyin syllables and groups thereof.

  The main goal of this module is to provide functions to manipulate strings that contain pinyin
  words, which are potentially mixed with other content. These strings are represented by the
  `t:pinyin_list/0` type. Pinyin lists can be obtained by parsing a string with the `read/2`,
  `read!/2` or `sigil_p/2` functions, or by using `Hanzi.to_pinyin/2`. Afterwards, these lists can
  be converted into a _numbered_ or marked_ representation by using the `numbered/1` or
  `marked/1` function, respectively.

  A `t:pinyin_list/0` is a list which contains strings and pinyin structs (`t:t/0`). These structs
  are used to encode pinyin syllables; they can be created directly through the use of the
  `from_marked/1`, `from_marked!/1`, `from_numbered/1`, `from_numbered!/1`, `from_string/1` or
  `from_string!/1` functions. Like `t:pinyin_lists/0`, `t:t/0` structs can be converted to
  numbered or marked strings through the use of the `numbered/1` and `marked/1` functions.
  """
  alias Pinyin.Parsers

  # ----------------- #
  # Compile-time Work #
  # ----------------- #

  # Characters which can take a tone mark
  markeable_characters = ~w(a e i o u ü ê n m)
  markeable_characters = markeable_characters ++ Enum.map(markeable_characters, &String.upcase/1)

  # Unicode combining diacritics which represent the various tone markers
  tone_diacritic_combiners = [0x0304, 0x0301, 0x030C, 0x0300]

  # Function which can add a tone mark to a character. We generate all valid combinations at
  # compile time.
  @spec mark(String.t(), 0..4) :: String.t()
  defp mark(char, tone)

  for char <- markeable_characters, {tone, idx} <- Enum.with_index(tone_diacritic_combiners, 1) do
    # We normalise the string to ensure a compact representation
    marked = String.normalize(<<char::binary, tone::utf8>>, :nfc)

    defp mark(unquote(char), unquote(idx)), do: unquote(marked)
  end

  defp mark(c, _), do: c

  # ----- #
  # Types #
  # ----- #

  @typedoc """
  Representation of a single pinyin syllable.

  This type represents a single syllable in pinyin. Said otherwise, an instance of this type
  corresponds to a single Han character.

  Instances of this type should not be created manually, instead instances can be created from a
  numbered or marked string through the use of the `from_numbered/1`, `from_numbered!/1`,
  `from_marked/1`, `from_marked!/1` functions or by using the `sigil_p/2` sigil.
  """
  @type t :: %__MODULE__{tone: 0..4, initial: String.t(), final: String.t()}

  @enforce_keys [:final]
  defstruct tone: 0, initial: "", final: ""

  @typedoc """
  List of pinyin syllables mixed with plain strings.

  An instance of this type can be created from a string containing Han characters with the
  `Hanzi.to_pinyin/2` function. Alternatively, the `read/2` or `read!/2` functions can be used to
  obtain an instance of this type by parsing a string.

  The `marked/1` and `numbered/1` functions can be used to convert an instance of this type into a
  string.
  """
  @type pinyin_list :: [t() | String.t()]

  # -------- #
  # Creation #
  # -------- #

  defp parser_result({:ok, res, "", %{}, _, _}), do: {:ok, res}
  defp parser_result({:error, _, rem, %{}, _, _}), do: {:error, rem}

  defp parser_result!({:ok, res, "", %{}, _, _}), do: res
  defp parser_result!({:error, _, rem, %{}, _, _}), do: raise(ParseError, rem)

  @doc """
  Create a pinyin struct (`t:t/0`) from a string with tone marks.

  This function can only be used to parse a single pinyin syllable (e.g. "nǐ", not "nǐhǎo"). If
  parsing fails, an `{:error, <remainder of string>}` is returned, `<remainder of string>`
  contains the part of the string which made parsing fail.

  ## Examples

      iex> Pinyin.from_marked("nǐ")
      {:ok, %Pinyin{initial: "n", final: "i", tone: 3}}

      iex> Pinyin.from_marked("nǐhǎo")
      {:error, "hǎo"}

      iex> Pinyin.from_marked("hello")
      {:error, "llo"}
  """
  @spec from_marked(String.t()) :: {:ok, t()} | {:error, String.t()}
  def from_marked(word) do
    case word |> Parsers.marked_syllable() |> parser_result() do
      {:ok, [res]} -> {:ok, res}
      err -> err
    end
  end

  @doc """
  Create a pinyin struct (`t:t/0`) from a string with tone marks.

  Like `from_marked/1`, but returns the result or raises an exception if an error occurred while
  parsing.

  ## Examples

      iex> Pinyin.from_marked!("nǐ")
      #Pinyin<nǐ>

      iex> Pinyin.from_marked!("nǐhǎo")
      ** (ParseError) Error occurred when attempting to parse: "hǎo"

      iex> Pinyin.from_marked!("hello")
      ** (ParseError) Error occurred when attempting to parse: "llo"
  """
  @spec from_marked!(String.t()) :: t() | no_return()
  def from_marked!(word), do: word |> Parsers.marked_syllable() |> parser_result!() |> hd()

  @doc """
  Create a pinyin struct (`t:t/0`) from a string with a tone number.

  This function can only be used to parse a single pinyin syllable (e.g. "ni3", not "ni3hao3"),
  no whitespace may be present between the pinyin syllable and the tone marker. The tone marker
  should be a number between 1 and 4 and the last element of the string.

  If parsing fails, an `{:error, <remainder of string>}` is returned, `<remainder of string>`
  contains the part of the string which made parsing fail.

  ## Examples

      iex> Pinyin.from_numbered("ni3")
      {:ok, %Pinyin{initial: "n", final: "i", tone: 3}}

      iex> Pinyin.from_numbered("ni3hao3")
      {:error, "hao3"}

      iex> Pinyin.from_numbered("ha3o")
      {:error, "o"}

      iex> Pinyin.from_numbered("hello")
      {:error, "llo"}
  """
  @spec from_numbered(String.t()) :: {:ok, t()} | {:error, String.t()}
  def from_numbered(word) do
    case word |> Parsers.numbered_syllable() |> parser_result() do
      {:ok, [res]} -> {:ok, res}
      err -> err
    end
  end

  @doc """
  Create a pinyin struct (`t:t/0`) from a string with a tone number.

  Like `from_numbered/1`, but returns the result or raises an exception if an error occurred while
  parsing.

  ## Examples

      iex> Pinyin.from_numbered!("ni3")
      #Pinyin<nǐ>

      iex> Pinyin.from_numbered!("ni3hao3")
      ** (ParseError) Error occurred when attempting to parse: "hao3"

      iex> Pinyin.from_numbered!("ha3o")
      ** (ParseError) Error occurred when attempting to parse: "o"

      iex> Pinyin.from_numbered!("hello")
      ** (ParseError) Error occurred when attempting to parse: "llo"
  """
  @spec from_numbered!(String.t()) :: t() | no_return()
  def from_numbered!(word), do: word |> Parsers.numbered_syllable() |> parser_result!() |> hd()

  @doc """
  Create a pinyin struct (`t:t/0`) from a string.

  This function can be used to parse a single pinyin syllable which is marked or which has a tone
  number. It combines the functionality of `from_marked/1` and `from_numbered/1`.The limitations
  of these functions apply to this function.

  If parsing fails, an `{:error, <remainder of string>}` is returned, `<remainder of string>`
  contains the part of the string which made parsing fail.

  ## Examples

      iex> Pinyin.from_string("ni3")
      {:ok, %Pinyin{initial: "n", final: "i", tone: 3}}

      iex> Pinyin.from_string("nǐ")
      {:ok, %Pinyin{initial: "n", final: "i", tone: 3}}

      iex> Pinyin.from_string("ni3hao3")
      {:error, "hao3"}

      iex> Pinyin.from_string("nǐhǎo")
      {:error, "hǎo"}
  """
  @spec from_string(String.t()) :: {:ok, t()} | {:error, String.t()}
  def from_string(word) do
    case word |> Parsers.syllable() |> parser_result() do
      {:ok, [res]} -> {:ok, res}
      err -> err
    end
  end

  @doc """
  Create a pinyin struct (`t:t/0`) from a string.

  Like `from_string/1`, but returns the result or raises an exception if an error occurred while
  parsing.

  ## Examples

      iex> Pinyin.from_string!("ni3")
      #Pinyin<nǐ>

      iex> Pinyin.from_string!("nǐ")
      #Pinyin<nǐ>

      iex> Pinyin.from_string!("ni3hao3")
      ** (ParseError) Error occurred when attempting to parse: "hao3"

      iex> Pinyin.from_string!("nǐhǎo")
      ** (ParseError) Error occurred when attempting to parse: "hǎo"
  """
  @spec from_string!(String.t()) :: t() | no_return()
  def from_string!(word), do: word |> Parsers.syllable() |> parser_result!() |> hd()

  @doc """
  Read a string and convert it into a list of string and pinyin structs.

  This function reads a string containing pinyin mixed with normal text. The output of this
  function is a list of strings and pinyin structs. White space and punctuation will be separated
  from other strings.

  The input string may contain tone-marked (e.g. "nǐ") pinyin, numbered ("ni3") pinyin or a mix
  thereof (nǐ hao3). Note that in numbered pinyin mode tone numerals __must not__ be separated
  from their word. For instance, "ni3" will be correctly parsed as "nǐ", "ni 3" will not. When
  tone marked pinyin is used the tone must be marked on the correct letter. For instance, hǎo will
  parse correctly, haǒ will not; we recommend the use of numbered pinyin if there is uncertainty
  about the location of the tone mark.

  ## Parse Modes

  By default, this function only accepts strings which consists exclusively of pinyin, whitespace
  and punctuation. Parsing any text that cannot be interpreted as pinyin will result in an error:

      iex> Pinyin.read("Ni3hao3!")
      {:ok, [%Pinyin{tone: 3, initial: "N", final: "i"}, %Pinyin{tone: 3, initial: "h", final: "ao"}, "!"]}

      iex> Pinyin.read("Ni3hao3, hello!")
      {:error, "hello!"}

  This behaviour can be tweaked if pinyin mixed with regular text needs to be parsed; this can be
  done by passing a `mode` to this function. There are 3 available modes:

  - `:exclusive`: The default. Every character (except white space and punctuation) is
    interpreted as pinyin. If this is not possible, an error is returned.
  - `:words`: Any word (i.e. a continuous part of the string that does not contain whitespace or
    punctuation) is either interpreted as a sequence of pinyin syllables or as non-pinyin text. If
    a word contains any characters that cannot be interpreted as pinyin, the whole word is
    considered to be non-pinyin text. This mode does not return errors.
  - `:mixed`: Any word can contain a mixture of pinyin and non-pinyin characters. The read
    function will interpret anything it can interpret as pinyin as pinyin and leaves the other
    text unmodified. This is mainly useful to mix characters and pinyin. It is recommend to use
    the `:words` mode when possible instead of this mode, as this mode will often parse regular
    text as pinyin text. This mode does not return errors.

  The following examples show the use of all three modes:

      iex> Pinyin.read("Ni3hao3!", :exclusive)
      {:ok, [%Pinyin{tone: 3, initial: "N", final: "i"}, %Pinyin{tone: 3, initial: "h", final: "ao"}, "!"]}

      iex> Pinyin.read("Ni3hao3, hello!", :exclusive)
      {:error, "hello!"}

      iex> Pinyin.read("Ni3好hao3, hello!", :exclusive)
      {:error, "Ni3好hao3, hello!"}

      iex> Pinyin.read("Ni3hao3!", :words)
      {:ok, [%Pinyin{tone: 3, initial: "N", final: "i"}, %Pinyin{tone: 3, initial: "h", final: "ao"}, "!"]}

      iex> Pinyin.read("Ni3hao3, hello!", :words)
      {:ok, [%Pinyin{tone: 3, initial: "N", final: "i"}, %Pinyin{tone: 3, initial: "h", final: "ao"}, ", ", "hello", "!"]}

      iex> Pinyin.read("Ni3好hao3, hello!", :words)
      {:ok, ["Ni3好hao3",  ", ", "hello", "!"]}

      iex> Pinyin.read("Ni3hao3!", :mixed)
      {:ok, [%Pinyin{tone: 3, initial: "N", final: "i"}, %Pinyin{tone: 3, initial: "h", final: "ao"}, "!"]}

      iex> Pinyin.read("Ni3hao3, hello!", :mixed)
      {:ok, [%Pinyin{tone: 3, initial: "N", final: "i"}, %Pinyin{tone: 3, initial: "h", final: "ao"}, ", ", %Pinyin{initial: "h", final: "e"}, "l", %Pinyin{initial: "l", final: "o"}, "!"]}

      iex> Pinyin.read("Ni3好hao3, hello!", :mixed)
      {:ok, [%Pinyin{tone: 3, initial: "N", final: "i"}, "好",  %Pinyin{tone: 3, initial: "h", final: "ao"}, ", ", %Pinyin{initial: "h", final: "e"}, "l", %Pinyin{initial: "l", final: "o"}, "!"]}

  When `:mixed` or `:word` mode is used, it is possible some words are incorrectly identified as
  pinyin. This is generally not a problem for users who just wish to use `marked/1` or
  `numbered/1` on the result of `read/2`, since pinyin syllables with no tone are printed as is.

  ## Capitalization and -r suffix

  This function is able to read capitalized and uppercase pinyin strings. That is, strings such as
  "Ni3hao3", "NI3HAO3" and "NI3hao3" are accepted. However, pinyin words with mixed capitalization
  are not recognized:

      iex> Pinyin.read("Lei3")
      {:ok, [%Pinyin{tone: 3, initial: "L", final: "ei"}]}

      iex> Pinyin.read("LEI3")
      {:ok, [%Pinyin{tone: 3, initial: "L", final: "EI"}]}

      iex> Pinyin.read("LeI")
      {:error, "LeI"}

      iex> Pinyin.read("LEi")
      {:error, "LEi"}

  Finally, this function does not detect the _-r_ suffix. Users of the library should take care to
  fully write out _er_ instead. That is, do not write "zher", use "zheer" instead.

      iex> Pinyin.read("zher")
      {:error, "zher"}

      iex> Pinyin.read("zheer")
      {:ok, [%Pinyin{initial: "zh", final: "e"}, %Pinyin{initial: "", final: "er"}]}
  """
  @spec read(String.t(), :exclusive | :words | :mixed) ::
          {:ok, pinyin_list()} | {:error, String.t()}
  def read(string, mode \\ :exclusive) when mode in [:exclusive, :words, :mixed] do
    case mode do
      :exclusive -> Parsers.pinyin_only(string)
      :words -> Parsers.pinyin_words(string)
      :mixed -> Parsers.pinyin_mix(string)
    end
    |> parser_result()
  end

  @doc """
  Identical to `read/2`, but returns the result or a `ParseError`

  ## Examples

      iex> Pinyin.read!("ni3hao3")
      [%Pinyin{tone: 3, initial: "n", final: "i"}, %Pinyin{tone: 3, initial: "h", final: "ao"}]

      iex> Pinyin.read!("ni3 hao3")
      [%Pinyin{tone: 3, initial: "n", final: "i"}, " ", %Pinyin{tone: 3, initial: "h", final: "ao"}]

      iex> Pinyin.read!("ni 3")
      ** (ParseError) Error occurred when attempting to parse: "3"
  """
  @spec read!(String.t(), :exclusive | :words | :mixed) :: pinyin_list() | no_return()
  def read!(string, mode \\ :exclusive) when mode in [:exclusive, :words, :mixed] do
    case read(string, mode) do
      {:ok, res} -> res
      {:error, remainder} -> raise ParseError, remainder
    end
  end

  @doc """
  Read a string containing marked pinyin and convert it into `t:pinyin_list/0`.

  Like `read/2`, but only accepts marked pinyin.

  ## Examples

      iex> Pinyin.read_marked("Nǐhǎo!", :exclusive)
      {:ok, [%Pinyin{tone: 3, initial: "N", final: "i"}, %Pinyin{tone: 3, initial: "h", final: "ao"}, "!"]}

      iex> Pinyin.read_marked("Nǐhǎo, hello!", :exclusive)
      {:error, "hello!"}

      iex> Pinyin.read_marked("Ni3hao3, hello!", :exclusive)
      {:error, "Ni3hao3, hello!"}

      iex> Pinyin.read_marked("Nǐhǎo, hello!", :words)
      {:ok, [%Pinyin{tone: 3, initial: "N", final: "i"}, %Pinyin{tone: 3, initial: "h", final: "ao"}, ", ", "hello", "!"]}

      iex> Pinyin.read_marked("Ni3hao3, hello!", :words)
      {:ok, ["Ni3hao3", ", ", "hello", "!"]}

      iex> Pinyin.read_marked("Ni3hǎo, hello!", :words)
      {:ok, ["Ni3hǎo", ", ", "hello", "!"]}

      iex> Pinyin.read_marked("Ni3hao3!", :mixed)
      {:ok, [%Pinyin{tone: 0, initial: "N", final: "i"}, "3", %Pinyin{tone: 0, initial: "h", final: "ao"}, "3", "!"]}

      iex> Pinyin.read_marked("Ni3hǎo, hello!", :mixed)
      {:ok, [%Pinyin{tone: 0, initial: "N", final: "i"}, "3", %Pinyin{tone: 3, initial: "h", final: "ao"}, ", ", %Pinyin{initial: "h", final: "e"}, "l", %Pinyin{initial: "l", final: "o"}, "!"]}
  """
  @spec read_marked(String.t(), :exclusive | :words | :mixed) ::
          {:ok, pinyin_list()} | {:error, String.t()}
  def read_marked(string, mode \\ :exclusive) do
    case mode do
      :exclusive -> Parsers.marked_only(string)
      :words -> Parsers.marked_words(string)
      :mixed -> Parsers.marked_mix(string)
    end
    |> parser_result()
  end

  @doc """
  Identical to `read_marked/2`, but returns the result or a `ParseError`

  ## Examples

      iex> Pinyin.read_marked!("nǐhǎo")
      [%Pinyin{tone: 3, initial: "n", final: "i"}, %Pinyin{tone: 3, initial: "h", final: "ao"}]

      iex> Pinyin.read_marked!("ni3 hao3")
      ** (ParseError) Error occurred when attempting to parse: "ni3 hao3"
  """
  @spec read_marked!(String.t(), :exclusive | :words | :mixed) :: pinyin_list() | no_return()
  def read_marked!(string, mode \\ :exclusive) when mode in [:exclusive, :words, :mixed] do
    case read_marked(string, mode) do
      {:ok, res} -> res
      {:error, remainder} -> raise ParseError, remainder
    end
  end

  @doc """
  Read a string containing numbered pinyin and convert it into `t:pinyin_list/0`.

  Like `read/2`, but only accepts numbered pinyin.

  ## Examples

      iex> Pinyin.read_numbered("Ni3hao3!", :exclusive)
      {:ok, [%Pinyin{tone: 3, initial: "N", final: "i"}, %Pinyin{tone: 3, initial: "h", final: "ao"}, "!"]}

      iex> Pinyin.read_numbered("Ni3hao3, hello!", :exclusive)
      {:error, "hello!"}

      iex> Pinyin.read_numbered("Nǐhǎo, hello!", :exclusive)
      {:error, "Nǐhǎo, hello!"}

      iex> Pinyin.read_numbered("Ni3hao3, hello!", :words)
      {:ok, [%Pinyin{tone: 3, initial: "N", final: "i"}, %Pinyin{tone: 3, initial: "h", final: "ao"}, ", ", "hello", "!"]}

      iex> Pinyin.read_numbered("Nǐhǎo, hello!", :words)
      {:ok, ["Nǐhǎo", ", ", "hello", "!"]}

      iex> Pinyin.read_numbered("Ni3hǎo, hello!", :words)
      {:ok, ["Ni3hǎo", ", ", "hello", "!"]}

      iex> Pinyin.read_numbered("Ni3hǎo!", :mixed)
      {:ok, [%Pinyin{tone: 3, initial: "N", final: "i"}, "hǎ", %Pinyin{final: "o"}, "!"]}

      iex> Pinyin.read_numbered("Ni3hǎo, hello!", :mixed)
      {:ok, [%Pinyin{tone: 3, initial: "N", final: "i"}, "hǎ", %Pinyin{final: "o"}, ", ", %Pinyin{initial: "h", final: "e"}, "l", %Pinyin{initial: "l", final: "o"}, "!"]}
  """
  @spec read_numbered(String.t(), :exclusive | :words | :mixed) ::
          {:ok, pinyin_list()} | {:error, String.t()}
  def read_numbered(string, mode \\ :exclusive) do
    case mode do
      :exclusive -> Parsers.numbered_only(string)
      :words -> Parsers.numbered_words(string)
      :mixed -> Parsers.numbered_mix(string)
    end
    |> parser_result()
  end

  @doc """
  Identical to `read_numbered/2`, but returns the result or a `ParseError`

  ## Examples

      iex> Pinyin.read_numbered!("ni3hao3")
      [%Pinyin{tone: 3, initial: "n", final: "i"}, %Pinyin{tone: 3, initial: "h", final: "ao"}]

      iex> Pinyin.read_numbered!("nǐhǎo")
      ** (ParseError) Error occurred when attempting to parse: "nǐhǎo"
  """
  @spec read_numbered!(String.t(), :exclusive | :words | :mixed) :: pinyin_list() | no_return()
  def read_numbered!(string, mode \\ :exclusive) when mode in [:exclusive, :words, :mixed] do
    case read_numbered(string, mode) do
      {:ok, res} -> res
      {:error, remainder} -> raise ParseError, remainder
    end
  end

  @doc """
  Sigil to create a pinyin list or struct.

  When used without any modifiers, this sigil converts its input into a pinyin list through the
  use of `read!/2` in `:exclusive` mode. The `w` and `m` modifiers can be used to use `:words` or
  `:mixed` mode respectively.

  When this sigil is called with the `s` modifier, a pinyin struct is created by calling
  `from_string!/1`.

  ## Examples

      iex> ~p/ni3/
      [%Pinyin{tone: 3, initial: "n", final: "i"}]

      iex> ~p/ni3 hello/w
      [%Pinyin{tone: 3, initial: "n", final: "i"}, " ", "hello"]

      iex> ~p/ni3好/m
      [%Pinyin{tone: 3, initial: "n", final: "i"}, "好"]

      iex> ~p/ni3/s
      %Pinyin{tone: 3, initial: "n", final: "i"}

  """
  defmacro sigil_p({:<<>>, _, [word]}, [?s]) when is_binary(word) do
    Macro.escape(from_string!(word))
  end

  defmacro sigil_p({:<<>>, _, [string]}, mode)
           when is_binary(string) and mode in [[], [?w], [?m]] do
    mode =
      case mode do
        [?w] -> :words
        [?m] -> :mixed
        [] -> :exclusive
      end

    Macro.escape(read!(string, mode))
  end

  # -------------------------- #
  # String & IOlist Conversion #
  # -------------------------- #

  @doc """
  Convert a `t:t/0` or `t:pinyin_list/0` to a numbered version.

  The numbered version consists of the word without tone markings followed by the number of the
  tone. It is often used when typing pinyin manually. Any occurence of "ü" is shown as "v".
  Non-pinyin text is not modified.

  ## Examples

      iex> numbered(~p/nǐ/s)
      "ni3"

      iex> numbered(~p/lüè/s)
      "lve4"

      iex> numbered(~p/nǐhǎo/)
      "ni3hao3"

      iex> numbered(~p/NǏHǍO/)
      "NI3HAO3"

      iex> numbered(~p/Nǐhǎo, how are you?/w)
      "Ni3hao3, how are you?"
  """
  @spec numbered(t() | pinyin_list()) :: String.t()
  def numbered(%Pinyin{initial: i, final: f, tone: 0}), do: i <> f
  def numbered(%Pinyin{initial: i, final: f, tone: t}), do: i <> f <> to_string(t)

  def numbered(list) when is_list(list) do
    list
    |> Enum.map(fn
      p = %Pinyin{} -> numbered(p)
      str when is_binary(str) -> str
    end)
    |> Enum.join()
  end

  @doc """
  Convert a `t:t/0` or `t:pinyin_list/0` to numbered iodata.

  Identical to `numbered/1`, except that the numbered pinyin is written as `t:iodata/0` instead of
  as a `t:String.t/0`.

  ## Examples

      iex> numbered_iodata(~p/nǐ/s)
      ["n", "i", "3"]

      iex> numbered_iodata(~p/lüè/s)
      ["l", "ve", "4"]

      iex> numbered_iodata(~p/nǐhǎo/)
      [["n", "i", "3"], ["h", "ao", "3"]]

      iex> numbered_iodata(~p/Nǐhǎo, how are you?/w)
      [["N", "i", "3"], ["h", "ao", "3"], ", ", "how", " ", "a", ["r", "e"], " ", "you", "?"]
  """
  @spec numbered_iodata(t() | pinyin_list()) :: iodata()
  def numbered_iodata(%Pinyin{initial: "", final: f, tone: 0}), do: f
  def numbered_iodata(%Pinyin{initial: "", final: f, tone: t}), do: [f, to_string(t)]
  def numbered_iodata(%Pinyin{initial: i, final: f, tone: 0}), do: [i, f]
  def numbered_iodata(%Pinyin{initial: i, final: f, tone: t}), do: [i, f, to_string(t)]

  def numbered_iodata(list) when is_list(list) do
    Enum.map(list, fn
      p = %Pinyin{} -> numbered_iodata(p)
      other -> other
    end)
  end

  @doc """
  Convert a `t:t/0` or `t:pinyin_list/0` to a tone-marked string.

  The tone-marked string consists of the pinyin word with the tone added in the correct location.
  It is generally used when printing pinyin. Any occurence of "v" is shown as "ü".

  ## Examples

      iex> marked(~p/ni3/s)
      "nǐ"

      iex> marked(~p/lve4/s)
      "lüè"

      iex> marked(~p/ni3hao3/)
      "nǐhǎo"

      iex> marked(~p/NI3HAO3/)
      "NǏHǍO"

      iex> marked(~p/Ni3hao3, how are you?/w)
      "Nǐhǎo, how are you?"

  """
  @spec marked(t() | pinyin_list()) :: String.t()
  def marked(pinyin)

  # Avoid work when there is no tone marker
  def marked(%Pinyin{initial: i, final: f, tone: 0}), do: i <> replace_v(f)

  # Special cases
  def marked(%Pinyin{initial: "", final: "ê", tone: t}), do: mark("ê", t)
  def marked(%Pinyin{initial: "", final: "Ê", tone: t}), do: mark("Ê", t)
  def marked(%Pinyin{initial: "", final: "m", tone: t}), do: mark("m", t)
  def marked(%Pinyin{initial: "", final: "M", tone: t}), do: mark("M", t)
  def marked(%Pinyin{initial: "", final: <<"n", rem::binary>>, tone: t}), do: mark("n", t) <> rem
  def marked(%Pinyin{initial: "", final: <<"N", rem::binary>>, tone: t}), do: mark("N", t) <> rem

  def marked(%Pinyin{initial: i, final: f, tone: t}) do
    final = replace_v(f)

    vowel = final |> String.codepoints() |> Enum.reduce(nil, &select_max/2)
    i <> String.replace(final, vowel, mark(vowel, t))
  end

  def marked(list) when is_list(list) do
    list
    |> Enum.map(fn
      p = %Pinyin{} -> marked(p)
      str when is_binary(str) -> str
    end)
    |> Enum.join()
  end

  defp replace_v(str), do: String.replace(str, ~w(v V), &if(&1 == "v", do: "ü", else: "Ü"))

  @doc """
  Convert a `t:t/0` or `t:pinyin_list/0` to marked iodata.

  Identical to `marked/1`, except that the marked pinyin is written as `t:iodata/0` instead of as
  a `t:String.t/0`.
  """
  @spec marked_iodata(t() | pinyin_list()) :: iodata()
  # Avoid work when there is no tone marker
  def marked_iodata(%Pinyin{initial: "", final: f, tone: 0}), do: f

  # Special cases
  def marked_iodata(%Pinyin{initial: "", final: "ê", tone: t}), do: mark("ê", t)
  def marked_iodata(%Pinyin{initial: "", final: "Ê", tone: t}), do: mark("Ê", t)
  def marked_iodata(%Pinyin{initial: "", final: "m", tone: t}), do: mark("m", t)
  def marked_iodata(%Pinyin{initial: "", final: "M", tone: t}), do: mark("M", t)

  def marked_iodata(%Pinyin{initial: "", final: <<c, rem::binary>>, tone: t}) when c in [?n, ?N] do
    [mark("n", t), rem]
  end

  def marked_iodata(%Pinyin{initial: i, final: f, tone: t}) do
    final = replace_v_iolist(f, 0)

    vowel = final |> String.codepoints() |> Enum.reduce(nil, &select_max/2)
    i <> String.replace(final, vowel, mark(vowel, t))
  end

  def marked_iodata(list) when is_list(list) do
    Enum.map(list, fn
      p = %Pinyin{} -> numbered_iodata(p)
      other -> other
    end)
  end

  defp replace_v_iolist(binary, offset) when offset > byte_size(binary), do: binary

  defp replace_v_iolist(binary, offset) do
    case binary do
      <<pre::binary-size(offset), ?v, rem::binary>> -> [pre, "ü", rem]
      <<pre::binary-size(offset), ?V, rem::binary>> -> [pre, "Ü", rem]
        _ -> replace_v_iolist(binary, offset + 1)
    end
  end

  # Tone Placement
  # --------------
  # Order matters here, do not randomly rearrange these clauses!

  # a always wins
  defp select_max("a", _), do: "a"
  defp select_max(_, "a"), do: "a"
  defp select_max("A", _), do: "A"
  defp select_max(_, "A"), do: "A"

  # e never occurs with a and always wins
  defp select_max("e", _), do: "e"
  defp select_max(_, "e"), do: "e"
  defp select_max("E", _), do: "E"
  defp select_max(_, "E"), do: "E"

  # o always wins if there is no a present
  defp select_max("o", _), do: "o"
  defp select_max(_, "o"), do: "o"
  defp select_max("O", _), do: "O"
  defp select_max(_, "O"), do: "O"

  # in the case of ui, the second letter takes the mark Keep in mind the "left" argument is the
  # new letter, this is done to make it easy to pass the function to reduce.
  defp select_max("i", "u"), do: "i"
  defp select_max("I", "U"), do: "I"
  defp select_max("i", "U"), do: "i"
  defp select_max("I", "u"), do: "I"

  defp select_max("u", "i"), do: "u"
  defp select_max("U", "I"), do: "U"
  defp select_max("u", "I"), do: "u"
  defp select_max("U", "i"), do: "U"

  # If none of the above match whichever vowel is present takes the mark
  defp select_max(v, _) when v in ["a", "e", "i", "o", "u", "ü"], do: v
  defp select_max(v, _) when v in ["A", "E", "I", "O", "U", "Ü"], do: v

  # If there is no vowel, stay with previous selection
  defp select_max(_, p), do: p
end

# --------- #
# Protocols #
# --------- #

defimpl String.Chars, for: Pinyin do
  def to_string(p = %Pinyin{}), do: Pinyin.marked(p)
end

defimpl List.Chars, for: Pinyin do
  def to_charlist(p = %Pinyin{}), do: Kernel.to_charlist(Pinyin.marked(p))
end

defimpl Inspect, for: Pinyin do
  import Inspect.Algebra
  def inspect(p = %Pinyin{}, _), do: concat(["#Pinyin<", to_string(p), ">"])
end
