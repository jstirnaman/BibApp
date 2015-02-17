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

# Get records from the Identity Management report
#  -- accounts added to ORCID since the last digest.
def local_orcids
  # CSV table of row objects
  # ex. puts rows[1][:orcid]
  rows = CSV.table('/Users/jstirnaman/dev/orcid/orcid.csv')
end

# GET orcid_id
# Returns the fields set as "Public" in the bio portion of the ORCID Record for the scholar represented by the specified orcid_id. 
# When used with an access token and the Member API, limited-access data is also returned.
# (NOTE: The same results are returned for orcid_id/orcid-bio.)
def bio(orcid_id)
  self.class.get("/#{orcid_id}/orcid-bio",
           @options)
end

# GET orcid_id/orcid-works
# Returns "works" research activities set as "Public"
# and belonging to orcid_id.
# Limited-access "works" are also returned if as_member
# is called with an access token.
def works(orcid_id, options)
  self.class.get("/#{orcid_id}/orcid-works")
end

# POST orcid_id/orcid-works
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

def validate(xmldocs, version)
	version ||= ORCID_VERSION
	schema_file = "orcid-message-#{version}.xsd"
	result = {}
	xsd = Nokogiri::XML::Schema(File.read(schema_file))
	xmldocs = xmldocs.class == Array ? xmldocs : [xmldocs]
	xmldoc = nil
	xmldocs.each do |xml|
	  case URI.parse(xml)
	    when URI::HTTP
        xmldoc = Nokogiri::XML(self.class(xml).body)
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

  end
end
