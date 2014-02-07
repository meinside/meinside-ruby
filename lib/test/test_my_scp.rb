#!/usr/bin/env ruby
# coding: UTF-8

# lib/test/test_my_scp.rb
# 
# test my_scp
# 
# created on : 2008.11.27
# last update: 2013.02.28
# 
# by meinside@gmail.com

require 'test/unit'

require_relative "../my_scp"
require_relative "../my_util"

LOCAL_TEST_DIR = File.expand_path("~/scp_test")
LOCAL_TEST_FILE = File.join(LOCAL_TEST_DIR, "test.txt")

class TestMyScp < Test::Unit::TestCase

  include MyUtil

  def setup
    @test_server = prompt("> remote server addr(ex: test.server.com): ")
    @test_id = prompt("> remote server user id: ")
    @test_passwd = prompt("> remote server user password: ", "*")
    @remote_test_dir = prompt("> remote test dir(ex: /home/test/test_dir/): ")

    `mkdir -p '#{LOCAL_TEST_DIR}'`
    `touch '#{LOCAL_TEST_FILE}'`
  end

  def test_all
    MyScp.new(@test_server, true).connect(@test_id, @test_passwd){|conn|
      assert(conn.upload(File.dirname(@remote_test_dir), LOCAL_TEST_DIR))
      assert(conn.download(@remote_test_dir, File.dirname(LOCAL_TEST_DIR)))
    }
  end

  def teardown
    `rm -rf '#{LOCAL_TEST_DIR}'`
  end

end

