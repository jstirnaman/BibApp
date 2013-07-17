# get all the various details that are available about the
# connected repositry


class Sword2Client::Repository

  # getsets for repo info
  attr_accessor :parsedoc, :name, :collections, :default

  def initialize(connection=Sword2Client::Connection.new, config = {})

    # make the variables available
    @connection = connection
    @config = config

    # parse the service document
    @parsedoc = parse_service_doc

    # set repo name
    @name = @parsedoc.repository_name
    
    # set the collections in the repo
    @collections = @parsedoc.collections

    # set the default collection
    @default = collection(@config['default_collection_url'])

  end

  # get the service document of this repo
  def servicedoc
    @theservicedoc = @connection.get(@connection.url).body if !@theservicedoc
    @theservicedoc
  end


  require 'rexml/document'
  # Must require ActiveRecord, as it adds the Hash.from_xml() method (used below)
  require 'active_record'
  # Parse the given SWORD Service Document.
  #
  # Returns a SwordClient::ParsedServiceDoc which contains
  # all information which was able to be parsed from
  # the SWORD Service Document
  def parse_service_doc(sd=servicedoc)

    # use SAX Parsing with REXML
    src = REXML::Source.new sd

    parser = Sword2Client::ServiceDocParser.new

    #parse Source Doc XML using our custom handler
    REXML::Document.parse_stream src, parser

    #return SwordClient::ParsedServiceDoc
    parser.parsed_service_doc
  end

  # get collection hash for collection url if it exists
  # pulls default information from the currently loaded service document
  def collection(collection_url,colls=@collections)

    # locate the requested collection, or find the default collection
    the_collection = nil
    colls.each do |c|
      the_collection = c if c['deposit_url'].to_s.strip == collection_url.to_s.strip
      break if the_collection
    end if !collection_url.nil?

    the_collection
  end

end