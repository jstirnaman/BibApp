#Abstraction of Person lookup by web service to replace LDAP functionality used by BibApp
require 'singleton'
require 'savon'
require 'nokogiri'

class AuthorWebservice
  include Singleton

  attr_accessor :config
  attr_accessor :connection_parameters

  def initialize(args = {})
     self.config = YAML::load(File.read("#{Rails.root}/config/directory_service.yml"))[Rails.env]
     raise StandardError if self.config.blank?
    self.initialize_connection_parameters
  end

  def initialize_connection_parameters
     if self.config['wsdl'].present?
       params = {:service_address => config['wsdl']}
     end
     if self.config['namespace'].present?
       params[:namespace] = config['namespace']
     end     
     if self.config['username'].present? and self.config['password'].present?
       params[:auth] = {:method => :basic_auth, :username => config['username'], :password => config['password']}
     end
     if self.config['token'].present?
       params[:auth].merge({:token => config['authToken']})
     end
     @conn_params = params
  end

  def get_connection
    Savon.client(wsdl: @conn_params[:service_address], 
      soap_version: 2,
      namespace_identifier: :dir,
      soap_header: { "dir:SecuredWebServiceHeader" => {"dir:Username" => @conn_params[:auth][:username],
                                                       "dir:Password" =>  @conn_params[:auth][:password],
                                                       "dir:AuthenticatedToken" => @conn_params[:auth][:token] || '' }})
    rescue Savon::Error => e
      log e.to_s
  end
  
  def search(query)
    client = self.get_connection
    response = client.call(:get_users_by_name, message: {"dir:foo" => query})
    # Person data comes back as SOAP-wrapped CDATA-encoded XML doc.
    resultsnode = Nokogiri::XML.parse(response.body[:get_users_by_name_response][:get_users_by_name_result])
    # Convert to an array of person hashes. This mirrors ldap_search results so
    # it behaves as a "drop-in" replacement for LDAP and we can reuse the same .clean method
    # and views.
    entries = resultsnode.xpath('/SearchResults//person').map do |p|
      Hash[p.children.map {|a| [a.attr('name'), [a.content]]}]
    end
    entries.map! {|e| clean(e)}     
    rescue Savon::Error => e
      raise e.message
  end

  def clean(entry)
    Hash.new.tap do |res|
      entry.each do |key, val|
        #res[key] = val[0]
        # map university-specific values
        if config.has_value? key.to_s
          k = config[key.to_s].to_sym
          res[k] = val[0]
          res[k] = NameCase.new(val[0]).nc! if [:sn, :givenname, :middlename, :generationqualifier, :displayname].include?(k)
          res[k] = val[0].titleize if [:title, :ou, :postaladdress].include?(k)
        end
      end
    end
  end
end
