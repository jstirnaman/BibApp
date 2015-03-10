require 'uri'
require 'csv'
require 'httparty'
require 'nokogiri'

###### Retrieving Public Data, i.e. not using Member API and OAuth.
### Search API.
## /search/orcid-bio?[Solr search] returns public bio data as <orcid-search-result>
### Query API.
## /[orcid-id]/orcid-bio returns public bio data as <orcid-profile>

module Orcid
  include HTTParty

  class OrcidParser < HTTParty::Parser
# Set a parser for the orcid+xml - vanilla xml.
  SupportedFormats = {"application/orcid+xml" => :orcid_xml}

    def orcid_xml
      MultiXml.parse(body)
    end
  end

  class OrcidApi
    include HTTParty
# ORCID Public Sandbox API base URI
ORCID_SB_PUBLIC = 'https://pub.sandbox.orcid.org'

#ORCID Member Sandbox API base URI
ORCID_SB_MEMBER = 'https://api.sandbox.orcid.org'

# ORCID API Version
ORCID_VERSION = '1.2'
ORCID_API_VERSION = '/v1.2/'
######

parser Orcid::OrcidParser

def orcid_version(version = ORCID_VERSION)
  version
end
# Defaults to Public API
base_uri ORCID_SB_PUBLIC + ORCID_API_VERSION
@options = {}

def member_base_uri
  self.class.base_uri ORCID_SB_MEMBER + ORCID_API_VERSION
end

def as_member(token)
  if token
    @options = {:headers => {"Authorization" => "Bearer " + token}}
    member_base_uri
  end
end

# Get records from a Identity Management report
#  -- accounts added to ORCID since the last digest.
def local_orcids
  # CSV table of row objects
  # ex. puts rows[1][:orcid]
  rows = CSV.table('/Users/jstirnaman/dev/orcid/orcid.csv')
end

### Scopes
  def bio_read_scope
    '/orcid-bio/read-limited'
  end

  def works_create_scope
    '/orcid-works/create'
  end

  def affiliations_create_scope
    '/affiliations/create'
  end

  def external_id_create_scope
    '/orcid-bio/external-identifiers/create'
  end

### GET
def bio(orcid_id)
  self.class.get("/#{orcid_id}/orcid-bio",
           @options)
end

def works(orcid_id, options)
  self.class.get("/#{orcid_id}/orcid-works")
end

### APPEND
def post_external_id(orcid_id, options)
  o = @options
  o[:headers].merge!({"Content-Type" => "application/orcid+xml"})
  o[:base_uri] = ORCID_SB_MEMBER + ORCID_API_VERSION
  options  = o.merge(options)
  req = self.class::Request.new(Net::HTTP::Post, "#{orcid_id}/orcid-bio/external-identifiers", options)
  res = req.perform
  if res.code >= 300
    res.inspect
  end
end

def post_affiliations(orcid_id, options)
  o = @options
  o[:headers].merge!({"Content-Type" => "application/orcid+xml"})
  o[:base_uri] = ORCID_SB_MEMBER + ORCID_API_VERSION
  options  = o.merge(options)
  req = self.class::Request.new(Net::HTTP::Post, "#{orcid_id}/affiliations", options)
  res = req.perform
  if res.code >= 300
    res.inspect
  end
end

def post_works(orcid_id, options)
  o = @options
  o[:headers].merge!({"Content-Type" => "application/orcid+xml"})
  o[:base_uri] = ORCID_SB_MEMBER + ORCID_API_VERSION
  options  = o.merge(options)
  req = self.class::Request.new(Net::HTTP::Post, "#{orcid_id}/orcid-works", options)
  res = req.perform
  if res.code >= 300
    res.inspect
  end
end

# GET /search/orcid-bio?[Solr search]
# Returns search results
def search(q)
  self.class.get("/search/orcid-bio?q=#{q}")
end

def validate(xmldocs, version = ORCID_VERSION)
  orcid_schema_path = "https://raw.githubusercontent.com/ORCID/ORCID-Source/master/orcid-model/src/main/resources/"
  orcid_schema_url = orcid_schema_path + "orcid-message-#{version}.xsd"
  schema_file = cache_schema(orcid_schema_url)
	result = {}
	xsd = Nokogiri::XML::Schema(schema_file)
	xmldocs = xmldocs.class == Array ? xmldocs : [xmldocs]
	xmldoc = nil
	xmldocs.each do |xml|
	  case URI.parse(xml)
	    when URI::HTTP
        xmldoc = Nokogiri::XML(self.class.get(xml).body)
		  when URI::Generic
				xmldoc = Nokogiri::XML(File.read(xml))
    end
    result[xml]=[]
		xsd.validate(xmldoc).each do |error|
			result[xml] << error.message
		end
	end
	result
end

def cache_schema(url)
  if Rails
    Rails.cache.fetch(url, expires_in: 24.hours) do
      response = self.class.get(orcid_schema_url)
      schema_file = response.body.gsub(/\>\s*\n\s*\</,'><').strip()
      if schema_file.success?
        schema_file
      else
        raise response.message
      end
    end
  end
end

end
end
