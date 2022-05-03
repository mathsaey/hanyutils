defmodule Zhuyin do
  @moduledoc """
  Utilities to deal with zhuyin syllables and groups thereof.

  The main goal of this module is to provide functions to manipulate strings that contain zhuyin
  words, which are potentially mixed with other content. These strings are represented by the
  `t:zhuyin_list/0` type. Zhuyin lists can be obtained by parsing a string with the `read/2`,
  `read!/2` or `sigil_z/2` functions. Afterwards, these lists can be converted into astring
  representation by using `to_string/1`n.

  A `t:zhuyin_list/0` is a list which contains strings and zhuyin structs (`t:t/0`). These structs
  are used to encode zhuyin syllables; they can be created directly through the use of the
  `from_string/1` or `from_string!/1` functions. Like `t:zhuyin_lists/0`, `t:t/0` structs can be
  converted strings through the use of the `to_string/1`functions.

  Additionally both `t:zhuyin_list/0` and zhuyin structs (`t:t/0`) can be created from or
  converted to pinyin structs (`Pinyin.t:t/0`) using `from_pinyin/1` or `to_pinyin/1` or
  """

  alias Zhuyin.Parsers

  # ----- #
  # Types #
  # ----- #

  @type t :: %__MODULE__{tone: 0..4, initial: String.t(), final: String.t()}

  @enforce_keys [:final]
  defstruct tone: 0, initial: "", final: ""

  @typedoc """
  List of zhuyin syllables mixed with plain strings.
  """
  @type zhuyin_list :: [t() | String.t()]

  # Ordered by which tone number they correspond to
  zhuyin_tones = ["˙", "", "ˊ", "ˇ", "ˋ"]
  def zhuyin_tones, do: unquote(zhuyin_tones)

  # ------------------------- #
  # Pinyin Mapping / Creation #
  # ------------------------- #

  @initials %{
    "ㄅ" => "b",
    "ㄆ" => "p",
    "ㄇ" => "m",
    "ㄈ" => "f",
    "ㄉ" => "d",
    "ㄊ" => "t",
    "ㄋ" => "n",
    "ㄌ" => "l",
    "ㄍ" => "g",
    "ㄎ" => "k",
    "ㄏ" => "h",
    "ㄐ" => "j",
    "ㄑ" => "q",
    "ㄒ" => "x",
    "ㄓ" => "zh",
    "ㄔ" => "ch",
    "ㄕ" => "sh",
    "ㄖ" => "r",
    "ㄗ" => "z",
    "ㄘ" => "c",
    "ㄙ" => "s"
  }
  @reverse_initials Map.new(@initials, fn {key, val} -> {val, key} end)

  # In pinyin standalone finals are spelled differently than when they are
  # combined with an initial
  @standalone_finals %{
    "ㄧ" => "yi",
    "ㄨ" => "wu",
    "ㄩ" => "yu",
    "ㄧㄚ" => "ya",
    "ㄨㄚ" => "wa",
    "ㄧㄥ" => "ying",
    "ㄧㄤ" => "yang",
    "ㄧㄝ" => "ye",
    "ㄨㄛ" => "wo",
    "ㄨㄥ" => "weng",
    "ㄨㄤ" => "wang",
    "ㄧㄠ" => "yao",
    "ㄨㄞ" => "wai",
    "ㄩㄝ" => "yue",
    "ㄩㄥ" => "yong",
    "ㄧㄡ" => "you",
    "ㄨㄟ" => "wei",
    "ㄧㄢ" => "yan",
    "ㄨㄢ" => "wan",
    "ㄩㄢ" => "yuan",
    "ㄧㄣ" => "yin",
    "ㄨㄣ" => "wen",
    "ㄩㄣ" => "yun",
    # Technically standalone initials. Parsed as standalone finals because it's easier to deal with
    "ㄓ" => "zhi",
    "ㄔ" => "chi",
    "ㄕ" => "shi",
    "ㄖ" => "ri",
    "ㄗ" => "zi",
    "ㄘ" => "ci",
    "ㄙ" => "si",
    # Standalone finals that are the same in Pinyin as when combined with an initial
    "ㄦ" => "er",
    "ㄢ" => "an"
  }
  @reverse_standalone_finals Map.new(@standalone_finals, fn {key, val} -> {val, key} end)

  @finals %{
    "ㄧ" => "i",
    "ㄨ" => "u",
    "ㄩ" => "v",
    "ㄚ" => "a",
    "ㄛ" => "o",
    "ㄜ" => "e",
    "ㄝ" => "e",
    "ㄞ" => "ai",
    "ㄟ" => "ei",
    "ㄠ" => "ao",
    "ㄡ" => "ou",
    "ㄢ" => "an",
    "ㄣ" => "en",
    "ㄤ" => "ang",
    "ㄥ" => "eng",
    "ㄦ" => "er",
    "ㄧㄚ" => "ia",
    "ㄨㄚ" => "ua",
    "ㄧㄥ" => "ing",
    "ㄧㄤ" => "iang",
    "ㄧㄝ" => "ie",
    "ㄨㄛ" => "uo",
    "ㄨㄥ" => "ong",
    "ㄨㄤ" => "uang",
    "ㄧㄠ" => "iao",
    "ㄨㄞ" => "uai",
    "ㄩㄝ" => "ve",
    "ㄩㄥ" => "iong",
    "ㄧㄡ" => "iu",
    "ㄨㄟ" => "ui",
    "ㄧㄢ" => "ian",
    "ㄨㄢ" => "uan",
    "ㄩㄢ" => "van",
    "ㄧㄣ" => "in",
    "ㄨㄣ" => "un",
    "ㄩㄣ" => "vn"
  }
  @reverse_finals Map.new(@finals, fn {key, val} -> {val, key} end)

  @doc """
  Create pinyin structs from a zhuyin struct or list.

  ## Examples

      iex> Zhuyin.to_pinyin(~z/ㄋㄧˇㄏㄠˇ/)
      ~p/nǐhǎo/

      iex> Zhuyin.to_pinyin(%Zhuyin{initial: "ㄋ", final: "ㄧ", tone: 3})
      %Pinyin{initial: "n", final: "i", tone: 3}

  """
  @spec to_pinyin(t() | zhuyin_list()) :: Pinyin.t() | Pinyin.pinyin_list()
  def to_pinyin(zhuyin = %Zhuyin{}) do
    if initial = @initials[zhuyin.initial] do
      %Pinyin{initial: initial, final: Map.fetch!(@finals, zhuyin.final), tone: zhuyin.tone}
    else
      %Pinyin{initial: "", final: Map.fetch!(@standalone_finals, zhuyin.final), tone: zhuyin.tone}
    end
  end

  def to_pinyin(list) when is_list(list) do
    list
    |> Enum.map(fn
      z = %Zhuyin{} -> Zhuyin.to_pinyin(z)
      str when is_binary(str) -> str
    end)
  end

  @doc """
  Create zhuyin structs from a pinyin struct or list.

  ## Examples

      iex> Zhuyin.from_pinyin(~p/nǐhǎo/)
      [%Zhuyin{initial: "ㄋ", final: "ㄧ", tone: 3}, %Zhuyin{initial: "ㄏ", final: "ㄠ", tone: 3}]

      iex> Zhuyin.from_pinyin(%Pinyin{initial: "n", final: "i", tone: 3})
      %Zhuyin{initial: "ㄋ", final: "ㄧ", tone: 3}

  """
  @spec from_pinyin(Pinyin.t() | Pinyin.pinyin_list()) :: t()
  def from_pinyin(pinyin = %Pinyin{}) do
    if initial = @reverse_initials[pinyin.initial] do
      %__MODULE__{initial: initial, final: @reverse_finals[pinyin.final], tone: pinyin.tone}
    else
      %__MODULE__{initial: "", final: @reverse_standalone_finals[pinyin.final], tone: pinyin.tone}
    end
  end

  def from_pinyin(list) when is_list(list) do
    list
    |> Enum.map(fn
      p = %Pinyin{} -> from_pinyin(p)
      str when is_binary(str) -> str
    end)
  end

  @spec read(String.t(), :exclusive | :words | :mixed) ::
          {:ok, zhuyin_list()} | {:error, String.t()}
  def read(string, mode \\ :exclusive) when mode in [:exclusive, :words, :mixed] do
    res =
      case mode do
        :exclusive -> Zhuyin.Parsers.zhuyin_only(string)
        :words -> Zhuyin.Parsers.zhuyin_words(string)
        :mixed -> Zhuyin.Parsers.zhuyin_mix(string)
      end

    case res do
      {:ok, lst, "", %{}, _, _} -> {:ok, lst}
      {:error, _, remainder, %{}, _, _} -> {:error, remainder}
    end
  end

  @spec read!(String.t(), :exclusive | :words | :mixed) ::
          zhuyin_list() | no_return()
  def read!(string, mode \\ :exclusive)
      when mode in [:exclusive, :words, :mixed] do
    case read(string, mode) do
      {:ok, res} -> res
      {:error, remainder} -> raise ParseError, remainder
    end
  end

  defp parser_result({:ok, res, "", %{}, _, _}), do: {:ok, res}
  defp parser_result({:error, _, rem, %{}, _, _}), do: {:error, rem}

  defp parser_result!({:ok, res, "", %{}, _, _}), do: res
  defp parser_result!({:error, _, rem, %{}, _, _}), do: raise(ParseError, rem)

  @doc """
  Create a single zhuyin struct (`t:t/0`) from a string.

  This function can be used to parse a single zhuyin syllable.

  If parsing fails, an `{:error, <remainder of string>}` is returned, `<remainder of string>`
  contains the part of the string which made parsing fail.

  ## Examples

      iex> Zhuyin.from_string("ㄋㄧˇ")
      {:ok, %Zhuyin{initial: "ㄋ", final: "ㄧ", tone: 3}}

      iex> Zhuyin.from_string("ㄋㄧˇㄏㄠˇ")
      {:error, "ㄏㄠˇ"}

      iex> Zhuyin.from_string("ㄋㄧˇhǎo")
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
  Create a single zhuyin struct (`t:t/0`) from a string.

  Like `from_string/1`, but returns the result or raises an exception if an error occurred while
  parsing.

  ## Examples

      #iex> Zhuyin.from_string("ㄋㄧˇ")
      #%Zhuyin{initial: "ㄋ", final: "ㄧ", tone: 3}}

      #iex> Zhuyin.from_string("ㄋㄧˇㄏㄠˇ")
      ##** (ParseError) Error occurred when attempting to parse: "ㄋㄧˇㄏㄠˇ"

      #iex> Zhuyin.from_string("ㄋㄧˇhǎo")
      ##** (ParseError) Error occurred when attempting to parse: "ㄋㄧˇhǎo"
  """
  @spec from_string!(String.t()) :: t() | no_return()
  def from_string!(word), do: word |> Parsers.syllable() |> parser_result!() |> hd()

  @doc """
  Sigil to create a zhuyin list or struct.

  When used without any modifiers, this sigil converts its input into a zhuyin list through the
  use of `read!/2` in `:exclusive` mode. The `w` and `m` modifiers can be used to use `:words` or
  `:mixed` mode respectively.

  When this sigil is called with the `s` modifier, a zhuyin struct is created by calling
  `from_string!/1`.

  ## Examples

      iex> ~z/ㄋㄧˇ/
      [%Zhuyin{tone: 3, initial: "ㄋ", final: "ㄧ"}]

      #iex> ~z/ㄋㄧˇ hello/w
      #[%Zhuyin{tone: 3, initial: "ㄋ", final: "ㄧ"}, " ", "hello"]

      #iex> ~z/ㄋㄧˇ好/m
      #[%Zhuyin{tone: 3, initial: "ㄋ", final: "ㄧ"}, "好"]

      #iex> ~z/ㄋㄧˇ/s
      #%Zhuyin{tone: 3, initial: "ㄋ", final: "ㄧ"}

  """
  defmacro sigil_z({:<<>>, _, [word]}, [?s]) when is_binary(word) do
    Macro.escape(from_string!(word))
  end

  defmacro sigil_z({:<<>>, _, [string]}, mode)
           when is_binary(string) and mode in [[], [?w], [?m]] do
    mode =
      case mode do
        [?w] -> :words
        [?m] -> :mixed
        [] -> :exclusive
      end

    Macro.escape(read!(string, mode))
  end
end

# --------- #
# Protocols #
# --------- #

defimpl String.Chars, for: Zhuyin do
  def to_string(z = %Zhuyin{}) do
    z.initial <> z.final <> Enum.at(Zhuyin.zhuyin_tones(), z.tone)
  end
end

defimpl List.Chars, for: Zhuyin do
  @spec to_charlist(Zhuyin.t()) :: charlist()
  def to_charlist(p = %Zhuyin{}) do
    Kernel.to_charlist(to_string(p))
  end
end

defimpl Inspect, for: Zhuyin do
  import Inspect.Algebra

  def inspect(p = %Zhuyin{}, _) do
    concat(["#Zhuyin<", to_string(p), ">"])
  end
end
