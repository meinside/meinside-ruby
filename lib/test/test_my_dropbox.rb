#!/usr/bin/env ruby
# coding: UTF-8

# lib/test/test_my_dropbox.rb
# 
# test my_dropbox
# 
# created on : 2013.02.07
# last update: 2015.01.16
# 
# by meinside@gmail.com

require 'test/unit'

require_relative "../my_dropbox"

require_relative "../my_util"
require_relative "../my_str"

class TestMyDropbox < Test::Unit::TestCase

  include MyUtil

  def setup
    @temp_dir = File.expand_path("./temp_test_my_dropbox")
    `mkdir '#{@temp_dir}'`
  end

  def test_dropbox
    # get connection info
    config = prompt("> dropbox config file's path (enter for none): ")
    if config.length > 0 && File.exists?(File.expand_path(config))
      assert(@dropbox = MyDropbox.new(config_file: config))
    else
      app_key = prompt("> dropbox app key: ")
      app_secret = prompt("> dropbox app secret: ", true)
      access_token = prompt("> dropbox access token: ")
      access_secret = prompt("> dropbox access secret: ", true)
      access_type = prompt("> dropbox access type (dropbox / app_folder): ")

      assert(@dropbox = MyDropbox.new(app_key: app_key, app_secret: app_secret, access_token: access_token, access_secret: access_secret, access_type: (access_type =~ /dropbox/i ? :dropbox : :app_folder)))

      temp_dir = File.basename(@temp_dir)
      temp_file = "test.txt"

      assert_not_nil(@dropbox.mkdir(temp_dir))
      assert_not_nil(@dropbox.put(__FILE__, temp_dir + "/" + temp_file))
      assert_not_nil(@dropbox.get(temp_dir + "/" + temp_file, @temp_dir + "/" + temp_file))
      assert_not_nil(@dropbox.cp(temp_dir + "/" + temp_file, temp_dir + "/" + temp_file + ".copied"))
      assert_not_nil(@dropbox.mv(temp_dir + "/" + temp_file + ".copied", temp_dir + "/" + temp_file + ".moved"))
      assert_not_nil(@dropbox.ls(temp_dir))
      assert_not_nil(@dropbox.rm(temp_dir))
    end
  end

  def teardown
    `rm -rf '#{@temp_dir}'`
  end

end

