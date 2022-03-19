defmodule PinyinTest do
  use ExUnit.Case
  import Pinyin
  doctest Pinyin

  test "Uncommon standalone finals" do
    assert Pinyin.from_marked("ng") == %Pinyin{tone: 0, initial: "", final: "ng"}
    assert Pinyin.from_marked("hng") == %Pinyin{tone: 0, initial: "", final: "hng"}
    assert Pinyin.from_marked("hm") == %Pinyin{tone: 0, initial: "", final: "hm"}
    assert Pinyin.from_marked("wong") == %Pinyin{tone: 0, initial: "", final: "wong"}
    assert Pinyin.from_marked("ê") == %Pinyin{tone: 0, initial: "", final: "ê"}
  end

  test "Uncommon standalone finals with tone marks" do
    # TODO: Implement ng tone mark
    # assert Pinyin.from_marked("ňg") == %Pinyin{tone: 3, initial: "", final: "ng"}
    # assert Pinyin.from_marked("ńg") == %Pinyin{tone: 2, initial: "", final: "ng"}
    assert Pinyin.from_marked("ê") == %Pinyin{tone: 0, initial: "", final: "ê"}
    assert Pinyin.from_marked("ê̄") == %Pinyin{tone: 1, initial: "", final: "ê"}
    assert Pinyin.from_marked("ế") == %Pinyin{tone: 2, initial: "", final: "ê"}
    assert Pinyin.from_marked("ê̌") == %Pinyin{tone: 3, initial: "", final: "ê"}
    assert Pinyin.from_marked("ề") == %Pinyin{tone: 4, initial: "", final: "ê"}
  end
end
