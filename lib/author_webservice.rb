#Abstraction of Person lookup by web service to replace LDAP functionality used by BibApp
require 'singleton'
require 'savon'
require 'nokogiri'

class AuthorWebserviceError < Savon::Error
end
class AuthorWebserviceConfigError < AuthorWebserviceError
end
class AuthorWebserviceConnectionError < AuthorWebserviceError
end

class AuthorWebservice
  include Singleton

  attr_accessor :config
  attr_accessor :connection_parameters

  def initialize(args = {})
     self.config = YAML::load(File.read("#{Rails.root}/config/directory_service.yml"))[Rails.env]
     raise AuthorWebserviceConfigError if self.config.blank?
    self.initialize_connection_parameters
  end

  def initialize_connection_parameters
     if self.config['wsdl'].present?
       parameters = {:service_address => config['wsdl']}
     end
     if self.config['namespace'].present?
       parameters[:namespace] = config['namespace']
     end     
     if self.config['username'].present? and self.config['password'].present?
#       parameters[:encryption] = :simple_tls
       parameters[:auth] = {:method => :simple, :username => config['username'], :password => config['password']}
     end
     if self.config['token'].present?
       parameters[:auth] << {:token => config['authToken']}
     end
     self.connection_parameters = parameters
  end

  def get_connection
#     Net::LDAP.new(self.connection_parameters).tap do |ldap|
#       raise BibappLdapConnectionError unless ldap.bind
#     end
    Savon.client(self.connection_parameters[:service_address])
  end
  
  def search(query)
    client = self.get_connection
    response = client.request :dir, :get_users do
      soap.version = 1
      # Namespacing required for authentication.
      soap.namespaces["xmlns:dir"] = self.connection_parameters[:namespace]
      # Authentication.
      # TODO: Not sure the best way to abstract this out, or if it's worth it to do so.
      soap.header = { "dir:SecuredWebServiceHeader" => { 
                    "dir:Username" => self.connection_parameters[:auth][:username], 
                    "dir:Password" => self.connection_parameters[:auth][:password],  
                    "dir:AuthenticatedToken" => self.connection_parameters[:auth][:token] || '' }}
      soap.body = { "dir:foo" => query}
     end
    
    # Person data comes back as SOAP-wrapped CDATA-encoded XML doc.
    resultsnode = Nokogiri::XML(response[:get_users_response][:get_users_result])    
    # Convert to an array of person hashes. This mirrors ldap_search results so
    # we can reuse the same .clean method.
    entries = resultsnode.xpath('/SearchResults//person').map do |p|
      Hash[p.children.map {|a| [a.attr('name'), [a.content]]}]
    end
    
    STDERR.puts entries
     
    entries.map! {|e| clean(e)}
     
    rescue AuthorWebserviceError => e
      raise AuthorWebserviceError(e.message)
  end

  def clean(entry)
    Hash.new.tap do |res|
      entry.each do |key, val|
        #res[key] = val[0]
        # map university-specific values
        if config.has_value? key.to_s
          k = config.index(key.to_s).to_sym
          res[k] = val[0]
          res[k] = NameCase.new(val[0]).nc! if [:sn, :givenname, :middlename, :generationqualifier, :displayname].include?(k)
          res[k] = val[0].titleize if [:title, :ou, :postaladdress].include?(k)
        end
      end
    end
  end


end