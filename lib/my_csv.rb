# coding: UTF-8

# lib/my_csv.rb
# 
# my csv library for parsing csv files easily
# 
# created on : 2010.08.13
# last update: 2013.08.23
# 
# by meinside@gmail.com

require 'csv'
require 'write_xlsx'
require 'spreadsheet'

# CSV helper class
class MyCsv

  # default encoding
  DEFAULT_ENCODING = 'UTF-8'

  @@encoding = DEFAULT_ENCODING

  # parse given file
  # @param filepath [String] csv file's path
  # @return [Array<Array>, nil]
  def self.parse_file(filepath)
    File.open(filepath, "r:#{@@encoding}"){|file|
      if block_given?
        CSV.foreach(file, encoding: @@encoding){|row|
          yield row
        }
      else
        return CSV.read(file, encoding: @@encoding)
      end
    }
  rescue
    puts "MyCsv.parse_file(#{filepath}): #{$!}"
    return nil
  end

  # parse given csv string
  # @param csv [String] csv string
  # @return [Array<Array>, nil]
  def self.parse(csv)
    if block_given?
      CSV.parse(csv, encoding: @@encoding){|row|
        yield row.map{|col| col.encode(@@encoding, invalid: :replace, undef: :replace) unless col.nil?}
      }
    else
      return CSV.parse(csv, encoding: @@encoding)
    end
  rescue
    puts "MyCsv.parse(): #{$!}"
    return nil
  end

  # parse a line of csv
  # @param line [String] a line of csv
  # @return [Array, nil]
  def self.parse_line(line)
    return line.nil? ? nil : line.encode(@@encoding, invalid: :replace, undef: :replace).parse_csv
  rescue
    puts "MyCsv.parse_line(#{line}): #{$!}"
    return nil
  end

  # build up a line of csv with given array
  # @param arr [Array] an array of elements
  # @return [Array, nil] a line of csv
  def self.buildup_line(arr)
    return CSV.generate(encoding: @@encoding){|csv| csv << arr}
  rescue
    puts "MyCsv.buildup_line(#{arr.join(",")}): #{$!}"
    return nil
  end

  # build up csv with given array of arrays
  # @param arr_of_arr [Array<Array>] array of csv lines
  # @return [Array<Array>, nil]
  def self.buildup_csv(arr_of_arr)
    return nil if arr_of_arr.nil?
    csv_string = CSV.generate(encoding: @@encoding){|csv|
      arr_of_arr.each{|row|
        csv << row.map{|col| col.to_s.encode(@@encoding, invalid: :replace, undef: :replace) unless col.nil?}
      }
    }
    return csv_string
  rescue
    puts "MyCsv.buildup_csv(): #{$!}"
    return nil
  end

  # build up csv with given array of arrays and save to a file
  # @param arr_of_arr [Array<Array>] array of csv lines
  # @param filepath [String] output file's path
  # @return [true, false]
  def self.buildup_csvfile(arr_of_arr, filepath)
    CSV.open(filepath, "wb"){|file|
      arr_of_arr.each{|arr|
        file << arr
      }
    }
    return true
  rescue
    puts "MyCsv.buildup_csvfile(#{filepath}): #{$!}"
    return false
  end

  # convert given csv file to xlsx file
  # @param from_filepath [String] csv file's path
  # @param to_filepath [String] output file's path (MS XLSX format)
  # @return [true, false]
  def self.csv_to_xlsx(from_filepath, to_filepath)
    workbook = WriteXLSX.new(to_filepath)
    worksheet = workbook.add_worksheet
    row = 0
    parse_file(from_filepath).each{|csv|
      col = 0
      csv.each{|element|
        worksheet.write(row, col, element)
        col += 1
      }
      row += 1
    }
    workbook.close
    return true
  rescue
    puts "MyCsv.csv_to_xlsx(#{from_filepath}, #{to_filepath}): #{$!}"
    return false
  end

  # convert given xls file to csv file
  # @param from_filepath [String] xls file's path (MS XLS format)
  # @param to_filepath [String] output file's path
  def self.xls_to_csvs(from_filepath, to_filepath)
    worksheets = Spreadsheet.open(from_filepath).worksheets
    worksheets.each{|sheet|
      if worksheets.count > 1
        ext = File.extname(to_filepath)
        output_filepath = to_filepath.gsub(ext, "_#{sheet.name}#{ext}")
      else
        output_filepath = to_filepath
      end
      File.open(output_filepath, "w"){|csv|
        sheet.each{|row|
          csv << buildup_line(row)
        }
      }
    }
  end

  # change character encoding
  # @param new_encoding [String] new encoding
  def self.encoding=(new_encoding)
    @@encoding = new_encoding
  end

  # get current character encoding
  # @return [String] current encoding
  def self.encoding
    @@encoding
  end

end
