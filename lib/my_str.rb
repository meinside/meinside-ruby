# coding: UTF-8

# lib/my_str.rb
# 
# string helper class
# 
# created on : 2012.06.26
# last update: 2013.08.23
# 
# by meinside@gmail.com

require 'hmac-sha1'
require 'openssl'
require 'digest/md5'
require 'base64'
require 'uri'

# monkey-patch for String class
class String

  # color codes for color terminals
  COLOR_CODES = {
    off: 0, bright: 1, underline: 4, blink: 5, invert: 7,
    hide: 8, black: 30, red: 31, green: 32, yellow: 33,
    blue: 34, magenta: 35, cyan: 36, white: 37, default: 39,
    black_bg: 40, red_bg: 41, green_bg: 42, yellow_bg: 43, blue_bg: 44,
    magenta_bg: 45, cyan_bg: 46, white_bg: 47, default_bg: 49,
  }

  # onsets of Hangul
  HANGUL_ONSETS = ['ㄱ', 'ㄲ', 'ㄴ', 'ㄷ', 'ㄸ', 'ㄹ', 'ㅁ', 'ㅂ', 'ㅃ', 'ㅅ', 'ㅆ', 'ㅇ', 'ㅈ', 'ㅉ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ']
  # nucleuses of Hangul
  HANGUL_NUCLEUSES = ['ㅏ', 'ㅐ', 'ㅑ', 'ㅒ', 'ㅓ', 'ㅔ', 'ㅕ', 'ㅖ', 'ㅗ', 'ㅘ', 'ㅙ', 'ㅚ', 'ㅛ', 'ㅜ', 'ㅝ', 'ㅞ', 'ㅟ', 'ㅠ', 'ㅡ', 'ㅢ', 'ㅣ']
  # codas of Hangul
  HANGUL_CODAS = ['', 'ㄱ', 'ㄲ', 'ㄳ', 'ㄴ', 'ㄵ', 'ㄶ', 'ㄷ', 'ㄹ', 'ㄺ', 'ㄻ', 'ㄼ', 'ㄽ', 'ㄾ', 'ㄿ', 'ㅀ', 'ㅁ', 'ㅂ', 'ㅄ', 'ㅅ', 'ㅆ', 'ㅇ', 'ㅈ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ']

  # referenced: http://stackoverflow.com/questions/4681055/how-can-i-detect-cjk-characters-in-a-string-in-ruby
  # @return [true, false] check if this string contains CJK characters
  def contains_cjk?
    !!(self =~ /\p{Han}|\p{Katakana}|\p{Hiragana}|\p{Hangul}/)
  end

  # referenced: http://blog.superkdk.com/?p=68
  # @return [Array] extracted Hangul syllables of this string
  def hangul_syllables
    syllables = []
    self.each_char{|c|
      c.unpack("U*").each{|b|
        if b >= 0xAC00 && b <= 0xD7A3	# korean characters' range: 가(0xAC00) ~ 힣(0xD7A3)
          b -= 0xAC00
          onset = b / (HANGUL_NUCLEUSES.count * HANGUL_CODAS.count)
          b %= (HANGUL_NUCLEUSES.count * HANGUL_CODAS.count)
          nucleus = b / HANGUL_CODAS.count
          coda = b % HANGUL_CODAS.count

          syllable = {
            onset: HANGUL_ONSETS[onset], 
            nucleus: HANGUL_NUCLEUSES[nucleus], 
          }
          syllable[:coda] = HANGUL_CODAS[coda] unless HANGUL_CODAS[coda].empty?

          syllables << syllable
        else
          syllables << b.chr
        end
      }
    }
    syllables
  end

  # * referenced: http://kpumuk.info/ruby-on-rails/colorizing-console-ruby-script-output/
  # get color code for given color symbol/code
  # @param color [Symbol, Fixnum] color
  def color_code(color)
    "\e[#{(color.is_a? Symbol) ? (COLOR_CODES[color] || COLOR_CODES[:default]) : color.to_i}m"
  end

  # colorize this string with given color symbols/codes
  # @param colors [Array] colors
  def colorize(* colors)
    buff = []
    colors.each{|color| buff << color_code(color)}
    buff << self << color_code(:off)
    buff.join
  end

  # get md5 hex digest value
  # @return [String] MD5 digest of this string
  def md5
    Digest::MD5.hexdigest(self)
  end

  # get hmac-sha1 digest
  # @return [String] HMAC-SHA1 digest of this string
  def hmac_sha1(secret)
    HMAC::SHA1.digest(secret, self)
  end

  # AES encrypt/decrypt
  # @param secret [String] secret key in 16bytes, 32bytes, ... (128bit, 256bit, ...)
  # @param params [Hash] parameters
  # @return encrypted bytes
  # 
  # @note example of params:
  #  {
  #    iv: "0123456789abcdef" or nil,
  #    option: :ecb, :cbc or etc.,
  #  }
  def aes_encrypt(secret, params = {iv: nil, option: :ecb})
    cipher = OpenSSL::Cipher::Cipher.new("aes-#{secret.length * 8}-#{params[:option].to_s}")
    cipher.encrypt
    cipher.key = secret
    cipher.iv = params[:iv] if params[:iv]
    encrypted = cipher.update(self)
    encrypted << cipher.final
    encrypted
  end

  # (see #aes_encrypt)
  def aes_decrypt(secret, params = {iv: nil, option: :ecb})
    decipher = OpenSSL::Cipher::Cipher.new("aes-#{secret.length * 8}-#{params[:option].to_s}")
    decipher.decrypt
    decipher.key = secret
    decipher.iv = params[:iv] if params[:iv]
    decrypted = decipher.update(self)
    decrypted << decipher.final
    decrypted
  end

  # base64 encode
  # @return [String] base64 encoded string
  def base64encode
    Base64.encode64(self).chomp
  end

  # (see #base64encode)
  def base64decode
    Base64.decode64(self)
  end

  # url encode
  # @param conform_to_rfc3986 [true, false] conform to RFC3986 or not
  # @return [String] url encoded string
  def urlencode(conform_to_rfc3986 = true)
    if conform_to_rfc3986	# http://tools.ietf.org/html/rfc3986#section-2.3
      URI.escape(self, Regexp.new("[^#{"-_.~a-zA-Z\\d"}]"))
    else
      URI.escape(self, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
    end
  end

  # (see #urlencode)
  def urldecode
    URI.unescape(self)
  end

  # remove html tags
  # @param preserved_tags [Array<String>] preserved tags
  # @return [String] tags-stripped-string
  def strip_tags(preserved_tags = [])
    (self.strip || '').gsub(/<(\/|\s)*[^(#{(preserved_tags << '|\/').join('|')})][^>]*>/, "")
  end

  # generate string from bytes array
  # @param bytes [Array<Number>] bytes array
  # @param enc [String] desired encoding
  # @return [String] generated string
  def self.from_bytes(bytes, enc = "utf-8")
    bytes.pack("C*").force_encoding(enc)
  end

end

