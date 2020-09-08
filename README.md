# Hanyutils

Utilities for dealing with Chinese characters (hanzi) and pinyin.

## Features

- Convert hanzi to pinyin
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
    {:hanyutils, "~> 0.2.2"}
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

```
iex> Hanyutils.to_marked_pinyin("你好")
"nǐhǎo"
iex> Hanyutils.to_numbered_pinyin("你好")
"ni3hao3"
iex> Hanyutils.characters?("你好")
true
iex> Hanyutils.mark_pinyin("ni3hao3")
"nǐhǎo"
iex> Hanyutils.number_pinyin("nǐhǎo")
"ni3hao3"
```

The `Hanyutils` module is built on top of the `Hanzi` and `Pinyin` modules.
You can use these lower-level modules directly if your use case is not present
in `Hanyutils`<sup>[*](#usecasefn)</sup> . As an example, the `to_marked_pinyin` function shown above could
be replaced by the following code:

```elixir
"你好" |> Hanzi.read() |> Hanzi.to_pinyin() |> Pinyin.marked()
```

The documentation for all of these modules can be found at [https://hexdocs.pm/hanyutils](https://hexdocs.pm/hanyutils).

<a name="usecasefn">*</a> Feel free to file an issue if you feel like your use case should be covered by the `Hanyutils` module.

## License

MIT
