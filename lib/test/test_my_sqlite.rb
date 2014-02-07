#!/usr/bin/env ruby
# coding: UTF-8

# lib/test/test_my_sqlite.rb
# 
# test my_sqlite
# 
# created on : 2012.06.28
# last update: 2013.02.28
# 
# by meinside@gmail.com

require 'test/unit'

require_relative "../my_sqlite"

TEST_SQLITE_FILEPATH = File.expand_path("~/my_sqlite_temp.sqlite")

class TestMySqlite < Test::Unit::TestCase

  def setup
    `rm -f '#{TEST_SQLITE_FILEPATH}'`
  end

  def test_all
    MySqlite.open(TEST_SQLITE_FILEPATH){|sqlite|
      assert(sqlite.execute_query("create table if not exists tbl_test(
                                    _id integer primary key autoincrement,
                                  str text not null)"))

      assert(sqlite.execute_query("insert into tbl_test(str) values(?)",
                                  ["test value 1"]))
      assert_equal(sqlite.last_insert_row_id, 1)

      assert(sqlite.execute_query("insert into tbl_test(str) values(?)",
                                  ["test value 2"]))
      assert_equal(sqlite.last_insert_row_id, 2)

      assert(sqlite.execute_query("update tbl_test set str = ? where _id = ?",
                                  ["changed", 1]))
      assert_equal(sqlite.changes, 1)

      assert_equal(sqlite.execute_query("select * from tbl_test").count, 2)

      assert_equal(sqlite.first_value("select * from tbl_test"), 1)
      assert_equal(sqlite.first_row("select * from tbl_test").join(","), "1,changed")
    }

    temp = MySqlite.open(TEST_SQLITE_FILEPATH)
    assert_not_nil(temp)
    temp.close
  end

  def teardown
    `rm -f '#{TEST_SQLITE_FILEPATH}'`
  end

end
