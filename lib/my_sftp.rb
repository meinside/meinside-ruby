# coding: UTF-8

# lib/my_sftp.rb
# 
# my sftp class
# 
# created on : 2008.11.19
# last update: 2014.06.17
# 
# by meinside@gmail.com

require 'net/sftp'
require 'net/ssh'

require_relative 'my_util'

class MySftp
  @@verbose = true

  def initialize(addr, port = 22)
    @address = addr
    @port = port
    @connection = nil
  end

  def connected?
    return !@connection.nil?
  end

  def connect(id, passwd)
    disconnect if @connection
    @connection = Net::SFTP.start(@address, id, port: @port, password: passwd)
    if block_given?
      yield self
      disconnect
    else
      return @connection
    end
  rescue
    puts "MySftp.connect(): #{$!}" if @@verbose
  end

  def disconnect
    @connection.close_channel if @connection
    @connection = nil
  rescue
    puts "MySftp.disconnect(): #{$!}" if @@verbose
  end

  def upload(from, to)
    return nil unless @connection
    puts "MySftp.upload(#{from} -> #{to})" if @@verbose
    # TODO - create directory recursively before upload
    @connection.upload!(from, to)
  rescue
    puts "MySftp.upload(#{from} -> #{to}): #{$!}" if @@verbose
  end

  def download(from, to)
    return nil unless @connection
    puts "MySftp.download(#{from} -> #{to})" if @@verbose
    @connection.download!(from, to)
  rescue
    puts "MySftp.download(#{from} -> #{to}): #{$!}" if @@verbose
  end

  def mkdir(path, permission = 0700)
    return nil unless @connection
    puts "MySftp.mkdir(#{path}, #{permission})" if @@verbose
    @connection.mkdir!(path, permissions: permission)
  rescue
    puts "MySftp.mkdir(#{path}, #{permission}): #{$!}" if @@verbose
  end

  def mkdir_r(remote_path, permission = 0700)
    return nil unless @connection
    path = remote_path[0,1]
    remote_path.split(path).each{|dir|
      path = File.join(path, dir)
      # TODO - if already exists => do nothing
      puts "MySftp.mkdir_r(#{path}, #{permission})" if @@verbose
      @connection.mkdir!(path, permissions: permission)
    }
  rescue
    puts "MySftp.mkdir_r(#{path}, #{permission}): #{$!}" if @@verbose
  end

  def rmdir(path)
    return nil unless @connection
    puts "MySftp.rmdir(#{path})" if @@verbose
    @connection.rmdir! path
  rescue
    puts "MySftp.rmdir(#{path}): #{$!}" if @@verbose
  end

  def rm(path)
    return nil unless @connection
    puts "MySftp.rm(#{path})" if @@verbose
    @connection.remove! path
  rescue
    puts "MySftp.rm(#{path}): #{$!}" if @@verbose
  end

  # recurse given remote dir and call lambdas on files/dirs according to their types
  # (with remote/local path params)
  #
  # usage:
  # > recurse("/far-away-home/meinside/test", 
  # 			"/near-home/meinside/test"
  # 			lambda{|dir|	doSomethingOnDir(dir)}, 
  # 			lambda{|file|	doSomethingOnFile(file)})
  #
  def recurse(remote_path, local_path, lambda_dir, lambda_file)
    handle = @connection.opendir!(remote_path)
    while (entries = @connection.readdir!(handle)) do
      entries.each {|entry|
        remote_fullpath = File.join(remote_path, entry.name)
        if [".", ".."].include? entry.name
          next
        elsif entry.directory?
          lambda_dir.call(remote_fullpath) unless lambda_dir.nil?
          recurse(remote_fullpath, local_path, lambda_dir, lambda_file)
        elsif entry.file?
          lambda_file.call(remote_fullpath) unless lambda_file.nil?
        end
      }
    end
    @connection.close(handle)
  rescue
    puts "MySftp.recurse() - #{$!}" if @@verbose
  end

  def download_r(from, to)
    lambda_dir = lambda{|path|
      local_path = File.join(to, path.gsub(from, ""))
      puts "dir: #{path} => #{local_path}" if @@verbose
      File.makedirs(local_path)
    }
    lambda_file = lambda{|path|
      local_path = File.join(to, path.gsub(from, ""))
      puts "file: #{path} => #{local_path}" if @@verbose
      @connection.download(path, local_path)
    }
    recurse(from, to, lambda_dir, lambda_file)
  end
  
  # @param verbose [true,false] set verbose or not
  def self.verbose=(verbose)
    @@verbose = verbose
  end

  # @return [true,false] verbose or not
  def self.verbose
    @@verbose
  end

# def upload_r(from, to)
#   lambda_dir = lambda{|path|
#     local_path = File.join(to, path.gsub(from, ""))
#     puts "dir: #{local_path} => #{path}" if @@verbose
#     @connection.mkdir_r(path)
#   }
#   lambda_file = lambda{|path|
#     local_path = File.join(to, path.gsub(from, ""))
#     puts "file: #{local_path} => #{path}" if @@verbose
#     @connection.upload(local_path, path)
#   }
#   recurse(to, from, lambda_dir, lambda_file)
# end
#
# def mkdir_r(path)
#   # TODO - implement here
# end

end

