#!/usr/bin/env ruby
# coding: UTF-8

# lib/test/test_my_oauth.rb
# 
# test my_oauth
# 
# created on : 2012.07.09
# last update: 2015.01.16
# 
# by meinside@gmail.com

require 'test/unit'

require_relative "../my_oauth"
require_relative "../my_util"

class TestMyOAuth < Test::Unit::TestCase

  include MyUtil

  def setup
    @request_token_url = prompt("> request token url(ex: https://api.twitter.com/oauth/request_token): ")
    @authorize_url = prompt("> authorize url(ex: https://api.twitter.com/oauth/authorize): ")
    @access_token_url = prompt("> access token url(ex: https://api.twitter.com/oauth/access_token): ")

    @consumer_key = prompt("> consumer key(ex: AaBbCcDdEeXxYyZz): ")
    @consumer_secret = prompt("> consumer secret(ex: Aa0Bb1Cc2Dd3Ee4Ff5Gg6Hh7Ii8): ", true)

    @oauth = MyOAuth.new(@consumer_key, @consumer_secret, @request_token_url, @access_token_url, @authorize_url)
  end

  def test_all
    user_auth_url = @oauth.get_user_auth_url

    assert_not_nil(user_auth_url)

    puts "* authorize yourself in the following url: #{user_auth_url}\nand provide oauth_verifier(PIN)"
    oauth_verifier = prompt("> PIN: ")

    assert(@oauth.authorize(oauth_verifier))
  end

  def teardown
    # do nothing
  end
end
