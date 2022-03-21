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

    test "upper case characters" do
      assert Pinyin._mark("A", 1) == "Ā"
      assert Pinyin._mark("A", 2) == "Á"
      assert Pinyin._mark("A", 3) == "Ǎ"
      assert Pinyin._mark("A", 4) == "À"

      assert Pinyin._mark("E", 1) == "Ē"
      assert Pinyin._mark("E", 2) == "É"
      assert Pinyin._mark("E", 3) == "Ě"
      assert Pinyin._mark("E", 4) == "È"

      assert Pinyin._mark("I", 1) == "Ī"
      assert Pinyin._mark("I", 2) == "Í"
      assert Pinyin._mark("I", 3) == "Ǐ"
      assert Pinyin._mark("I", 4) == "Ì"

      assert Pinyin._mark("O", 1) == "Ō"
      assert Pinyin._mark("O", 2) == "Ó"
      assert Pinyin._mark("O", 3) == "Ǒ"
      assert Pinyin._mark("O", 4) == "Ò"

      assert Pinyin._mark("U", 1) == "Ū"
      assert Pinyin._mark("U", 2) == "Ú"
      assert Pinyin._mark("U", 3) == "Ǔ"
      assert Pinyin._mark("U", 4) == "Ù"

      assert Pinyin._mark("Ü", 1) == "Ǖ"
      assert Pinyin._mark("Ü", 2) == "Ǘ"
      assert Pinyin._mark("Ü", 3) == "Ǚ"
      assert Pinyin._mark("Ü", 4) == "Ǜ"
    end

    test "special cases" do
      assert Pinyin._mark("ê", 1) == "ê̄"
      assert Pinyin._mark("ê", 2) == "ế"
      assert Pinyin._mark("ê", 3) == "ê̌"
      assert Pinyin._mark("ê", 4) == "ề"

      assert Pinyin._mark("n", 1) == "n̄"
      assert Pinyin._mark("n", 2) == "ń"
      assert Pinyin._mark("n", 3) == "ň"
      assert Pinyin._mark("n", 4) == "ǹ"

      assert Pinyin._mark("m", 1) == "m̄"
      assert Pinyin._mark("m", 2) == "ḿ"
      assert Pinyin._mark("m", 3) == "m̌"
      assert Pinyin._mark("m", 4) == "m̀"

      assert Pinyin._mark("Ê", 1) == "Ê̄"
      assert Pinyin._mark("Ê", 2) == "Ế"
      assert Pinyin._mark("Ê", 3) == "Ê̌"
      assert Pinyin._mark("Ê", 4) == "Ề"

      assert Pinyin._mark("N", 1) == "N̄"
      assert Pinyin._mark("N", 2) == "Ń"
      assert Pinyin._mark("N", 3) == "Ň"
      assert Pinyin._mark("N", 4) == "Ǹ"

      assert Pinyin._mark("M", 1) == "M̄"
      assert Pinyin._mark("M", 2) == "Ḿ"
      assert Pinyin._mark("M", 3) == "M̌"
      assert Pinyin._mark("M", 4) == "M̀"
    end

    test "does not modify other characters" do
      assert Pinyin._mark("x", 4) == "x"
    end

    test "neutral tone" do
      assert Pinyin._mark("a", 0) == "a"
    end

    test "results in the shortest possible string" do
      for char <- ~w(a e i o u ü A E I O U Ü), idx <- 1..4 do
        marked = Pinyin._mark(char, idx)
        assert String.codepoints(marked) == String.graphemes(marked)
      end
    end
  end

  describe "mark" do
    test "standard standalone words" do
      assert Pinyin.marked(Pinyin.create("h", "uan", 1)) == "huān"
      assert Pinyin.marked(Pinyin.create("p", "iao", 2)) == "piáo"
      assert Pinyin.marked(Pinyin.create("p", "eng", 3)) == "pěng"
      assert Pinyin.marked(Pinyin.create("sh", "uo", 4)) == "shuò"
      assert Pinyin.marked(Pinyin.create("sh", "ui", 1)) == "shuī"
      assert Pinyin.marked(Pinyin.create("n", "iu", 2)) == "niú"
      assert Pinyin.marked(Pinyin.create("sh", "i", 3)) == "shǐ"
      assert Pinyin.marked(Pinyin.create("l", "ü", 4)) == "lǜ"
    end

    test "uppercase standalone words" do
      assert Pinyin.marked(Pinyin.create("H", "UAN", 1)) == "HUĀN"
      assert Pinyin.marked(Pinyin.create("P", "IAO", 2)) == "PIÁO"
      assert Pinyin.marked(Pinyin.create("P", "ENG", 3)) == "PĚNG"
      assert Pinyin.marked(Pinyin.create("SH", "UO", 4)) == "SHUÒ"
      assert Pinyin.marked(Pinyin.create("SH", "UI", 1)) == "SHUĪ"
      assert Pinyin.marked(Pinyin.create("N", "IU", 2)) == "NIÚ"
      assert Pinyin.marked(Pinyin.create("SH", "I", 3)) == "SHǏ"
      assert Pinyin.marked(Pinyin.create("L", "Ü", 4)) == "LǛ"
    end

    test "words with v" do
      assert Pinyin.marked(Pinyin.create("l", "v", 4)) == "lǜ"
      assert Pinyin.marked(Pinyin.create("l", "ve", 4)) == "lüè"
      assert Pinyin.marked(Pinyin.create("L", "V", 4)) == "LǛ"
      assert Pinyin.marked(Pinyin.create("L", "VE", 4)) == "LÜÈ"
    end

    test "uncommon cases" do
      assert Pinyin.marked(Pinyin.create("", "m", 1)) == "m̄"
      assert Pinyin.marked(Pinyin.create("", "n", 2)) == "ń"
      assert Pinyin.marked(Pinyin.create("", "ng", 3)) == "ňg"
      assert Pinyin.marked(Pinyin.create("", "ê", 4)) == "ề"

      assert Pinyin.marked(Pinyin.create("", "M", 1)) == "M̄"
      assert Pinyin.marked(Pinyin.create("", "N", 2)) == "Ń"
      assert Pinyin.marked(Pinyin.create("", "Ng", 3)) == "Ňg"
      assert Pinyin.marked(Pinyin.create("", "NG", 3)) == "ŇG"
      assert Pinyin.marked(Pinyin.create("", "Ê", 4)) == "Ề"
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
