# coding: UTF-8

# lib/my_mysql.rb
# 
# mysql wrapper
# 
# created on : 2012.08.02
# last update: 2013.08.12
# 
# by meinside@gmail.com

require "mysql"

# add helper functions in Mysql::Stmt
class Mysql::Stmt
  # number of rows
  # @return [Fixnum] number of selected rows
  def count
    self.num_rows
  end

  # get row at given index
  # @param index [Fixnum] row index
  # @return
  def [](index)
    self.fetch[index]
  end
end

# mysql wrapper class
class MyMysql

  # default host
  LOCALHOST = "127.0.0.1"	# XXX - 'localhost'

  # default port
  DEFAULT_PORT = 3306

  # default character set
  DEFAULT_CHARSET = "utf8"

  @@charset = DEFAULT_CHARSET
  @database = nil

  # setup mysql connection
  #
  # @param options [Hash] 
  #
  # @note Options example: 
  #  {
  #    host: "some.host",
  #    port: 3306,
  #    user: "some_user",
  #    password: "some_passwd",
  #    database: "some_db", 
  #  }
  def initialize(options, &block)
    host = options[:host] || LOCALHOST
    port = options[:port] || DEFAULT_PORT
    user = options[:user]
    passwd = options[:password]
    database = options[:database]

    @database = Mysql.connect(host, user, passwd, database, port)
    @database.options(Mysql::SET_CHARSET_NAME, @@charset)

    if block_given?
      yield self
      disconnect
    end
  end

  # (see #initialize)
  def self.connect(options, &block)
    if block_given?
      MyMysql.new(options, &block)
    else
      return MyMysql.new(options)
    end
  end

  # execute given query and variables
  # @param sql [String] query
  # @param vars [Hash] query parameters
  def execute_query(sql, *vars)
    if vars && vars.count > 0
      @database.prepare(sql).execute(*vars.flatten)
    else
      @database.prepare(sql).execute
    end
  rescue
    puts "MyMysql.execute_query(): #{$!}"
  end

  # get tables
  # @return [Array<String>]
  def tables
    @database.list_tables
  end

  # get databases
  # @return [Array<String>]
  def databases
    @database.list_dbs
  end

  # select database
  # @param database [String] database name
  def select_database(database)
    @database.select_db(database)
  end

  # get number of affected rows
  # @return [Fixnum]
  def changes
    @database.affected_rows
  end

  # get last inserted row's id
  # @return [Fixnum]
  def last_insert_row_id
    @database.insert_id
  end

  # disconnect from server
  def disconnect
    @database.close
    @database = nil
  end

  # set character set
  # @param new_charset [String] new charset
  def charset=(new_charset)
    @@charset = new_charset
  end

  # get current character set
  # @return [String]
  def charset
    @@charset
  end

  # set timeout values
  # @param timeout [Float] timeout value
  def timeout=(timeout)
    @database.options(Mysql::OPT_CONNECT_TIMEOUT, timeout)
    @database.options(Mysql::OPT_READ_TIMEOUT, timeout)
    @database.options(Mysql::OPT_WRITE_TIMEOUT, timeout)
  end

end
