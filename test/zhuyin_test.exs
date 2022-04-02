defmodule ZhuyinTest do
  use ExUnit.Case
  import Zhuyin
  import Zhuyin.Parsers
  import Pinyin
  doctest Zhuyin

  describe "Decode Zhuyin" do
    test "Full syllables" do
      tests = [
        {"ㄐㄩ˙", ~p/jv/},
        {"ㄌㄩˇ", ~p/lv3/},
        {"ㄓㄠˊ", ~p/zhao2/},
        {"ㄓˋ", ~p/zhi4/},
        {"ㄌㄥ", ~p/leng1/},
        {"ㄕㄨㄟˇ", ~p/shui3/},
        {"ㄌㄧㄡˊ", ~p/liu2/},
        {"ㄧˊ", ~p/yi2/},
        {"ㄇㄧㄣˊ", ~p/min2/},
        {"ㄨㄥˊ", ~p/weng2/},
        {"ㄨˊ", ~p/wu2/},
        {"ㄩ", ~p/yu1/},
        {"ㄩㄝˇ", ~p/yue3/},
        {"ㄩㄝˋ", ~p/yue4/},
        {"ㄩㄢˊ", ~p/yuan2/},
        {"ㄌㄩㄢˋ", ~p/lvan4/},
        {"ㄌㄢˇ", ~p/lan3/},
        {"ㄦˊ", ~p/er2/}
        # {"ㄦ˙", ~p/r0/}
      ]

      Enum.each(tests, fn {z, p} -> assert Zhuyin.read!(z) |> Zhuyin.to_pinyin() == p end)
    end

    test "Incomplete syllables" do
      tests = [
        "ㄝ",
        "ㄐˇ"
      ]

      Enum.each(tests, fn z -> assert Zhuyin.read(z) == {:error, z} end)
    end
  end

  describe "Syllable parser" do
    test "Syllable parser parses only a single syllable" do
      {:error, "expected end of string", "ㄏㄠˇ", %{}, {1, 0}, 8} =
        Zhuyin.Parsers.syllable("ㄋㄧˇㄏㄠˇ")
    end

    test "Works for syllable with initial, final and tone" do
      {:ok, [%Zhuyin{initial: "ㄋ", final: "ㄧ", tone: 3}], "", %{}, {1, 0}, 8} =
        Zhuyin.Parsers.syllable("ㄋㄧˇ")
    end

    test "Works for syllable with initial and final, no tone" do
      {:ok, [%Zhuyin{initial: "ㄋ", final: "ㄧ", tone: 1}], "", %{}, {1, 0}, 6} =
        Zhuyin.Parsers.syllable("ㄋㄧ")
    end

    test "Works for standalone final" do
      {:ok, [%Zhuyin{initial: "", final: "ㄧ", tone: 1}], "", %{}, {1, 0}, 3} =
        Zhuyin.Parsers.syllable("ㄧ")
    end

    test "Doesn't work for character that's not a standalone final" do
      {:error, _, "ㄋ", %{}, {1, 0}, 0} = Zhuyin.Parsers.syllable("ㄋ")
    end
  end

  describe "Zhuyin only parser" do
    test "Can parse a full word of two syllables" do
      assert {:ok, [~z/ㄋㄧˇ/, ~z/ㄏㄠˇ/] |> List.flatten(), "", %{}, {1, 0}, 16} ==
               Zhuyin.Parsers.zhuyin_only("ㄋㄧˇㄏㄠˇ")
    end

    test "Doesn't accept mixed strings" do
      {:error, "expected end of string", "ㄋㄧˇhao", %{}, {1, 0}, 0} =
        Zhuyin.Parsers.zhuyin_only("ㄋㄧˇhao")
    end

    test "Can parse a multiple words with one or more syllables." do
      assert {:ok,
              [~z/ㄋㄧˇ/, ~z/ㄏㄠˇ/, ~z/ㄨˇ/, " ", ~z/ㄕˋ/, " ", ~z/ㄋㄧˇ/, " ", ~z/ㄍㄜ/, ~z/ㄍㄜ˙/]
              |> List.flatten(), "", %{}, {1, 0},
              51} ==
               Zhuyin.Parsers.zhuyin_only("ㄋㄧˇㄏㄠˇㄨˇ ㄕˋ ㄋㄧˇ ㄍㄜㄍㄜ˙")
    end
  end

  describe "Mixed parser" do
    test "" do
      pinyin = Zhuyin.read!("test ㄓㄨyu", :mixed) |> Zhuyin.to_pinyin() |> Enum.join()
      assert pinyin == "test zhūyu"
    end
  end
end
