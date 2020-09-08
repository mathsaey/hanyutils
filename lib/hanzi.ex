defmodule Hanzi do
  @moduledoc """
  Han/Chinese character (汉字) utilities and conversion to Pinyin lists.

  The main goal of this module is to convert strings containing Han characters into a
  `t:Pinyin.pinyin_list/0`. In turn, such a list can be formatted by the functions present in the
  `Pinyin` module (i.e. `Pinyin.marked/1` or `Pinyin.numbered/1`).

  A string of Han characters can be read with `read/1` or `sigil_h/2`. These functions both return
  a list containing strings mixed with `t:Hanzi.t/0` structs. Such a list can be converted into
  a `t:Pinyin.pinyin_list/0` through the use of `to_pinyin/2`. Users with more esoteric use cases
  can directly modify the `t:Hanzi.t/0` inside the `t:hanzi_list/0`.

  ## `to_pinyin/2` and converters

  Since a given Hanzi may have different valid pronunciations, `to_pinyin/2` accepts a second
  argument that determines how a given `t:Hanzi.t/0` is converted into a `t:Pinyin.pinyin_list/0`.
  This second argument is called a _converter_. This module includes some standard converters.
  Please refer to the documentation of `to_pinyin/2` for more information.

  ## Data source

  The results of the functions offered by this module are all ultimately derived from the data
  contained in the `Unihan_Readings.txt` file of the
  [Unicode Han Database](http://www.unicode.org/reports/tr38/tr38-27.html).
  `t:t/0` contains additional information about the available information.
  """

  @enforce_keys [:char, :pron]
  defstruct [:char, :pron, pron_tw: nil, alt: []]

  @typedoc """
  Representation of a single Hanzi (chinese Character).

  This struct contains all the information extraced from the Unihan_readings database for a given
  character. It contains the following fields:

  | Key       | Description                                         | `Unihan_Readings.txt` field |
  | --------- | --------------------------------------------------- | --------------------------- |
  | `char`    | The character itself                                |                             |
  | `pron`    | Most common pronunciation in pinyin                 | [kMandarin](http://www.unicode.org/reports/tr38/tr38-27.html#kMandarin)       |
  | `pron_tw` | Most common pronunciation for Taiwan in Pinyin      | [kMandarin](http://www.unicode.org/reports/tr38/tr38-27.html#kMandarin)       |
  | `alt`     | All readings defined by the Hanyu Pinyin Dictionary | [kHanyuPinyin](http://www.unicode.org/reports/tr38/tr38-27.html#kHanyuPinyin) |

  ## `pron` and `pron_tw`

  In some rare cases, the most common reading of a hanzi is different in mainland China and in
  Taiwan. If this is the case, the most common mainland reading will be stored under the `pron`
  key, while the most common Taiwanese reading will be stored under the `pron_tw` key. When the
  readings are the same, `pron` will contain the reading while `pron_tw` will be `nil`.  Note
  that, at the time of writing, only 38 characters out of the 41226 defined by
  `Unihan_Readings.txt` have a different reading for mainland China and Taiwan.

  ## `alt`

  Some hanzi have different readings based on their exact use. When this is the case, all the
  possible readings of a character will stored as a list in `alt`.
  """
  @type t :: %__MODULE__{
          char: String.t(),
          pron: Pinyin.t(),
          pron_tw: Pinyin.t() | nil,
          alt: [Pinyin.t()]
        }

  @typedoc """
  List of Hanzi characters mixed with plain strings.
  """
  @type hanzi_list :: [t() | String.t()]

  # ------------------- #
  # Low-level Utilities #
  # ------------------- #

  @doc """
  Obtain the `t:Hanzi.t/0` struct for a character.

  Note that this only works on a single character.

  ## Examples

      iex> Hanzi.from_character("你")
      %Hanzi{char: "你", pron: %Pinyin{word: "ni", tone: 3}, pron_tw: nil, alt: []}
      iex> Hanzi.from_character("x")
      nil
      iex> Hanzi.from_character("你好")
      nil
  """
  @spec from_character(String.t()) :: t() | nil
  def from_character(character), do: Hanzi.Map.lookup(character)

  @doc """
  Check if a _single_ character is a valid Han character.

  ## Examples

      iex> Hanzi.character?("你")
      true
      iex> Hanzi.character?("x")
      false
      iex> Hanzi.character?("你好")
      false
  """
  @spec character?(String.t()) :: boolean()
  def character?(character) do
    from_character(character) != nil
  end

  # ---------- #
  # converters #
  # ---------- #

  @doc """
  Converter that retrieves the most common pronunciation of a `t:Hanzi.t/0`.

  The additional argument specifies if the most common pronunciation for mainland China or Taiwan
  is retrieved.

  ## Examples

      iex> Hanzi.common_pronunciation(~h/你/s)
      [%Pinyin{word: "ni", tone: 3}]
      iex> Hanzi.common_pronunciation(~h/你/s, :cn)
      [%Pinyin{word: "ni", tone: 3}]
      iex> Hanzi.common_pronunciation(~h/你/s, :tw)
      [%Pinyin{word: "ni", tone: 3}]
      iex> Hanzi.common_pronunciation(~h/万/s)
      [%Pinyin{word: "wan", tone: 4}]
      iex> Hanzi.common_pronunciation(~h/万/s, :cn)
      [%Pinyin{word: "wan", tone: 4}]
      iex> Hanzi.common_pronunciation(~h/万/s, :tw)
      [%Pinyin{word: "mo", tone: 4}]
  """
  @spec common_pronunciation(t(), :cn | :tw) :: Pinyin.pinyin_list()
  def common_pronunciation(hanzi, loc \\ :cn)
  def common_pronunciation(hanzi, :cn), do: [hanzi.pron]
  def common_pronunciation(hanzi, :tw), do: [hanzi.pron_tw || hanzi.pron]

  @doc """
  Converter that returns all pronunciations of a character or the most common.

  If only a single pronunciation is available, it is returned, otherwise, all possible
  pronunciations are returned. When all possible pronunciations are returned, `left`, `mid` and
  `right` determine how the alternatives are separated. `left` is positioned before the first
  pronunciation in the list, `right` is positioned after the last pronunciation, `mid` is
  positioned between all the other pronunciations.

  ## Examples

      iex> Hanzi.all_pronunciations(~h/你/s)
      [%Pinyin{word: "ni", tone: 3}]
      iex> Hanzi.all_pronunciations(~h/㓎/s)
      ["[ ", %Pinyin{word: "qin", tone: 1}, " | ", %Pinyin{word: "qin", tone: 4}, " | ", %Pinyin{word: "qin", tone: 3}, " ]"]
      iex> Hanzi.all_pronunciations(~h/㓎/s, "", "", "")
      ["", %Pinyin{word: "qin", tone: 1}, "", %Pinyin{word: "qin", tone: 4}, "", %Pinyin{word: "qin", tone: 3}, ""]
  """
  @spec all_pronunciations(t(), String.t(), String.t(), String.t()) :: Pinyin.pinyin_list()
  def all_pronunciations(hanzi, left \\ "[ ", mid \\ " | ", right \\ " ]")

  def all_pronunciations(%Hanzi{pron: p, alt: []}, _, _, _), do: [p]

  def all_pronunciations(%Hanzi{pron: _, alt: alt}, left, mid, right) do
    [left | Enum.intersperse(alt, mid) ++ [right]]
  end

  # ------------- #
  # Hanzi Strings #
  # ------------- #

  @doc """
  Read a string and convert it into a list of strings and `t:Hanzi.t/0` structs.

  This function reads a string containing characters mixed with normal text. The output of this
  function is a list of strings and Hanzi structs.

  The input string may contain any character. Any character in the string that is recognised as a
  Han character (by `character?/1`) is returned as a `t:Hanzi.t/0` in the returned list.  Any
  other character in the input is returned unmodified.

  ## Examples

      iex> Hanzi.read("你好")
      [%Hanzi{char: "你", pron: %Pinyin{word: "ni", tone: 3}}, %Hanzi{char: "好", pron: %Pinyin{word: "hao", tone: 3}, alt: [%Pinyin{word: "hao", tone: 3}, %Pinyin{word: "hao", tone: 4}]}]
      iex> Hanzi.read("hello, 你")
      ["hello, ", %Hanzi{char: "你", pron: %Pinyin{word: "ni", tone: 3}}]
  """
  @spec read(String.t()) :: hanzi_list()
  def read(string) do
    string
    |> String.graphemes()
    |> Stream.map(fn el ->
      case from_character(el) do
        nil -> el
        hanzi -> hanzi
      end
    end)
    # TODO: separate whitespace in future version?
    |> Stream.chunk_by(&match?(%Hanzi{}, &1))
    |> Stream.flat_map(fn
      lst = [el | _] when is_binary(el) -> [Enum.join(lst)]
      lst = [%Hanzi{} | _] -> lst
    end)
    |> Enum.to_list()
  end

  @doc """
  Sigil to create a Hanzi list or struct.

  When used without any modifiers, this sigil converts ins input into a hanzi list through the use
  of `read/1`. When the `s` modifier is used, `from_character/1` is used instead.

  ## Examples

      iex> ~h/hello, 你/
      ["hello, ", %Hanzi{char: "你", pron: %Pinyin{word: "ni", tone: 3}}]
      iex> ~h/你/s
      %Hanzi{char: "你", pron: %Pinyin{word: "ni", tone: 3}}
      iex> ~h/你好/s
      nil
  """
  defmacro sigil_h({:<<>>, _, [char]}, [?s]) when is_binary(char) do
    hanzi = from_character(char)

    quote do
      unquote(Macro.escape(hanzi))
    end
  end

  defmacro sigil_h({:<<>>, _, [string]}, []) when is_binary(string) do
    list = read(string)

    quote do
      unquote(Macro.escape(list))
    end
  end

  @doc """
  Verify if a list or string contains only characters.

  Note that whitespace is not counted as a character.

  ## Examples

      iex> Hanzi.characters?(["你", "好"])
      true
      iex> Hanzi.characters?(["你", "boo", "好"])
      false
      iex> Hanzi.characters?("你好")
      true
      iex> Hanzi.characters?("你 好")
      false
  """
  @spec characters?(String.t() | [String.t()]) :: boolean()
  def characters?(l) when is_list(l), do: Enum.all?(l, &character?/1)

  def characters?(str) when is_binary(str) do
    str
    |> String.graphemes()
    |> characters?()
  end

  @doc """
  Convert a Hanzi list to a string of characters.

  This function extracts the character of each `t:Hanzi.t/0` in `lst`. Normal strings in the list
  not modified. After converting the Hanzi in the list to characters, the list is joined with
  `Enum.join/2`. The `joiner` argument will be passed as the `joiner` to `Enum.join/2`.

  ## Examples

      iex> characters(~h/你好/)
      "你好"
      iex> characters(~h/你hello/)
      "你hello"
      iex> characters(~h/你好/, ";")
      "你;好"
      iex> characters(~h/你hello/, ";")
      "你;hello"
  """
  @spec characters(hanzi_list(), String.t()) :: String.t()
  def characters(lst, joiner \\ "") do
    lst
    |> Enum.map(fn
      %Hanzi{char: c} -> c
      str -> str
    end)
    |> Enum.join(joiner)
  end

  @doc """
  Convert a Hanzi list to a Pinyin list.

  Normal strings in the Hanzi list are returned unmodified. Every `Hanzi.t()` is passed as an
  argument to `converter`, which returns a `t:Pinyin.pinyin_list/0`. This list is added to the
  result.

  After calling this function, `Pinyin.marked/1` or `Pinyin.numbered/1` can be used to format the
  result.

  ## Converters

  A converter is any function that transforms a `t:Hanzi.t/0` into a `t:Pinyin.pinyin_list/0`.
  In the most simple case, such a converter simply returns the most common pronunciation. In more
  complicated cases, such a converter returns all the possible pronunciations of a Hanzi,
  separated by strings.

  The `Hanzi` module includes two converters: `common_pronunciation/2` and `all_pronunciations/4`.
  If no converter is specified, `&common_pronunciation(&1, :cn)` is used.

  If you wish to write your own converter, the functions mentioned above, and the examples below
  should be a good starting point.

  ## Examples

      iex> to_pinyin(~h/你好/)
      [%Pinyin{word: "ni", tone: 3}, %Pinyin{word: "hao", tone: 3}]
      iex> to_pinyin(~h/二万/, &common_pronunciation(&1, :tw))
      [%Pinyin{word: "er", tone: 4}, %Pinyin{word: "mo", tone: 4}]
      iex> to_pinyin(~h/你好/, &all_pronunciations/1)
      [%Pinyin{word: "ni", tone: 3}, "[ ", %Pinyin{word: "hao", tone: 3}, " | ", %Pinyin{word: "hao", tone: 4}, " ]"]
      iex> to_pinyin(~h/你好/, &all_pronunciations(&1, "", "", ""))
      [%Pinyin{word: "ni", tone: 3}, "", %Pinyin{word: "hao", tone: 3}, "", %Pinyin{word: "hao", tone: 4}, ""]
      iex> to_pinyin(~h/你好/, fn %Hanzi{pron: p} -> [p] end)
      [%Pinyin{word: "ni", tone: 3}, %Pinyin{word: "hao", tone: 3}]
  """
  @spec to_pinyin(hanzi_list(), (t() -> Pinyin.pinyin_list())) :: Pinyin.pinyin_list()
  def to_pinyin(lst, converter \\ &common_pronunciation/1) do
    Enum.flat_map(lst, fn
      h = %Hanzi{} -> converter.(h)
      str -> [str]
    end)
  end
end

defimpl String.Chars, for: Hanzi do
  def to_string(%Hanzi{char: c}), do: c
end

defimpl List.Chars, for: Hanzi do
  def to_charlist(%Hanzi{char: c}), do: Kernel.to_charlist(c)
end

defimpl Inspect, for: Hanzi do
  import Inspect.Algebra

  def inspect(%Hanzi{char: c}, _) do
    concat(["#Hanzi<", c, ">"])
  end
end
