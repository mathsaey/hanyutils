defmodule PinyinTest do
  use ExUnit.Case
  import Pinyin
  doctest Pinyin

  describe "_mark" do
    test "standard characters" do
      assert Pinyin._mark("a", 1) == "ā"
      assert Pinyin._mark("a", 2) == "á"
      assert Pinyin._mark("a", 3) == "ǎ"
      assert Pinyin._mark("a", 4) == "à"

      assert Pinyin._mark("e", 1) == "ē"
      assert Pinyin._mark("e", 2) == "é"
      assert Pinyin._mark("e", 3) == "ě"
      assert Pinyin._mark("e", 4) == "è"

      assert Pinyin._mark("i", 1) == "ī"
      assert Pinyin._mark("i", 2) == "í"
      assert Pinyin._mark("i", 3) == "ǐ"
      assert Pinyin._mark("i", 4) == "ì"

      assert Pinyin._mark("o", 1) == "ō"
      assert Pinyin._mark("o", 2) == "ó"
      assert Pinyin._mark("o", 3) == "ǒ"
      assert Pinyin._mark("o", 4) == "ò"

      assert Pinyin._mark("u", 1) == "ū"
      assert Pinyin._mark("u", 2) == "ú"
      assert Pinyin._mark("u", 3) == "ǔ"
      assert Pinyin._mark("u", 4) == "ù"

      assert Pinyin._mark("ü", 1) == "ǖ"
      assert Pinyin._mark("ü", 2) == "ǘ"
      assert Pinyin._mark("ü", 3) == "ǚ"
      assert Pinyin._mark("ü", 4) == "ǜ"
    end

    test "special cases" do
      assert Pinyin._mark("n", 1) == "n̄"
      assert Pinyin._mark("n", 2) == "ń"
      assert Pinyin._mark("n", 3) == "ň"
      assert Pinyin._mark("n", 4) == "ǹ"

      assert Pinyin._mark("m", 1) == "m̄"
      assert Pinyin._mark("m", 2) == "ḿ"
      assert Pinyin._mark("m", 3) == "m̌"
      assert Pinyin._mark("m", 4) == "m̀"
    end

    test "results in the shortest possible string" do
      for char <- ~w(a e i o u ü), idx <- 1..4 do
        marked = Pinyin._mark(char, idx)
        assert String.codepoints(marked) == String.graphemes(marked)
      end
    end
  end


  test "Uncommon standalone finals" do
    assert Pinyin.from_marked("ng") == %Pinyin{tone: 0, initial: "", final: "ng"}
    assert Pinyin.from_marked("hng") == %Pinyin{tone: 0, initial: "", final: "hng"}
    assert Pinyin.from_marked("hm") == %Pinyin{tone: 0, initial: "", final: "hm"}
    assert Pinyin.from_marked("wong") == %Pinyin{tone: 0, initial: "", final: "wong"}
    assert Pinyin.from_marked("ê") == %Pinyin{tone: 0, initial: "", final: "ê"}
  end

  test "Uncommon standalone finals with tone marks" do
    assert Pinyin.from_marked("ng") == %Pinyin{tone: 0, initial: "", final: "ng"}
    # There's no ng with first tone
    assert Pinyin.from_marked("ńg") == %Pinyin{tone: 2, initial: "", final: "ng"}
    assert Pinyin.from_marked("ňg") == %Pinyin{tone: 3, initial: "", final: "ng"}
    assert Pinyin.from_marked("ǹg") == %Pinyin{tone: 4, initial: "", final: "ng"}
    assert Pinyin.from_marked("ê") == %Pinyin{tone: 0, initial: "", final: "ê"}
    assert Pinyin.from_marked("ê̄") == %Pinyin{tone: 1, initial: "", final: "ê"}
    assert Pinyin.from_marked("ế") == %Pinyin{tone: 2, initial: "", final: "ê"}
    assert Pinyin.from_marked("ê̌") == %Pinyin{tone: 3, initial: "", final: "ê"}
    assert Pinyin.from_marked("ề") == %Pinyin{tone: 4, initial: "", final: "ê"}
  end
end
