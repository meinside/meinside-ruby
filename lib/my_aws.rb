# coding: UTF-8

# lib/my_aws.rb
# 
# AWS wrapper class
# (http://docs.amazonwebservices.com/AWSRubySDK/latest/frames.html)
# 
# created on : 2012.08.07
# last update: 2013.08.23
# 
# by meinside@gmail.com

require 'aws-sdk'
require 'yaml'

# Wrapper class for AWS services
class MyAws

  # location constraints
  LOCATION_CONSTRAINTS = {
    us: nil,
    uswest1: "us-west-1",
    uswest2: "us-west-2",
    eu: "eu-west-1",
    tokyo: "ap-northeast-1",
    singapore: "ap-southeast-1",
    sa: "sa-east-1",
  }

  # AWS-S3 wrapper class
  # * config(.yml) file's format:
  #  access_key_id: MY_ACCESS_KEY_ID
  #  secret_access_key: MY_SECRET_ACCESS_KEY
  class S3
    # (see #Bucket)
    @buckets = nil

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
      return true
    rescue
      nil
    end

    # @return [Array<Bucket>] buckets
    def self.buckets
      if @buckets.nil?
        @buckets = AWS::S3.new.buckets.map{|x| 
          Bucket.new(name: x.name, location_constraint: x.location_constraint)
        }
      end
      return @buckets
    end

    # get bucket with given name
    # @param name [String] bucket's name
    # @return [Bucket, nil]
    def self.bucket(name)
      buckets.find{|x| x.name == name}
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
      bucket = AWS::S3.new.buckets.create(name, options)
      if bucket.exists?
        new_bucket = Bucket.new(name: bucket.name, location_constraint: bucket.location_constraint)
        @buckets << new_bucket
        return new_bucket
      end
      return nil
    rescue
      puts $!
      return nil
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
      rescue
      else
        @buckets.delete_if{|x| x.name == name}
      end
    end

    # wrapper class for AWS-S3 bucket
    class Bucket
      def initialize(values)
        @name = values[:name]
        @location_constraint = values[:location_constraint]
        @endpoint = MyAws::S3.region_endpoint(@location_constraint)

        # https://forums.aws.amazon.com/thread.jspa?threadID=74724
        @s3 = AWS::S3.new(s3_endpoint: endpoint)

        @value = @s3.buckets[@name]
      end

      # return objects of this bucket
      # @return [AWS::S3::ObjectCollection]
      def objects
        @value.objects
      end

      # return object keys
      # @return [Array] keys of objects
      def object_keys
        @value.objects.map{|x| x.key}
      end

      # return object for given key
      # @param key [String] object's key
      # @return [AWS::S3::S3Object]
      def object(key)
        objects[key]
      end

      # if missing, call S3::Bucket's method instead
      def method_missing(method, *args, &block)
        if @value.methods.include? method
          @value.send(method, *args, &block)
        else
          super
        end
      end

      attr_reader :name, :endpoint
    end
  end

end

