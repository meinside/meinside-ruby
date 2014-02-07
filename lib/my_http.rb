# coding: UTF-8

# lib/my_http.rb
# 
# http related functions
# 
# created on : 2008.11.05.
# last update: 2014.02.06.
# 
# by meinside@gmail.com

require 'net/http'
require 'uri'

require_relative 'my_str'

# my http library
class MyHttp

  @@timeout = nil

  # get page content from given url
  # @param url [String] url
  # @param parameters [Hash] parameters GET parameters
  # @param additional_headers [Hash] additional headers
  # @return [Net::HTTPResponse, nil]
  #
  # @note Usage of returned value:
  #  case result
  #  when Net::HTTPOK
  #    puts result.body
  #  when Net::HTTPRedirection
  #    puts "redirected url = #{result['Location']}"
  #  else
  #    puts "http status code = #{result.code.to_i}"
  #  end
  def self.get(url, parameters = nil, additional_headers = nil)
    unless parameters.nil?	# append parameters to url
      parameters.each_pair{|key, value|
        unless url.include?("?")
          url += "?" 
        else
          url += "&"
        end
        url += "#{key.to_s.urlencode}=#{value.to_s.urlencode}"
      }
    end
    uri = URI.parse(url)
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https'){|http|
      req = Net::HTTP::Get.new(uri.request_uri)
      unless additional_headers.nil?
        additional_headers.each_pair{|key, value|
          req.add_field(key, value)
        }
      end
      http.read_timeout = @@timeout unless @@timeout
      return http.request(req)
    }
  rescue
    puts "MyHttp.get(#{url}): #{$!}"
    return nil
  end

  # get page content from given url with POST method
  # @param url [String] url
  # @param parameters [Hash] parameters POST parameters
  # @param additional_headers [Hash] additional headers
  # @return [Net::HTTPResponse, nil]
  def self.post(url, parameters = nil, additional_headers = nil)
    uri = URI.parse(url)
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https'){|http|
      req = Net::HTTP::Post.new(uri.request_uri)
      unless parameters.nil?
        req.set_form_data(parameters, ';')
      end
      unless additional_headers.nil?
        additional_headers.each_pair{|key, value|
          req.add_field(key.to_s, value.to_s)
        }
      end
      http.read_timeout = @@timeout unless @@timeout
      return http.request(req)
    }
  rescue
    puts "MyHttp.post(#{url}): #{$!}"
    return nil
  end

  # get page content from given url with POST method (sending multipart data)
  # @param url [String] url
  # @param parameters [Hash] POST parameters
  # @param additional_headers [Hash] additional headers
  # @return [Net::HTTPResponse, nil]
  def self.post_multipart(url, parameters, additional_headers = nil)
    uri = URI.parse(url)
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https'){|http|
      req = Net::HTTP::Post.new(uri.request_uri)
      boundary = "____boundary_#{Time.now.to_i.to_s}____"
      req["Content-Type"] = "multipart/form-data; boundary=#{boundary}"
      body = ""
      parameters.each_pair{|key, value|
        body << "--#{boundary}\r\n"
        if value.respond_to?(:read)	# check if it's a File object
          body << "Content-Disposition: form-data; name=\"#{key.to_s.urlencode}\"; filename=\"#{File.basename(value.path)}\"\r\n"
          body << "Content-Type: #{get_content_type(value.path)}\r\n\r\n"
          body << value.read
        else
          body << "Content-Disposition: form-data; name=\"#{key.to_s.urlencode}\"\r\n"
          body << "Content-Type: text/plain\r\n\r\n"
          body << value
        end
        body << "\r\n"
      }
      body << "--#{boundary}--\r\n"
      req.body = body
      req["Content-Length"] = req.body.size
      unless additional_headers.nil?
        additional_headers.each_pair{|key, value|
          req.add_field(key.to_s, value.to_s)
        }
      end
      http.read_timeout = @@timeout unless @@timeout
      return http.request(req)
    }
  rescue
    puts "MyHttp.post_multipart(#{url}): #{$!}"
    return nil
  end

  # get page content from given url with POST method and basic auth
  # @param url [String] url
  # @param parameters [Hash] POST parameters
  # @param additional_headers [Hash] additional headers
  # @return [Net::HTTPResponse, nil]
  def self.post_with_auth(url, id, passwd, parameters = nil, additional_headers = nil)
    uri = URI.parse(url)
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https'){|http|
      req = Net::HTTP::Post.new(uri.request_uri)
      req.basic_auth(id, passwd)
      unless parameters.nil?
        req.set_form_data(parameters, ';')
      end
      unless additional_headers.nil?
        additional_headers.each_pair{|key, value|
          req.add_field(key.to_s, value.to_s)
        }
      end
      http.read_timeout = @@timeout unless @@timeout
      return http.request(req)
    }
  rescue
    puts "MyHttp.post_with_auth(#{url}, #{id}, #{passwd}): #{$!}"
    return nil
  end

  # build up GET parameters
  # @param parameters_hash [Hash] 
  # @return [String] generated GET parameters
  def self.buildup_param(parameters_hash)
    param = ""
    parameters_hash.each_pair{|key, value|
      param.concat "#{param.empty? ? "?" : "&"}#{key.to_s.urlencode}=#{value.to_s.urlencode}"
    }
    return param
  end

  # get content type of given file
  # @param filepath [String] file's path
  # @return [String, nil]
  def self.get_content_type(filepath)
    MimeMagic.by_path(filepath)
  rescue
    puts "MyHttp.get_content_type(#{filepath}): #{$!}"
    return nil
  end

  # curl given url
  # @param url [String] url
  # @param params [Hash] parameters
  # @param headers [Hash] additional headers
  # @return [Net::HTTPResponse, nil]
  def self.curl(url, params = {}, headers = {})
    result = MyHttp.get(url, params, headers)
    case result
    when Net::HTTPOK
      return result.body
    when Net::HTTPRedirection
      return curl(result['Location'], params, headers)
    else
      return nil
    end
  end

  # download given url as a file
  # @param url [String] url
  # @param out_filepath [String] out file's path
  # @param params [Hash] parameters
  # @param headers [Hash] additional headers
  def self.download(url, out_filepath, params = {}, headers = {})
    File.open(out_filepath, "wb"){|file|
      file << curl(url, params, headers)
    }
  end

  # get content length of given url
  # @param url [String] url
  # @param headers [Hash] additional headers
  # @return [Fixnum] content length
  def self.get_content_length(url, headers = {})
    uri = URI.parse(url)
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https'){|http|
      req = Net::HTTP::Head.new(uri.request_uri)
      unless headers.nil?
        headers.each_pair{|key, value|
          req.add_field(key, value)
        }
      end
      http.read_timeout = @@timeout unless @@timeout
      result = http.request(req)
      case result
      when Net::HTTPOK
        return result["Content-Length"].to_i
      when Net::HTTPRedirection
        return get_content_length(result['Location'], headers)
      else
        return nil
      end
    }
  rescue
    puts "MyHttp.get_content_length(#{url}): #{$!}"
    return nil
  end

  def self.set_timeout(timeout)
    @@timeout = timeout
  end

end

