#!/usr/bin/env ruby
# coding: UTF-8

# lib/test/test_my_csv.rb
# 
# test my_csv
# 
# created on : 2012.06.28
# last update: 2013.02.28
# 
# by meinside@gmail.com

require 'test/unit'

require_relative "../my_csv"

TEMP_TXTFILE_PATH = File.expand_path("~/my_csv_temp.txt")
TEMP_CSVFILE_PATH = File.expand_path("~/my_csv_temp.csv")

CSV_TEXT =<<TEST
"col1","col2","col3"
1,Skull,"skulls everywhere"
2,Crossbone,"crossed-bones"
3,Pirates,"better than navy"
4,해적,"바다의 도적"
TEST
CSV_ARR = [
  ["col1", "col2", "col3",],
  [1, "Skull", "skulls everywhere",],
  [2, "Crossbone", "crossed-bones",],
  [3, "Pirates", "better than navy",],
  [4, "해적", "바다의 도적",],
]

class TestMyCsv < Test::Unit::TestCase

  def setup
    File.open(TEMP_TXTFILE_PATH, "w"){|file| file << CSV_TEXT}
  end

  def test_all
    assert(MyCsv.parse_file(TEMP_TXTFILE_PATH))
    assert(MyCsv.parse(CSV_TEXT))
    assert(MyCsv.parse_line(CSV_TEXT.split("\n").first))
    assert_equal(MyCsv.parse_line(MyCsv.buildup_line(CSV_ARR.first)), CSV_ARR.first)
    assert_equal(MyCsv.parse_line(MyCsv.buildup_line(CSV_ARR.last)).last, CSV_ARR.last.last)
    assert_not_nil(MyCsv.buildup_csv(CSV_ARR))
    assert(MyCsv.buildup_csvfile(CSV_ARR, TEMP_CSVFILE_PATH))
    assert_equal(MyCsv.parse_file(TEMP_CSVFILE_PATH).last.last, CSV_ARR.last.last)

    MyCsv.encoding = "EUC-KR"
    assert_equal(MyCsv.encoding, "EUC-KR")
  end

  def teardown
    `rm -f '#{TEMP_TXTFILE_PATH}'`
    `rm -f '#{TEMP_CSVFILE_PATH}'`
  end

end

