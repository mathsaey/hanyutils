# Hanyutils

[![hex.pm](https://img.shields.io/hexpm/v/hanyutils.svg)](https://hex.pm/packages/hanyutils)
[![hexdocs.pm](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/hanyutils/api-reference.html)
[![hex.pm](https://img.shields.io/hexpm/dt/hanyutils.svg)](https://hex.pm/packages/hanyutils)
[![hex.pm](https://img.shields.io/hexpm/l/hanyutils.svg)](https://hex.pm/packages/hanyutils)
[![github.com](https://img.shields.io/github/last-commit/mathsaey/hanyutils.svg)](https://github.com/mathsaey/hanyutils/commits/master)

Flexible, modular utilities for dealing with Chinese characters
([Hanzi](https://en.wikipedia.org/wiki/Chinese_characters)) and
[Pinyin](https://en.wikipedia.org/wiki/Pinyin).

## Features

- Convert Chinese characters (Hanzi) to Pinyin
  - Based on the [Unicode Han Database](http://www.unicode.org/reports/tr38/tr38-27.html)
  - Showing only the most common pronunciation
  - Showing the most common pronunciation for Taiwan (if it differs from the
  most common pronunciation in mainland China)
  - Showing all available pronunciations
- Read and manipulate pinyin strings
  - Read both tone-marked and numbered pinyin strings. Supports capitalized and
  uppercase pinyin words, and supports strings containing pinyin mixed with
  regular text
  - Convert to either representation (numbered or tone marked)
- Direct access to the building blocks of the library for more esoteric use cases

The following features are planned for a future version of hanyutils:

- Handle punctuation (。,？,！,...) when translating Han characters
- Support for 儿 (e.g. translate 这儿 to "zhe'er" instead of "zheer")

## Installation

Add `hanyutils` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:hanyutils, "~> 0.2.5"}
  ]
end
```

Note that this package automatically generates functions based on a (large)
file.
Therefore, compiling this dependency takes some time (around a minute on my machine).

## Usage

If you are dealing with a common use case (e.g. converting all characters in a
string to pinyin) it is likely your use case is covered by the `Hanyutils`
module:

```elixir
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
"ㄋㄧˇㄏㄠˇ"

iex> Hanyutils.pinyin_to_zhuyin("ni3hǎo")
"ㄋㄧˇㄏㄠˇ"
```

The `Hanyutils` module is built on top of the `Hanzi`, `Pinyin`, and `Zhuyin` modules.
You can use these lower-level modules directly if your use case is not present in `Hanyutils`.

Feel free to file an issue if you feel like your use case should be covered by the `Hanyutils` module.

As an example, the `to_marked_pinyin` function shown above could be replaced by the following code:

```elixir
iex> "你好" |> Hanzi.read() |> Hanzi.to_pinyin() |> Pinyin.marked()
"nǐhǎo"
```

Alternative versions of this procedure which show all available pronunciations can be written as follows:

```elixir
iex> "重庆" |> Hanzi.read() |> Hanzi.to_pinyin(&Hanzi.all_pronunciations/1) |> Pinyin.marked()
"[ zhòng | chóng | tóng ]qìng"

iex> "重庆" |> Hanzi.read() |> Hanzi.to_pinyin(&Hanzi.all_pronunciations(&1, "{", ";", "}")) |> Pinyin.marked()
"{zhòng;chóng;tóng}qìng"
```

## License

MIT
