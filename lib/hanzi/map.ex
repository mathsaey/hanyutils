defmodule Hanzi.Map do
  @moduledoc false
  # lookup/1 is implemented by generating clauses for each hanzi defined by the unicode standard.
  # Therefore, compiling this module does take some time.

  @doc """
  Obtain the `t:Hanzi.t/0` struct for a given character.
  """
  def lookup(character)

  __DIR__
  |> Path.join("characters.map")
  |> File.stream!()
  |> Stream.drop_while(&String.starts_with?(&1, ["#", "\n"]))
  |> Stream.map(&String.split/1)
  |> Stream.map(fn [c, t | entries] -> {c, t, Enum.map(entries, &Pinyin.from_marked!/1)} end)
  |> Stream.map(fn
    {c, "p", [p]} -> %{char: c, pron: p}
    {c, "p", [pm, pt]} -> %{char: c, pron: pm, pron_tw: pt}
    {c, "a", a} -> %{char: c, alt: a}
  end)
  |> Stream.chunk_by(& &1.char)
  |> Stream.map(fn
    [left, right] -> Map.merge(left, right)
    [single] -> single
  end)
  |> Stream.map(fn
    # If alt only repeats the most common pronunciation we drop it
    m = %{pron: p, alt: [p]} -> Map.delete(m, :alt)
    # Don't modify entries with both pronunciation and alt after this point
    t = %{char: _, alt: _, pron: _} -> t
    # Words that occur only in kHanyuPinyin
    %{char: c, alt: [p]} -> %{char: c, pron: p}
    # Words that occur only in kHanyuPinyin with multiple pronunciations
    m = %{alt: [p | _]} -> Map.put(m, :pron, p)
    # Entries with only pronunciation remain unmodified, use this instead of a catch-all clause
    # to prevent bugs
    t = %{char: _, pron: _} -> t
  end)
  |> Enum.map(&struct(Hanzi, &1))
  |> Enum.map(fn s = %Hanzi{char: c} ->
    def lookup(unquote(c)), do: unquote(Macro.escape(s))
  end)

  # For using during development
  # |> Enum.map(fn s = %{char: c} ->
  #   def lookup(unquote(c)), do: struct(Hanzi, unquote(Macro.escape(s)))
  # end)

  def lookup(_), do: nil
end
