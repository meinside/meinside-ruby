# coding: UTF-8

# lib/my_aws.rb
# 
# AWS wrapper class
# (http://docs.amazonwebservices.com/AWSRubySDK/latest/frames.html)
# 
# created on : 2012.08.07
# last update: 2014.03.07
# 
# by meinside@gmail.com

require 'aws-sdk'
require 'yaml'

# Wrapper class for AWS services
class MyAws
  # location constraints
  LOCATION_CONSTRAINTS = {
    us: nil,
    uswest1: 'us-west-1',
    uswest2: 'us-west-2',
    eu: 'eu-west-1',
    tokyo: 'ap-northeast-1',
    singapore: 'ap-southeast-1',
    sa: 'sa-east-1',
  }

  # AWS-S3 wrapper class
  # * config(.yml) file's format:
  #  access_key_id: MY_ACCESS_KEY_ID
  #  secret_access_key: MY_SECRET_ACCESS_KEY
  class S3
    @@s3 = nil

    # @param params [String, Hash] config file's path or parameter values as a hash
    # @note examples
    #  - MyAws::S3.config(config_file: "~/.conf/s3.yml")
    #  - MyAws::S3.config(access_key_id: "MY_ACCESS_KEY_ID", secret_access_key: "MY_SECRET_ACCESS_KEY")
    # @return [true, nil]
    def self.config(params)
      if params[:config_file]
        config = YAML.load(File.read(File.expand_path(params[:config_file])))
        AWS.config(config)
      else
        AWS.config(params)
      end
      @@s3 = AWS::S3.new
      true
    rescue
      puts "* exception while configuring AWS: #{$!}"
      false
    end

    # @return [Array<Bucket>] buckets
    def self.buckets
      @@s3.buckets
    end

    # get bucket with given name
    # @param name [String] bucket's name
    # @return [Bucket, nil]
    def self.bucket(name)
      buckets.find{|x| x.name == name}
    rescue AWS::S3::Errors::AccessDenied
      @@s3.buckets[name]
    end

    # get location constraints' keys
    # @return [Array<String>]
    def self.regions
      LOCATION_CONSTRAINTS.keys
    end

    # get appropriate region endpoint for given location
    # @param location [String] location constraint's key
    # @return [String]
    def self.region_endpoint(location)
      return location.nil? ? 
        "s3.amazonaws.com" : 
        "s3-#{(location.is_a?(Symbol) ? LOCATION_CONSTRAINTS[location] : location)}.amazonaws.com"
    end

    # create a new bucket with given name and options
    # @param name [String] bucket's name
    # @param location [Symbol] location = :us | :uswest1 | :uswest2 | :eu | :tokyo | :singapore | :sa
    # @param options [Hash] options =
    #  {
    # 	acl: :private | :public_read | :public_read_write | :authenticated_read | :log_delivery_write,
    # 	grant_read: "xxx",
    # 	grant_write: "xxx",
    # 	grant_read_acp: "xxx",
    # 	grant_write_acp: "xxx",
    # 	grant_full_control: "xxx",
    #  }
    # @return [Bucket, nil] generated bucket
    def self.create_bucket(name, location = nil, options = {})
      options[:location_constraint] = LOCATION_CONSTRAINTS[location] if !location.nil? && !options.has_key?(:location_constraint)
      @@s3.buckets.create(name, options)
    rescue AWS::S3::Errors::AccessDenied
      puts "* exception while creating a bucket: #{$!}"
      nil
    end

    # empty bucket with given name
    # @param name [String] bucket's name
    def self.empty_bucket(name)
      bucket(name).clear!
    end

    # delete bucket with given name
    # @param name [String] bucket's name
    # @param error_when_not_empty [true, false] ignore not_empty_error or not
    def self.delete_bucket(name, error_when_not_empty = false)
      begin
        if error_when_not_empty
          bucket(name).delete
        else
          bucket(name).delete!
        end
      rescue AWS::S3::Errors::AccessDenied
        puts "* exception while deleting a bucket: #{$!}"
      end
    end
  end
end

