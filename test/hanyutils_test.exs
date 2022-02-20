defmodule HanyutislTest do
  use ExUnit.Case
  doctest Hanyutils

  describe "Full sentence" do
    test "To Zhuyin" do
      assert Hanyutils.to_zhuyin("你好。我是你的哥哥") ==
               "ㄋㄧˇㄏㄠˇ。ㄨㄛˇㄕㄧˋㄋㄧˇㄉㄝ˙ㄍㄝㄍㄝ"
    end

    test "To PinYin" do
      assert Hanyutils.to_marked_pinyin("你好。我是你的哥哥") ==
               "nǐhǎo。wǒshìnǐdegēgē"
    end
  end

  describe "Full sentence with other characters" do
    test "To Zhuyin" do
      assert Hanyutils.to_zhuyin("你好 Daniel。我是你的哥哥。我 25 歲") ==
               "ㄋㄧˇㄏㄠˇ Daniel。ㄨㄛˇㄕㄧˋㄋㄧˇㄉㄝ˙ㄍㄝㄍㄝ。ㄨㄛˇ 25 ㄙㄨㄟˋ"
    end

    test "To PinYin" do
      assert Hanyutils.to_marked_pinyin("你好 Daniel。我是你的哥哥。我 25 歲") ==
               "nǐhǎo Daniel。wǒshìnǐdegēgē。wǒ 25 suì"
    end
  end
end
