# coding: UTF-8

# lib/my_gmail.rb
# 
# wrapper of gmail gem
# 
# created on : 2012.09.03
# last update: 2013.08.12
# 
# by meinside@gmail.com

require 'gmail'

# Gmail helper class
class MyGmail

  # send gmail with given options
  #
  # @param params [Hash] 
  #
  # @note params example:
  #  {
  #    username: 'somebody@gmail-or-something.com',
  #    passwd: 'some_passwd',
  #    recipient: 'somebody-who-will-receive-this@anywhere.com',
  #    title: 'some_title',
  #    text_content: 'plain text content',
  #    # (or)
  #    html_content: 'html text content',
  #    # (and optionally)
  #    filepath: '/some_where/some_file_name',
  #  }
  def self.send(params)
    Gmail.new(params[:username], params[:passwd]) {|gmail|
      gmail.deliver {
        to params[:recipient]
        subject params[:title]
        if params[:text_content]
          text_part {
            body params[:text_content]
          }
        end
        if params[:html_content]
          html_part {
            content_type 'text/html; charset=UTF-8'
            body params[:html_content]
          }
        end
        if params[:filepath]
          filepath = params[:filepath]
          if File.exists? filepath
            add_file filepath
          else
            puts "* file not found: #{filepath}"
          end
        end
      }
    }
  end
end
