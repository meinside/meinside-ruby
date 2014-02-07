#!/usr/bin/env ruby
# coding: UTF-8

# lib/test/test_my_sftp.rb
# 
# test my_sftp
# 
# created on : 2008.11.19
# last update: 2013.02.28
# 
# by meinside@gmail.com

require 'test/unit'

require_relative "../my_sftp"

LOCAL_TEST_DIR = File.expand_path("~/sftp_test/")
LOCAL_TEMP_FILE = "/tmp/test.txt"

class TestMySftp < Test::Unit::TestCase

  include MyUtil

  def test_all
    # without block
    sftp = MySftp.new(@test_server, @test_port, false)
    assert(!sftp.connected?)
    assert_not_nil(sftp.connect(@test_id, @test_passwd))
    assert(sftp.connected?)
    assert_not_nil(sftp.mkdir(@remote_test_dir))
    assert_not_nil(sftp.upload(__FILE__, @remote_test_file))
    assert_not_nil(sftp.download(@remote_test_file, LOCAL_TEMP_FILE))
    assert_not_nil(sftp.rm(@remote_test_file))
    assert_not_nil(sftp.rmdir(@remote_test_dir))
    sftp.disconnect
    assert(!sftp.connected?)

    # with block
    sftp = MySftp.new(@test_server, @test_port, false)
    assert(!sftp.connected?)
    sftp.connect(@test_id, @test_passwd){|conn|
      assert_not_nil(conn.mkdir(@remote_test_dir))
      assert_not_nil(conn.upload(__FILE__, @remote_test_file))
      assert_not_nil(conn.download(@remote_test_file, LOCAL_TEMP_FILE))
      assert_not_nil(conn.rm(@remote_test_file))
      assert_not_nil(conn.rmdir(@remote_test_dir))
    }
    assert(!sftp.connected?)
  end

  def setup
    @test_server = prompt("> remote server addr(ex: test.server.com): ")
    @test_port = prompt("> remote server port(ex: 22): ")
    @test_id = prompt("> remote server user id: ")
    @test_passwd = prompt("> remote server user password: ", "*")
    @remote_test_dir = prompt("> remote test dir(ex: /home/test/test_dir/): ")
    @remote_test_file = File.join(@remote_test_dir, "test.txt")
  end

  def teardown
    `rm -rf '#{LOCAL_TEMP_FILE}'`
  end
end

