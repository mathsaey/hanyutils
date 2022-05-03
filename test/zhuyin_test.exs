defmodule ZhuyinTest do
  use ExUnit.Case
  import Zhuyin
  import Pinyin
  doctest Zhuyin

  describe "read" do
    test "full syllables" do
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
        # Pinyin parser can't parse r right now.
        # ㄦ/兒 in first tone is just "r" in pinyin
        # {"ㄦ˙", ~p/r0/}
      ]

      Enum.each(tests, fn {z, p} -> assert Zhuyin.read!(z) |> Zhuyin.to_pinyin() == p end)
    end

    test "incomplete syllables" do
      tests = ~w(ㄝ ㄐˇ)
      Enum.each(tests, fn z -> assert Zhuyin.read(z) == {:error, z} end)
    end

    test "regular standalone initials" do
      assert Zhuyin.read!("ㄋㄧˇ") == [%Zhuyin{initial: "ㄋ", final: "ㄧ", tone: 3}]
    end

    test "exclusive mode" do
      assert Zhuyin.read("ㄕㄧˇ", :exclusive) == {:ok, [~z/ㄕ/s, ~z/ㄧˇ/s]}
      assert Zhuyin.read("ㄋㄧˇㄏㄠˇ", :exclusive) == {:ok, [~z/ㄋㄧˇ/s, ~z/ㄏㄠˇ/s]}
    end

    test "exclusive mode does not accept mixed strings" do
      assert Zhuyin.read("ㄋㄧˇhao", :exclusive) == {:error, "ㄋㄧˇhao"}
    end

    test "can parse multiple words with one or more syllables" do
      assert Zhuyin.read("ㄋㄧˇㄏㄠˇㄨˇ ㄕˋ ㄋㄧˇ ㄍㄜㄍㄜ˙", :exclusive) ==
               {:ok,
                [
                  ~z/ㄋㄧˇ/s,
                  ~z/ㄏㄠˇ/s,
                  ~z/ㄨˇ/s,
                  " ",
                  ~z/ㄕˋ/s,
                  " ",
                  ~z/ㄋㄧˇ/s,
                  " ",
                  ~z/ㄍㄜ/s,
                  ~z/ㄍㄜ˙/s
                ]}
    end

    test "mixed strings" do
      assert Zhuyin.read!("test ㄓㄨyu", :mixed) |> Zhuyin.to_pinyin() |> Pinyin.marked() ==
               "test zhūyu"
    end
  end

  describe "from_string" do
    test "only parses a single syllable" do
      assert Zhuyin.from_string("ㄋㄧˇㄏㄠˇ") == {:error, "ㄏㄠˇ"}
    end

    test "works for syllables with initial, final and tone" do
      assert Zhuyin.from_string("ㄋㄧˇ") == {:ok, %Zhuyin{initial: "ㄋ", final: "ㄧ", tone: 3}}
    end

    test "works for syllables with initial, final and no tone" do
      assert Zhuyin.from_string("ㄋㄧ") == {:ok, %Zhuyin{initial: "ㄋ", final: "ㄧ", tone: 1}}
    end

    test "works for standalone finals" do
      assert Zhuyin.from_string("ㄧ") == {:ok, %Zhuyin{initial: "", final: "ㄧ", tone: 1}}
    end

    test "doesn't work for characters that are not standalone finals" do
      assert Zhuyin.from_string("ㄋ") == {:error, "ㄋ"}
    end

    test "does not allow standalone initials to be combined with a final" do
      assert Zhuyin.from_string("ㄕㄧˇ") == {:error, "ㄧˇ"}
    end
  end
end
