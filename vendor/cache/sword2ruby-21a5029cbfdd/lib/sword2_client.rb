# Ruby SWORD 2.0 Client
#
# developed as part of the JISC SWORD 2.0 project
#
# this was demo-ed in BibApp,
# so I learnt from the original 1.3 client that was in BibApp
# which was written by Tim Donohue, I think
# see: http://bibapp.org/
#
# provides SWORD client functionality as per the SWORD 2.0 spec
# when run against a SWORD 2.0 compliant server
# see: http://www.swordapp.org/
#
# also see: http://cottagelabs.com/some-post-about-sword2_client-ruby-client
# for more info about using this client
#
# exceptions:
#   does not handle ORE responses yet
#
# see the convenience functions and the execute function below for usage
#
# info about HEADERS and METADATA is in the README
#
# by Mark MacGillivray mark@cottagelabs.com


# define a sword exception
class SwordException < Exception; end
class SwordDepositReceiptParseException < Exception
  attr_accessor :source_xml
end

# sword client class
# create one of these to interact with a repository via sword
class Sword2Client

  # use Rails.logger if available for all logging
  class << self
    def logger
      @@logger ||= ::STDOUT
      @@logger ||= ::Rails.logger if defined?(Rails.logger)
    end
  end

  # access the connection, the config, and any deposit receipts
  attr_accessor :connection, :config, :depositreceipt

  # init the sword client based on configs
  # config_path under rails would be "#{Rails.root}/config/sword.yml"
  def initialize(config_path = nil,config = {})

    # set default config paths if none provided. use a rails config path if available
    config_path="#{File.expand_path(File.dirname(__FILE__))}/../config/sword.yml" if config_path.nil?
    config_path="#{Rails.root}/config/sword.yml" if defined?(Rails.root)

    # load config, throw exception if no config file or values, or critical info missing
    raise SwordException, "could not find sword config file at " + config_path + " and no config params passed" if ( !File.exists?(config_path) and config.length == 0 )

    # set the config depending on environment. throw exception if impossible
    @config = YAML::load(File.read(config_path))[Rails.env] if defined?(Rails.env) and File.exists?(config_path)
    @config = YAML::load(File.read(config_path))["test"] if !defined?(Rails.env) and File.exists?(config_path)
    @config.merge(config) if config.length > 0
    raise SwordException, "sword config found, but 'service_doc_url' is not set for current env" if !@config['service_doc_url'] or @config['service_doc_url'].empty?

    # set connection params from configs
    params = {}
    params[:debug_mode] = true if @config['debug_mode']
    params[:username] = @config['username'] if @config['username'] and !@config['username'].empty?
    params[:password] = @config['password'] if @config['password'] and !@config['password'].empty?

    # set proxy params if necessary
    if @config['proxy_server'] and !@config['proxy_server'].empty?
      proxy_settings = {}
      proxy_settings[:server] = @config['proxy_server']
      proxy_settings[:port] = @config['proxy_port'] if @config['proxy_port'] and !@config['proxy_port'].empty?
      proxy_settings[:username] = @config['proxy_username'] if @config['proxy_username'] and !@config['proxy_username'].empty?
      proxy_settings[:password] =  @config['proxy_password'] if @config['proxy_password']and !@config['proxy_password'].empty?
      params[:proxy_settings] = proxy_settings
    end

    # init connection
    @connection = Sword2Client::Connection.new(@config['service_doc_url'], params)

    # set the depositreceipt to nil, it can be set into after execute if necessary

  end


  # test if the SwordClient seems to be configured
  # by attempting to initialize it based on sword.yml
  def self.configured?
    begin
      client = Sword2Client.new
      return true if client.kind_of?(Sword2Client)
    rescue SwordException, Exception
      # rescue any exception, but do nothing
    end
    return false
  end


  # get the details about the repo at the end of the connection
  def repo(connection = @connection,config = @config)
    if !@repository
      @repository = Sword2Client::Repository.new(connection,config)
    end
    @repository
  end


  # now follow some convenience functions that just do the SWORD execute


  # make a new container in a collection by POSTing a file or metadata or both
  # URL expected to identify collection - should be collection IRI
  def new_container(collection_url,filepath=nil,metadata={},headers={})
    raise SwordException, "new_container cannot be done without a content filepath and/or metadata" if filepath.nil? and metadata.empty?
    execute("post","collection",collection_url,filepath,metadata,headers)
  end

  # POST content to an existing container
  # URL expected to identify container - should be container edit IRI
  def add_to_container(container_url,filepath=nil,headers={})
    raise SwordException, "add_to_container cannot be done with no filepath" if filepath.nil?
    execute("post","edit",container_url,filepath,{},headers)
  end

  # PUT new content to a container (replacing current content)
  # URL expected to identify container - should be container edit IRI
  def replace_container_content(container_url,filepath=nil,headers={})
    raise SwordException, "replace_container_content cannot be done with no filepath" if filepath.nil?
    execute("put","edit-media",container_url,filepath,{},headers)
  end

  # PUT new metadata to a container (replacing current metadata)
  # URL expected to identify container - should be container edit IRI
  def replace_container_metadata(container_url,metadata={},headers={})
    raise SwordException, "replace_container_metadata cannot be done with no metadata" if metadata.empty?
    execute("put","edit",container_url,nil,metadata,headers)
  end

  # PUT new content and metadata to a container (replacing current content and metadata)
  # URL expected to identify container - should be container edit IRI
  def replace_container_content_and_metadata(container_url,filepath,metadata={},headers={})
    raise SwordException, "replace_container_content_and_metadata cannot be done without content filepath and metadata" if filepath.nil? and metadata.empty?
    execute("put","edit",container_url,filepath,metadata,headers)
  end

  # DELETE content of a container
  # URL expected to identify container - should be container edit IRI
  def delete_container_content(container_url)
    execute("delete","edit-media",container_url)
  end

  # DELETE a container (and its content)
  # URL expected to identify container - should be container edit IRI
  def delete_container(container_url)
    execute("delete","edit",container_url)
  end

  # tell the sword server to change the  in-progress header of an item
  # URL expected to identify container - should be container edit IRI
  def set_in_progress(container_url,headers={"In-Progress"=>false})
    tmp = Tempfile.new('emptyfile')
    execute("post","edit",container_url,tmp.path,nil,headers)
  end


  # execute a method on collection, edit or edit-media
  def execute(method="get",on="collection",url=nil,filepath=nil,metadata={},headers={})

    # create a deposit object
    object = Sword2Client::DepositObject.new(method,on,url,filepath,metadata,headers,repo)

    # do the request
    case method
      when "get" then response = @connection.get(object.target,object.headers)
      when "post" then response = @connection.post(object.object,object.target,object.headers)
      when "put" then response = @connection.put(object.object,object.target,object.headers)
      when "delete" then response = @connection.delete(object.target)
    end

    return_response(response,on,method)

  end


  private

  # this method defines the response that gets returned from the execute
  def return_response(response,on,method)

    case response
      when Net::HTTPSuccess

        case method
          when "get"
            case on
              when "collection"
                # response is collection description if collection
                # return a list of the edit IRIs for the items in the collection
                coll = Sword2Client::Collection.new(response.body)
                coll.items
              when "edit"
                # response is deposit receipt
                @depositreceipt = Sword2Client::DepositReceipt.new(response.body)
                
              when "edit-media"
                # response is file
                response.body
            end

          when "post"
            # response may return deposit receipt in body. if so, make it available
            if !response.body.nil? and response.body != ""
              @depositreceipt = Sword2Client::DepositReceipt.new(response.body)
            else
              @depositreceipt = Sword2Client::DepositReceipt.new(response['Location'])
            end
            # response should set location header which is edit IRI, so return that
            response['Location']

          when "put"
            # response is just OK or some other suitable response code, so return nil
            nil

          when "delete"
            # response is nothing
            nil
        end
    else
      response.error!
    end

  end

end

# load SwordClient sub-classes
require 'sword2_client/atomentry'
require 'sword2_client/collection'
require 'sword2_client/connection'
require 'sword2_client/depositobject'
require 'sword2_client/depositreceipt'
require 'sword2_client/multipart'
require 'sword2_client/parsedservicedoc'
require 'sword2_client/repository'
require 'sword2_client/servicedocparser'

