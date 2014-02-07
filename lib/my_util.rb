# coding: UTF-8

# lib/my_util.rb
# 
# my utility functions
# 
# created on : 2008.11.19
# last update: 2014.02.07
# 
# by meinside@gmail.com

require 'io/console'
require 'digest/md5'

# monkey-patch for Object class
class Object
  # returns deep-copied object
  def deep_copy
    Marshal.load(Marshal.dump(self))
  end
end

# my utility module
module MyUtil

  # get user's input from STDIN with or without masking
  # @param msg [String] prompt message
  # @param mas [true, false] mask or not (for password input)
  # @return [String] user's input (without trailing newline)
  def prompt(msg, mask = false)
    print msg
    if mask
      input = STDIN.noecho(&:gets).chomp
      puts
    else
      input = STDIN.gets.chomp
    end
    input
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

