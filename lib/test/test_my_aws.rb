#!/usr/bin/env ruby
# coding: UTF-8

# lib/test/test_my_aws.rb
# 
# test my_aws
# 
# created on : 2012.08.07
# last update: 2015.01.16
# 
# by meinside@gmail.com

require 'test/unit'

require_relative '../my_aws'

require_relative '../my_util'
require_relative '../my_str'

class TestMyAws < Test::Unit::TestCase

  include MyUtil

  def setup
    @temp_dir = File.expand_path("./temp_test_my_aws")
    `mkdir '#{@temp_dir}'`
  end

  def test_s3
    # get connection info
    config = prompt("> s3 config file's path (enter for none): ")
    if config.length > 0 && File.exists?(File.expand_path(config))
      assert(MyAws::S3.config(config_file: config))
    else
      access_key_id = prompt("> s3 access key id: ", true)
      secret_access_key = prompt("> s3 secret access key: ", true)
      assert(MyAws::S3.config(access_key_id: access_key_id, secret_access_key: secret_access_key))
    end

    assert_not_nil(MyAws::S3.buckets)
    MyAws::S3.buckets.each{|bucket|
      assert_not_nil(MyAws::S3.bucket(bucket.name))
    }
    assert_nil(MyAws::S3.bucket("no_such_f**king_bucket"))

    temp_bucket_name = Time.now.to_s.md5
    temp_bucket = MyAws::S3.create_bucket(temp_bucket_name)

    assert_not_nil(temp_bucket)
    assert(temp_bucket.empty?)

    temp_file_name = Time.now.to_s.md5
    assert_not_nil(temp_bucket.objects[temp_file_name].write("test"))
    assert_equal(temp_bucket.objects[temp_file_name].read, "test")

    assert_not_nil(temp_bucket.objects[temp_file_name].write("test", acl: :public_read))	# default acl: :private
    assert_equal(temp_bucket.objects[temp_file_name].read, "test")

    assert_equal(temp_bucket.objects.map{|o| o.key}, [temp_file_name])

    assert(!temp_bucket.empty?)
    temp_bucket.clear!
    assert(temp_bucket.empty?)

    temp_file_path = File.join(@temp_dir, temp_file_name)
    File.open(temp_file_path, "w"){|file|
      file << "file test"
    }
    assert_not_nil(temp_bucket.objects[temp_file_name].write(File.new(temp_file_path)))
    assert_equal(temp_bucket.objects[temp_file_name].read, "file test")

    assert_not_nil(temp_bucket.objects[temp_file_name].public_url)

    assert_not_nil(temp_bucket.objects[temp_file_name].url_for(:read, response_content_type: "application/json"))
    assert_not_nil(temp_bucket.objects[temp_file_name].url_for(:write, expires: 10 * 60))	# 10 minutes
    assert_not_nil(temp_bucket.objects[temp_file_name].url_for(:delete))

    temp_bucket.objects[temp_file_name].delete
    assert(temp_bucket.empty?)

    temp_bucket.delete!

  end

  def teardown
    `rm -rf '#{@temp_dir}'`
  end

end

