defmodule HanyutislTest do
  use ExUnit.Case
  doctest Hanyutils

  describe "full sentence" do
    test "to zhuyin" do
      assert Hanyutils.to_zhuyin("你好。我是你的哥哥") == "ㄋㄧˇㄏㄠˇ。ㄨㄛˇㄕˋㄋㄧˇㄉㄝ˙ㄍㄝㄍㄝ"
    end

    test "to pinyin" do
      assert Hanyutils.to_marked_pinyin("你好。我是你的哥哥") == "nǐhǎo。wǒshìnǐdegēgē"
    end
  end

  describe "full sentence with other characters" do
    test "to zhuyin" do
      assert Hanyutils.to_zhuyin("你好 Daniel。我是你的哥哥。我 25 歲") ==
               "ㄋㄧˇㄏㄠˇ Daniel。ㄨㄛˇㄕˋㄋㄧˇㄉㄝ˙ㄍㄝㄍㄝ。ㄨㄛˇ 25 ㄙㄨㄟˋ"
    end

    test "to pinyin" do
      assert Hanyutils.to_marked_pinyin("你好 Daniel。我是你的哥哥。我 25 歲") ==
               "nǐhǎo Daniel。wǒshìnǐdegēgē。wǒ 25 suì"
    end
  end

  test "standalone finals that look like initial and final" do
    # These fail if the pinyin parser parses the pronunciation as initial and final because
    # it will generate ㄧ during conversion to Zhuyin.
    # ci is not ㄘㄧˋ
    assert Hanyutils.to_zhuyin("次") == "ㄘˋ"
    # zi is not ㄗㄧˋ
    assert Hanyutils.to_zhuyin("自") == "ㄗˋ"
    # si is not ㄙㄧˋ
    assert Hanyutils.to_zhuyin("四") == "ㄙˋ"
    # zhi is not ㄓㄧ
    assert Hanyutils.to_zhuyin("之") == "ㄓ"
    # chi is not  ㄔㄧ
    assert Hanyutils.to_zhuyin("吃") == "ㄔ"
    # shi is not ㄕㄧˋ
    assert Hanyutils.to_zhuyin("是") == "ㄕˋ"
    # ri is not ㄖㄧˋ
    assert Hanyutils.to_zhuyin("日") == "ㄖˋ"
  end
end
