#!/usr/bin/env ruby
# coding: UTF-8

# lib/test/test_my_http.rb
# 
# test my_http
# 
# created on : 2008.11.05
# last update: 2013.02.28
# 
# by meinside@gmail.com

require 'test/unit'

require_relative '../my_http'

WRONG_URL = "http://something.is.wrong/"
GOOD_URL = "http://www.google.com"
SOME_URL_THAT_MANAGES_GET = "http://www.google.com"
SOME_URL_THAT_MANAGES_POST = "http://www.snee.com/xml/crud/posttest.cgi"

class TestMyHttp < Test::Unit::TestCase

  def test_get

    # bad url
    result = MyHttp.get(WRONG_URL)
    assert_nil(result)

    # good url
    result = MyHttp.get(GOOD_URL)
    assert_not_nil(result)

    # url with extra parameters/headers as hash
    result = MyHttp.get(
      SOME_URL_THAT_MANAGES_GET, 
      {"q" => "test", "hl" => "ko",},
      {"Some-Header-Value" => "Nothing",})
    assert_not_nil(result)

  end

  def test_post

    # bad url
    result = MyHttp.post(WRONG_URL)
    assert_nil(result)

    # good url
    result = MyHttp.post(GOOD_URL)
    assert_not_nil(result)	# needs 'Content-length' header

    # url with extra parameters/headers as hash
    result = MyHttp.post(
      SOME_URL_THAT_MANAGES_POST, 
      {"fname" => "Test Value 1", "lname" => "Test Value 2",},
      {"Some-Header-Value" => "Nothing",})
    assert_not_nil(result)

  end

end

