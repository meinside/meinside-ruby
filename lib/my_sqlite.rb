# coding: UTF-8

# lib/my_sqlite.rb
# 
# sqlite wrapper
# 
# created on : 2009.12.21
# last update: 2013.08.12
# 
# by meinside@gmail.com

require 'sqlite3'

# SQLite wrapper class
class MySqlite

  @database = nil

  # @param filepath [String] file path
  def initialize(filepath, &block)
    @database = SQLite3::Database.new(filepath)

    if block_given?
      yield self
      close
    end
  end

  # (see #initialize)
  def self.open(filepath, &block)
    if block_given?
      MySqlite.new(filepath, &block)
    else
      return MySqlite.new(filepath)
    end
  end

  # execute given query and variables
  # @param sql [String] query
  # @param vars [Array] query parameters
  # @return
  def execute_query(sql, *vars)
    return @database.execute(sql, vars)
  rescue
    puts "MySqlite.execute_query(): #{$!}"
  end

  # with column headers
  #
  # @note Usage:
  #  column_names, *rows = sqlite.select_with_column_names("select * from some_table")
  #
  # @param sql [String] query
  # @param vars [Array] query parameters
  # @return
  def select_with_column_names(sql, *vars)
    return @database.execute2(sql, vars)
  rescue
    puts "MySqlite.select_with_column_names(): #{$!}"
  end

  # get first row with given query and variables
  # @param sql [String] query
  # @param vars [Array] query parameters
  # @return
  def first_row(sql, *vars)
    return @database.get_first_row(sql, vars)
  rescue
    puts "MySqlite.first_row(): #{$!}"
  end

  # get first value with given query and variables
  # @param sql [String] query
  # @param vars [Array] query parameters
  # @return
  def first_value(sql, *vars)
    return @database.get_first_value(sql, vars)
  rescue
    puts "MySqlite.first_value(): #{$!}"
  end

  # get number of affected rows
  # @return [Fixnum]
  def changes
    return @database.changes
  end

  # get last inserted row's id
  # @return [Fixnum]
  def last_insert_row_id
    return @database.last_insert_row_id
  end

  # close currently opened file
  def close
    @database.close
  end

end

