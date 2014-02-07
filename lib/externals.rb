# coding: UTF-8

# lib/externals.rb
# 
# functions using external services
# (in unofficial ways)
# 
# created on : 2013.02.27
# last update: 2013.08.23
# 
# by meinside@gmail.com

require 'json'

require_relative 'my_http'
require_relative 'my_str'

module Externals

  FAKE_USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_2) AppleWebKit/537.22 (KHTML, like Gecko) Chrome/25.0.1364.99 Safari/537.22"

  class Naver

    # auto-space given text with naver lab's web interface
    # (http://s.lab.naver.com/autospacing/)
    def self.autospace(str)
      result = MyHttp.post("http://s.lab.naver.com/autospacing/", {query: str,})
      if result.code.to_i == 200
        if result.body =~ /\<div class=\"wrap_spacing2\" style=\"clear:both;\"\>\s*\<p\>(.*?)\<\/p\>\s*\<\/div\>/im
          return $1.strip_tags
        end
      end
      return nil
    rescue
      puts "# exception in autospace: #{$!}"
      return nil
    end

  end

  class Google

    # return locale of given string suggested by google translate's web interface
    def self.detect_language(str)
      result = MyHttp.get("http://translate.google.com/translate_a/t", 
                          {client: "t", text: str, hl: "en", sl: "auto", tl: "auto", ie: "UTF-8", oe: "UTF-8"},
                          {"User-Agent" => FAKE_USER_AGENT,})
      if result.code.to_i == 200
        if result.body =~ /\[\[\[.*?\]\],(.*)"/
          txt = $1
          while txt =~ /\[[^\[\]]*\]/
            txt = txt.gsub(/\[[^\[\]]*\]/, "")
          end
          return $1.strip if txt =~ /^,\"([a-z]+)\"/i
        end
      end
      return nil
    rescue
      puts "# exception in detect_language: #{$!}"
      return nil
    end

    # translate given string with google translate's web interface
    def self.translate(str, from_lang, to_lang)
      result = MyHttp.get("http://translate.google.com/translate_a/t", 
                          {client: "t", text: str, hl: "en", sl: from_lang, tl: to_lang, ie: "UTF-8", oe: "UTF-8", multires: 1, otf: 1, pc: 1, ssel: 4, tsel: 0, sc: 1},
                          {"User-Agent" => FAKE_USER_AGENT,})
      if result.code.to_i == 200
        if result.body =~ /\[\[(\[.*?\])\]/
          return JSON.parse($1.strip, {allow_nan: true})[0]
        end
      end
      return nil
    rescue
      puts "# exception in translate: #{$!}"
      return nil
    end

    # download translated text's sound file
    # (http://translate.google.com/translate_tts?tl=ko&q=What+the+hell)
    def self.text_to_soundfile(str, to_lang, out_filepath)
      result = MyHttp.get("http://translate.google.com/translate_tts", 
                          {tl: to_lang, q: str,}, 
                          {"User-Agent" => FAKE_USER_AGENT,})
      if result.code.to_i == 200
        File.open(out_filepath, "wb"){|file| file << result.body}
        return true
      else
        return false
      end
    rescue
      puts "# exception in text_to_soundfile: #{$!}"
      return false
    end

  end

end

