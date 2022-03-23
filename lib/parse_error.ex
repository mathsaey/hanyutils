defmodule ParseError do
  @moduledoc """
  Error that may be raised when parsing pinyin strings.
  """
  defexception [:message]

  @impl true
  def exception(remainder) do
    msg = "Error occurred when attempting to parse: \"#{remainder}\""
    %__MODULE__{message: msg}
  end
end
