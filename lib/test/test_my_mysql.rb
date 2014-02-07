#!/usr/bin/env ruby
# coding: UTF-8

# lib/test/test_my_mysql.rb
# 
# test my_mysql
# 
# created on : 2012.08.02
# last update: 2013.02.28
# 
# by meinside@gmail.com

require 'test/unit'

require_relative "../my_util"
require_relative "../my_mysql"

class TestMyMysql < Test::Unit::TestCase

  include MyUtil

  def setup
    @test_host = prompt("> mysql host(default: localhost): ")
    @test_host = nil if @test_host.strip.empty?
    @test_port = prompt("> mysql port(default: 3306): ")
    @test_port = nil if @test_port.strip.empty?
    @test_id = prompt("> mysql user id: ")
    @test_passwd = prompt("> mysql user password: ", "*")
    @test_database = prompt("> mysql database: ")
  end

  def test_all
    MyMysql.connect(
      host: @test_host, 
      port: @test_port, 
      user: @test_id, 
      password: @test_passwd, 
      database: @test_database){|mysql|

      assert_not_nil(mysql)

      assert(mysql.execute_query("drop table if exists test_my_mysql"))
      num_tables = mysql.tables.count

      assert(mysql.execute_query("create table test_my_mysql(
                                id integer primary key auto_increment,
                                name varchar(32) not null,
                                value text default null
                                )"))

      assert_equal(mysql.tables.count, num_tables + 1)

      assert(mysql.execute_query("insert into test_my_mysql(name, value) values(?, ?)",
                                 ["tester", "testing my_mysql.rb"]))
      assert(mysql.execute_query("insert into test_my_mysql(name, value) values(?, ?)",
                                 ["tester2", "testing my_mysql.rb"]))
      assert(mysql.execute_query("insert into test_my_mysql(name, value) values('tester3', 'testing my_mysql.rb')"))
      assert(mysql.execute_query("insert into test_my_mysql(name, value) values('tester4', 'testing my_mysql.rb')"))

      assert_nil(mysql.execute_query("intentionally wrong query"))

      assert_not_nil(mysql.execute_query("select * from test_my_mysql where id >= ?",
                                         [0]))
      assert_not_nil(mysql.execute_query("select * from test_my_mysql where id >= 0"))

      last_insert_row_id = mysql.last_insert_row_id
      assert_equal(last_insert_row_id, mysql.execute_query("select count(*) as cnt from test_my_mysql")[0])

      mysql.execute_query("select * from test_my_mysql").each{|row|
        assert_not_nil(row[0])
        assert_not_nil(row[1])
      }

      assert_nil(mysql.execute_query("select * from test_my_mysql where name = 'no such name'").fetch)
      assert_equal(mysql.execute_query("select * from test_my_mysql where name = 'no such name'").count, 0)

      assert_equal(mysql.execute_query("update test_my_mysql set name = ?", "updated name").affected_rows, last_insert_row_id)

      assert(mysql.execute_query("drop table test_my_mysql"))

      assert_equal(mysql.charset, "utf8")
      mysql.charset = "euc-kr"
      assert_equal(mysql.charset, "euc-kr")
    }
  end

  def teardown
    # do nothing
  end

end

