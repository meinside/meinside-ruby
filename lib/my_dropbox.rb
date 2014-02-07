# coding: UTF-8

# lib/my_dropbox.rb
# 
# Dropbox library's wrapper class
# (https://www.dropbox.com/developers/start/setup#ruby)
# 
# created on : 2013.02.06
# last update: 2013.08.23
# 
# by meinside@gmail.com

require 'dropbox_sdk'
require 'yaml'

# Wrapper class for Dropbox service
# * config(.yml) file's format:
#  app_key: MY_APP_KEY
#  app_secret: MY_APP_SECRET
#  access_type: :dropbox or :app_folder
#  access_token: SESSION_TOKEN_RETRIEVED_FROM_AUTHORIZATION
#  access_secret: SESSION_SECRET_RETRIEVED_FROM_AUTHORIZATION
class MyDropbox

  private

  def self.restore_session(params)
    app_key = params[:app_key] || params["app_key"]
    app_secret = params[:app_secret] || params["app_secret"]
    access_token = params[:access_token] || params["access_token"]
    access_secret = params[:access_secret] || params["access_secret"]
    access_type = params[:access_type] || params["access_type"]

    session = DropboxSession.new(app_key, app_secret)
    session.set_access_token(access_token, access_secret)
    return DropboxClient.new(session, access_type)
  end

  public
  
  # use this function directly for generating access key/secret
  # @param params [String, Hash] config file's path or parameter values as a hash
  # @note examples
  #  - MyDropbox::authorize(app_key: "MY_APP_KEY", app_secret: "MY_APP_SECRET")
  # @return [DropboxSession, nil]
  def self.authorize(params)
    if params[:config_file]
      configs = YAML.load(File.read(File.expand_path(params[:config_file])))
      config = configs[:dropbox] || configs["dropbox"]
      return self.restore_session(config)
    else
      if params[:access_token] && params[:access_secret]
        return self.restore_session(params)
      else
        session = DropboxSession.new(params[:app_key], params[:app_secret])
        session.get_request_token
        authorize_url = session.get_authorize_url
        puts "* authorize with your Dropbox account here: #{authorize_url}"
        print "* press enter when finished..."
        gets
        session.get_access_token
        puts "> save following as a .yml file:"
        puts <<YML_FILE
---
dropbox:
  app_key: #{params[:app_key]}
  app_secret: #{params[:app_secret]}
  access_type: :dropbox or :app_folder  # should be set as the application provides
  access_token: #{session.access_token.key}
  access_secret: #{session.access_token.secret}
YML_FILE
      end
    end
    nil
  rescue
    puts $!
    nil
  end

  # initializer
  # @param params [String, Hash] config file's path or parameter values as a hash
  # @note examples
  #  - dropbox = MyDropbox.new(config_file: "~/.conf/dropbox.yml")
  #  - dropbox = MyDropbox.new(app_key: "MY_APP_KEY", app_secret: "MY_APP_SECRET", access_token: "xxxxxx", access_secret: "yyyyyy", access_type: ":dropbox or :app_folder")
  # @return [DropboxClient, nil]
  def initialize(params)
    @client = MyDropbox.authorize(params)
  rescue
    puts $!
    @client = nil
  end

  # put local file to dropbox server
  # @return [Hash, nil]
  def put(local_file, to_location, overwrite = true, close_file = true)
    local_file = File.open(File.expand_path(local_file), "rb") unless local_file.respond_to?(:read) # check if it's a File object
    result = @client.put_file(to_location, local_file, overwrite)
    local_file.close if close_file
    result
  rescue
    puts $!
    nil
  end

  # get remote file to local
  # @return [Hash, nil]
  def get(from_location, local_filepath, revision = nil)
    contents, metadata = @client.get_file_and_metadata(from_location, revision)
    File.open(local_filepath, 'wb'){ |f| f.write contents }
    metadata
  rescue
    puts $!
    nil
  end

  # get metadata for given path
  # @return [Hash, nil]
  def ls(path, revision = nil, include_deleted = false)
    @client.metadata(path, 25000, true, nil, revision, include_deleted)
  rescue
    puts $!
    nil
  end

  # create a directory on given path
  # @return [Hash, nil]
  def mkdir(path)
    @client.file_create_folder(path)
  rescue
    puts $!
    nil
  end

  # copy a remote file
  # @return [Hash, nil]
  def cp(from_location, to_location)
    @client.file_copy(from_location, to_location)
  rescue
    puts $!
    nil
  end

  # move a remote file
  # @return [Hash, nil]
  def mv(from_location, to_location)
    @client.file_move(from_location, to_location)
  rescue
    puts $!
    nil
  end

  # delete a remote file
  # @return [Hash, nil]
  def rm(location)
    @client.file_delete(location)
  rescue
    puts $!
    nil
  end

  # get revisions of a remote file
  # @return [Hash, nil]
  def revisions(location, limit = 1000)
    @client.revisions(location, limit)
  rescue
    puts $!
    nil
  end

  # restore a remote file
  # @return [Hash, nil]
  def restore(location, revision)
    @client.restore(location, revision)
  rescue
    puts $!
    nil
  end

  # share a remote file
  # @return [Hash, nil]
  def share(location)
    @client.shares(location)
  rescue
    puts $!
    nil
  end

end

