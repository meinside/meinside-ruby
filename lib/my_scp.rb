# coding: UTF-8

# lib/my_scp.rb
# 
# my scp class
# 
# created on : 2008.11.27
# last update: 2014.06.17
# 
# by meinside@gmail.com

require 'net/scp'

require_relative 'my_util'

class MyScp
  @@verbose = true

  def initialize(addr)
    @address = addr
    @connection = nil
  end

  def connect(id, passwd)
    disconnect if @connection
    @connection = Net::SCP.start(@address, id, password: passwd)
    if block_given?
      yield self
      disconnect
    else
      return @connection
    end
  rescue
    puts "error: MyScp.connect()" if @@verbose
  end

  def disconnect
    @connection.session.close if @connection
    @connection = nil
  rescue
    puts "error: MyScp.disconnect()" if @@verbose
  end

  def upload(remote_dir, local_dir, recursive = true)
    return nil if @connection.nil?
    puts "MyScp.upload(#{local_dir} -> #{remote_dir})"
    @connection.upload!(local_dir, remote_dir, recursive: recursive)
    return true
  rescue
    puts "error: MyScp.upload(#{local_dir} -> #{remote_dir})" if @@verbose
  end

  def download(remote_dir, local_dir, recursive = true)
    return nil if @connection.nil?
    puts "MyScp.download(#{remote_dir} -> #{local_dir})"
    @connection.download!(remote_dir, local_dir, recursive: recursive)
    return true
  rescue
    puts "error: MyScp.download(#{remote_dir} -> #{local_dir})" if @@verbose
  end
  
  # @param verbose [true,false] set verbose or not
  def self.verbose=(verbose)
    @@verbose = verbose
  end

  # @return [true,false] verbose or not
  def self.verbose
    @@verbose
  end

end

