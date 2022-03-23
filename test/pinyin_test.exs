defmodule PinyinTest do
  use ExUnit.Case
  import Pinyin
  doctest Pinyin

  describe "marked" do
    test "standard standalone words" do
      assert Pinyin.marked(~p/huan1/s) == "huān"
      assert Pinyin.marked(~p/piao2/s) == "piáo"
      assert Pinyin.marked(~p/peng3/s) == "pěng"
      assert Pinyin.marked(~p/shuo4/s) == "shuò"
      assert Pinyin.marked(~p/shui1/s) == "shuī"
      assert Pinyin.marked(~p/niu2/s) == "niú"
      assert Pinyin.marked(~p/shi3/s) == "shǐ"
      assert Pinyin.marked(~p/lv4/s) == "lǜ"
    end

    test "uppercase standalone words" do
      assert Pinyin.marked(~p/HUAN1/s) == "HUĀN"
      assert Pinyin.marked(~p/PIAO2/s) == "PIÁO"
      assert Pinyin.marked(~p/PENG3/s) == "PĚNG"
      assert Pinyin.marked(~p/SHUO4/s) == "SHUÒ"
      assert Pinyin.marked(~p/SHUI1/s) == "SHUĪ"
      assert Pinyin.marked(~p/NIU2/s) == "NIÚ"
      assert Pinyin.marked(~p/SHI3/s) == "SHǏ"
      assert Pinyin.marked(~p/LV4/s) == "LǛ"
    end

    test "words with v" do
      assert Pinyin.marked(~p/lv4/s) == "lǜ"
      assert Pinyin.marked(~p/lve4/s) == "lüè"
      assert Pinyin.marked(~p/LV4/s) == "LǛ"
      assert Pinyin.marked(~p/LVE4/s) == "LÜÈ"
    end

    test "uncommon cases" do
      assert Pinyin.marked(~p/m1/s) == "m̄"
      assert Pinyin.marked(~p/n2/s) == "ń"
      assert Pinyin.marked(~p/ng3/s) == "ňg"
      assert Pinyin.marked(~p/ê4/s) == "ề"

      assert Pinyin.marked(~p/M1/s) == "M̄"
      assert Pinyin.marked(~p/N2/s) == "Ń"
      assert Pinyin.marked(~p/Ng3/s) == "Ňg"
      assert Pinyin.marked(~p/NG3/s) == "ŇG"
      assert Pinyin.marked(~p/Ê4/s) == "Ề"
    end
  end

  describe "read_marked" do
    test "uncommon standalone finals" do
      assert Pinyin.from_marked!("ng") == %Pinyin{tone: 0, initial: "", final: "ng"}
      assert Pinyin.from_marked!("hng") == %Pinyin{tone: 0, initial: "", final: "hng"}
      assert Pinyin.from_marked!("hm") == %Pinyin{tone: 0, initial: "", final: "hm"}
      assert Pinyin.from_marked!("wong") == %Pinyin{tone: 0, initial: "", final: "wong"}
      assert Pinyin.from_marked!("ê") == %Pinyin{tone: 0, initial: "", final: "ê"}
    end

    test "uncommon standalone finals with tone marks" do
      assert Pinyin.from_marked!("ńg") == %Pinyin{tone: 2, initial: "", final: "ng"}
      assert Pinyin.from_marked!("ňg") == %Pinyin{tone: 3, initial: "", final: "ng"}
      assert Pinyin.from_marked!("ǹg") == %Pinyin{tone: 4, initial: "", final: "ng"}
      assert Pinyin.from_marked!("ê") == %Pinyin{tone: 0, initial: "", final: "ê"}
      assert Pinyin.from_marked!("ê̄") == %Pinyin{tone: 1, initial: "", final: "ê"}
      assert Pinyin.from_marked!("ế") == %Pinyin{tone: 2, initial: "", final: "ê"}
      assert Pinyin.from_marked!("ê̌") == %Pinyin{tone: 3, initial: "", final: "ê"}
      assert Pinyin.from_marked!("ề") == %Pinyin{tone: 4, initial: "", final: "ê"}
    end
  end
end
