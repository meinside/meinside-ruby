#!/usr/bin/env ruby
# coding: UTF-8

# lib/test/test_my_str.rb
# 
# test my_str
# 
# created on : 2012.06.26
# last update: 2013.02.28
# 
# by meinside@gmail.com

require 'test/unit'

require_relative "../my_str"

class TestMyStr < Test::Unit::TestCase
  def setup
    # do nothing
  end

  def teardown
    # do nothing
  rescue
    # do nothing
  end

  def test_cjk
    assert(!"English".contains_cjk?)
    assert("한글".contains_cjk?)
    assert("漢文".contains_cjk?)
    assert("カタカナ".contains_cjk?)

    assert_equal("English".hangul_syllables, ["E", "n", "g", "l", "i", "s", "h"])
    assert_equal("무한".hangul_syllables, [{onset: "ㅁ", nucleus: "ㅜ"}, {onset: "ㅎ", nucleus: "ㅏ", coda: "ㄴ"}])
    assert_equal("계".hangul_syllables, [{onset: "ㄱ", nucleus: "ㅖ"}])
  end

  def test_colorizer
    assert_equal("test".colorize(:red), "\e[31mtest\e[0m")
    assert_equal("test 2".colorize(:red), "test 2".colorize(:red))
    assert_equal("test 3".colorize(:red, :blue_bg), "test 3".colorize(:red, :blue_bg))
    assert_not_equal("test 4".colorize(:red), "test 4".colorize(:blue))
    assert_equal("test 5".colorize(:no_such_color), "test 5".colorize(:default))
  end

  def test_md5
    # test md5
    assert_equal("098f6bcd4621d373cade4e832627b4f6", "test".md5)
    assert_equal("some_string".md5, "some_string".md5)
    assert_not_equal("some_string".md5, "some_other_string".md5)
  end

  def test_aes_encrypt_decrypt
    # (ECB - without initial vector)
    key = "0123456789abcdef0123456789abcdef"
    assert_equal("test", "test".aes_encrypt(key).aes_decrypt(key))
    assert_equal("test".aes_encrypt(key).base64encode, "dQvVpMGPSPL8zCxGByAGIg==")

    # (CBC - with initial vector)
    iv = "abcdef0123456789abcdef0123456789"
    assert_equal("test", "test".aes_encrypt(key, {iv: iv, option: :cbc}).aes_decrypt(key, {iv: iv, option: :cbc}))
    assert_equal("test".aes_encrypt(key, {iv: iv, option: :cbc}).base64encode, "KRCvNKY+BPy7gW5hekKaQA==")
  end

  def test_urlencode
    # test url encode/decode
    assert_equal("something ?!^&*()[]{}", 
                 "something ?!^&*()[]{}".urlencode.urldecode)
  end

  def test_base64
    # test base64 encode/decode
    assert_equal("something more ?!^&*()[]{}", 
                 "something more ?!^&*()[]{}".base64encode.base64decode)
  end

  def test_strip_tags

    # remove all html tags
    assert_equal("no tags left", 
                 "<b>no tags left</b><br/>".strip_tags)

    # remove selected html tags only
    assert_equal("<b>no tags left here</b><br/>", 
                 "<b>no tags left <a href='#'>here</a></b><br/>".strip_tags(["br","b"]))
  end
end
