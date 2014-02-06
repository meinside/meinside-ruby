# coding: UTF-8

# lib/my_util.rb
# 
# my utility functions
# 
# created on : 2008.11.19
# last update: 2013.08.12
# 
# by meinside@gmail.com

require "highline/import"
require "find"
require "fileutils"
require "base64"

# monkey-patch for Object class
class Object
  # returns deep-copied object
  def deep_copy
    Marshal.load(Marshal.dump(self))
  end
end

# my utility module
module MyUtil

  # get user's input from STDIN with/without masking
  # @param msg [String] prompt message
  # @param masking_char [String, nil] masking character for password input (nil for non-masking)
  def prompt(msg, masking_char = nil)
    if masking_char.nil?
      ask(msg)
    else
      ask(msg){|q| q.echo = masking_char}
    end
  end

  # get md5sum from given file path
  # @param filepath [String] file path
  # @return [String] MD5 hash of given file
  def md5sum(filepath)
    md5 = Digest::MD5.new
    File.open(filepath, "r"){|file|
      md5.update(file.read)
    }
    return md5.hexdigest
  end

end

