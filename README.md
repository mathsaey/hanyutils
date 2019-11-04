# Hanyutils

Utilities for dealing with Chinese characters (hanzi) and pinyin.

Feature requests, issues and pull requests are welcome!

## Installation

Add `hanyutils` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:hanyutils, "~> 0.1.0"}
  ]
end
```

Note that this package automatically generates functions based on a (large) file.
Therefore, compiling the dependency may take some time.

## Usage

This package defines two modules: `Pinyin` and `Hanzi`.
The former deals with pinyin, while the latter deals with hanzi.

Documentation about both modules can be found at [https://hexdocs.pm/hanyutils](https://hexdocs.pm/hanyutils).
The most important provided functions are shown below.

### Hanzi

```
iex> Hanzi.is_character?("你")
true
iex> Hanzi.to_pinyin("你好")
"nǐhǎo"
```

### Pinyin

```
iex> Pinyin.prettify("ni3hao3")
"nǐhǎo"
iex> Pinyin.prettify("lve4")
"lüè"
```

## Note on characters with multiple pronunciations

Certain characters have multiple possible readings. Be aware that this library
always picks the most customary (according to the Unicode Standard) reading for
mainland China. The next version of the Hanzi module will provide more options
to deal with this situation.

## License

MIT
