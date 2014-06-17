# coding: UTF-8

# lib/my_oauth.rb
# 
# OAuth class (referenced: http://oauth.net/core/1.0a)
# 
# created on : 2009.09.15
# last update: 2014.06.17
# 
# by meinside@gmail.com

require_relative 'my_http'
require_relative 'my_str'

# my OAuth helper class
class MyOAuth
  @@verbose = true

  # initializer
  #
  # @note
  # * if the user is already authorized(then, no need to authorize again), extra_param must have 'oauth_token' & 'oauth_token_secret' key-values in it.
  #
  # * example:
  #  extra_param = {
  #    "oauth_token" => XXXX,  # access token
  #    "oauth_token_secret" => YYYY, # access token secret
  #   }
  #
  # @param consumer_key [String] consumer key
  # @param consumer_secret [String] consumer secret
  # @param request_token_url [String] request token url
  # @param access_token_url [String] access token url
  # @param authorize_url [String] authorize url
  # @param extra_param [Hash] extra parameters
  #
  def initialize(consumer_key, consumer_secret, request_token_url, access_token_url, authorize_url, extra_param = {})
    # consumer key/secret
    @consumer_key = consumer_key
    @consumer_secret = consumer_secret

    # urls
    @request_token_url = request_token_url
    @access_token_url = access_token_url
    @authorize_url = authorize_url

    # initialize values
    @oauth_token = {
      "oauth_token" => "",
      "oauth_token_secret" => "",
    }

    if extra_param.include?("oauth_token") && extra_param.include?("oauth_token_secret")	# already authorized
      @authorized = true
      @access_token = extra_param
    else	# not authorized
      @authorized = false
      @access_token = nil
    end
  end

  # @return [String] timestamp
  def timestamp
    return Time.now.tv_sec.to_s
  end

  # @return [String] nonce value
  def nonce
    return Time.now.hash.to_s.md5
  end

  # converts string parameter to ruby hash (ex: name1=value1&name2=value3&...)
  # @param str [String] string
  # @return [Hash] parsed value of given string
  def string_param_to_hash(str)
    hash = {}
    str.split("&").each{|param|
      name, value = param.split("=")
      hash[name] = value
    }
    return hash
  end

  # normalizes given url
  # @param url [String] url
  # @return [String] normalized url
  def normalize_url(url)
    result = ""
    uri = URI.parse(url)
    result += uri.scheme.downcase
    result += "://"
    result += uri.host.downcase
    result += ":#{uri.port}" if uri.default_port != uri.port
    result += uri.path
    return url
  end

  # normalizes given request parameters(hash)
  # @param params_hash [Hash] parameters' hash
  # @param get_post_params_hash [Hash] GET/POST parameters' hash
  # @return [String] normalized request params
  def normalize_request_param(params_hash, get_post_params_hash)
    normalized_request_param = ""
    total_params_hash = {}
    params_hash.each_pair{|key, value|
      total_params_hash[key.to_s] = value.to_s
    }
    get_post_params_hash.each_pair{|key, value|
      total_params_hash[key.to_s] = value.to_s
    }
    total_params_hash.sort.each{|token|
      next if token[0] == "realm"	# skip 'realm' parameter
      normalized_request_param += "&" if normalized_request_param.length > 0
      normalized_request_param += "#{token[0].urlencode}=#{token[1].urlencode}"
    }

    return normalized_request_param
  end

  # generate signature base string
  # @param method [String] method
  # @param url [String] url
  # @param params [Hash] parameters
  # @param get_post_params [Hash] GET/POST parameters
  # @return [String] signature base string
  def generate_signature_base_string(method, url, params, get_post_params = {})
    normalized_url = normalize_url(url)
    normalized_params = normalize_request_param(params, get_post_params)
    return method + "&" + normalized_url.urlencode + "&" + normalized_params.urlencode
  end

  # generate oauth signature
  # @param signature_base_string [String] signature base string
  # @return [String] oauth signature
  def generate_oauth_signature(signature_base_string)
    return signature_base_string.hmac_sha1(@consumer_secret.urlencode + "&" + @oauth_token["oauth_token_secret"].urlencode).base64encode
  end

  # generate access signature
  # @param signature_base_string [String] signature base string
  # @return [String] access signature
  def generate_access_signature(signature_base_string)
    return signature_base_string.hmac_sha1(@consumer_secret.urlencode + "&" + @access_token["oauth_token_secret"].urlencode).base64encode
  end

  # generate auth header from given params
  # @param params [Hash] parameters
  # @return [String] auth header
  def generate_auth_header(params)
    auth_header_value = ""
    params.each_pair{|key, value|
      auth_header_value += "," if auth_header_value.length > 0
      auth_header_value += "#{key.urlencode}=\"#{value.urlencode}\""
    }

    return auth_header_value
  end

  # returns oauth token values (token + token_secret)
  # @return [Hash, nil]
  def request_oauth_token
    request_token_hash = {
      "oauth_consumer_key" => "#{@consumer_key}",
      "oauth_signature_method" => "HMAC-SHA1",
      "oauth_timestamp" => timestamp,
      "oauth_nonce" => nonce,
      "oauth_version" => "1.0",
      "oauth_callback" => "oob",
    }

    # set signature
    request_token_hash["oauth_signature"] = generate_oauth_signature(generate_signature_base_string("POST", @request_token_url, request_token_hash))

    # post with auth header
    result = MyHttp.post(@request_token_url, nil, {
      "Authorization" => "OAuth #{generate_auth_header(request_token_hash)}",
    })

    auth_token_string = result.body.strip
    if result.is_a? Net::HTTPSuccess
      return string_param_to_hash(auth_token_string)
    else
      status = result.code
      return nil
    end
  end

  # request access token with given oauth verifier
  # @param oauth_verifier [String] OAuth verifier
  # @return [true, false] the request was processed successfully
  def request_access_token(oauth_verifier)
    access_token_hash = {
      "oauth_consumer_key" => "#{@consumer_key}",
      "oauth_token" => "#{@oauth_token["oauth_token"]}",
      "oauth_signature_method" => "HMAC-SHA1",
      "oauth_timestamp" => timestamp,
      "oauth_nonce" => nonce,
      "oauth_version" => "1.0",
      "oauth_verifier" => "#{oauth_verifier}",
    }

    # set signature
    access_token_hash["oauth_signature"] = generate_oauth_signature(generate_signature_base_string("POST", @access_token_url, access_token_hash))

    # post with auth header
    result = MyHttp.post(@access_token_url, nil, {
      "Authorization" => "OAuth #{generate_auth_header(access_token_hash)}",
    })

    access_token_string = result.body.strip
    if result.is_a? Net::HTTPSuccess
      return string_param_to_hash(access_token_string)
    else
      status = result.code
      return nil
    end
  end

  # get user's auth url (user will use this url to authorize him/herself)
  # @return [String, nil]
  def get_user_auth_url
    @oauth_token = request_oauth_token
    return @authorize_url + "?oauth_token=" + @oauth_token["oauth_token"]
  rescue
    puts $! if @@verbose
    return nil
  end

  # authorize with user's pin number(retrieved from user's auth url)
  # @param oauth_verifier [String] OAuth verifier
  # @return [true, false]
  def authorize(oauth_verifier)
    @access_token = request_access_token(oauth_verifier)
    @authorized = true
    return true
  rescue
    puts $! if @@verbose
    return false
  end

  # request protected resources using get method
  # @param url [String] url
  # @param params [Hash] parameters
  # @return [Net::HTTPResponse]
  def get(url, params = {})
    get_auth_hash = {
      "oauth_consumer_key" => "#{@consumer_key}",
      "oauth_token" => "#{@access_token["oauth_token"]}",
      "oauth_signature_method" => "HMAC-SHA1",
      "oauth_timestamp" => timestamp,
      "oauth_nonce" => nonce,
      "oauth_version" => "1.0",
    }

    # set signature
    get_auth_hash["oauth_signature"] = generate_access_signature(generate_signature_base_string("GET", url, get_auth_hash, params))

    # get with auth header
    return MyHttp.get(url, params, {
      "Authorization" => "OAuth #{generate_auth_header(get_auth_hash)}",
    })
  end

  # request protected resources using post method
  # @param url [String] url
  # @param params [Hash] parameters
  # @return [Net::HTTPResponse]
  def post(url, params = {})
    post_auth_hash = {
      "oauth_consumer_key" => "#{@consumer_key}",
      "oauth_token" => "#{@access_token["oauth_token"]}",
      "oauth_signature_method" => "HMAC-SHA1",
      "oauth_timestamp" => timestamp,
      "oauth_nonce" => nonce,
      "oauth_version" => "1.0",
    }

    # set signature
    post_auth_hash["oauth_signature"] = generate_access_signature(generate_signature_base_string("POST", url, post_auth_hash, params))

    # post with auth header
    return MyHttp.post(url, params, {
      "Authorization" => "OAuth #{generate_auth_header(post_auth_hash)}",
      "Content-Type" => "application/x-www-form-urlencoded",
    })
  end

  # request protected resources using post method (sending multipart data)
  # @param url [String] url
  # @param params [Hash] parameters
  # @return [Net::HTTPResponse]
  def post_multipart(url, params = {})
    post_auth_hash = {
      "oauth_consumer_key" => "#{@consumer_key}",
      "oauth_token" => "#{@access_token["oauth_token"]}",
      "oauth_signature_method" => "HMAC-SHA1",
      "oauth_timestamp" => timestamp,
      "oauth_nonce" => nonce,
      "oauth_version" => "1.0",
    }

    # set signature
    # (when sending multipart/form-data, 
    # it doesn't need post params for signature base string)
    post_auth_hash["oauth_signature"] = generate_access_signature(generate_signature_base_string("POST", url, post_auth_hash))

    # post with auth header
    return MyHttp.post_multipart(url, params, {
      "Authorization" => "OAuth #{generate_auth_header(post_auth_hash)}",
    })
  end
  
  # @param verbose [true,false] set verbose or not
  def self.verbose=(verbose)
    @@verbose = verbose
  end

  # @return [true,false] verbose or not
  def self.verbose
    @@verbose
  end

  attr_reader :access_token, :authorized

  public :get_user_auth_url, :authorize, :get, :post
  private :request_access_token, :request_oauth_token, :generate_oauth_signature, :generate_access_signature

end

