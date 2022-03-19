defmodule Pinyin.Char do
  @moduledoc false
  # Generate functions to map characters to marked characters at compile time

  lower_tone_map = %{
    "a" => ~w(ā á ǎ à),
    "e" => ~w(ē é ě è),
    "i" => ~w(ī í ǐ ì),
    "o" => ~w(ō ó ǒ ò),
    "u" => ~w(ū ú ǔ ù),
    "ü" => ~w(ǖ ǘ ǚ ǜ),
    "v" => ~w(ǖ ǘ ǚ ǜ),
    # Be careful when selecting these. Some editors (e.g. VS Code has problems selecting these characters as single characters)
    "ê" => ~w(ê̄ ế ê̌ ề)
  }

  upper_tone_map =
    lower_tone_map
    |> Enum.reduce(%{}, fn {char, tones}, map ->
      Map.put(map, String.upcase(char), Enum.map(tones, &String.upcase/1))
    end)

  tone_map = Map.merge(lower_tone_map, upper_tone_map)

  @doc """
  Accept a plain character and return it with a tone marker.
  """
  def with_tone(char, tone)

  @doc """
  Accept a marked character and return a `{plain, tone}` tuple.
  """
  def split(c)

  for {plain, toned_chars} <- tone_map do
    for {tone, idx} <- Enum.with_index(toned_chars, 1) do
      # Add a tone to a character
      def with_tone(unquote(plain), unquote(idx)), do: unquote(tone)

      # ü and v have the same mapped characters, avoid ambiguity
      unless plain == "ü" or plain == "Ü" do
        # Split a tone into its character + index
        def split(unquote(tone)), do: {unquote(plain), unquote(idx)}
      end
    end
  end

  def with_tone(c, _), do: c
  def split(c), do: {c, 0}
end
