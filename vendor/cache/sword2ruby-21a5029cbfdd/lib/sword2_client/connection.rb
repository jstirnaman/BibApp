# client connection to a sword Server
#

require 'net/https'

class Sword2Client::Connection
  
  # URL of SWORD Server (actually URL of service document), and the persistent connection to it
  attr_reader :url, :connection
  
  # Timeout for our connection
  attr_reader :timeout
  
  #User Name & Password to Authenticate with
  attr_writer :username, :password
  
  # If depositing on behalf of someone else, this is his/her username
  attr_accessor :on_behalf_of
  
  # Proxy Settings to use for all requests (if necessary)
  # This is a hash including {:server, :port, :username, :password}
  attr_accessor :proxy_settings


  
  # Initialize a connection to a SWORD Server instance, whose Service Document
  #   is located at the URL specified.  This does *not* request the
  #   Service Document, it just initializes a Connection with information.
  #
  #   conn = Sword::Connection.new("http://example.com:8080/sword-app/servicedocument")
  #
  # Options available:
  #    :username => User name to connect as
  #    :password => Password for user
  #    :on_behalf_of => Connect on behalf of another user
  #    :timeout => specify connection timeout (in seconds)
  #    :proxy_settings => Proxy Server Settings
  #                      Hash which may include (only :server is required):
  #                      {:server   => name of proxy server, 
  #                       :port     => port on proxy server,
  #                       :username => login name for proxy server, 
  #                       :password => password for proxy server}
  #    :debug_mode => Set to true to log all HTTP request/responses to STDERR                   
  #
  def initialize(service_doc_url="http://sss.cottagelabs.com/sd-uri", opts={})
    @url = URI.parse(service_doc_url)
    raise SwordException, "URL for Service Document seems to be an invalid HTTP URL: #{service_doc_url}" unless @url.kind_of? URI::HTTP
  
    # load username / password / on_behalf_of, if specified
    @username = opts[:username] if opts[:username]
    @password = opts[:password] if opts[:password]
    @on_behalf_of = opts[:on_behalf_of] if opts[:on_behalf_of]

    # set up the persistent connection.
    @connection = Net::HTTP.new(@url.host, @url.port)

    # setup proxy if necessary
    if opts[:proxy_settings]
      @proxy_settings = opts[:proxy_settings]
      @connection.proxy(@proxy_settings[:server], @proxy_settings[:port], @proxy_settings[:username], @proxy_settings[:password])
    else

    end

    #set to SSL if HTTPS connection
    @connection.use_ssl = @url.scheme == "https" 
    @connection.verify_mode = OpenSSL::SSL::VERIFY_NONE #turn off SSL verify mode
    
    #setup connection timeout, if specified
    @connection.read_timeout = opts[:timeout] if opts[:timeout]
    
    #If debug mode, turn on debugging of HTTP request/response
    @connection.set_debug_output(STDERR) if opts[:debug_mode]

  end


  # GET collection ATOM description - url should be collection IRI
  # GET container ATOM receipt - url should be container edit IRI
  # GET container content - url should be container edit-media IRI
  def get(url,headers={})

    dorequest("get",url,nil,headers)

  end


  # POST new package and/or metadata - url should be collection IRI
  # POST additional content - url should be container edit IRI
  def post(object,url,headers={})

    dorequest("post",url,object,headers)

  end


  # PUT new metadata - url should be container edit IRI
  # PUT totally new content - url should be container edit-media IRI
  def put(object,url,headers={})

    dorequest("put",url,object,headers)

  end


  # DELETE container - url should be container edit IRI
  # DELETE content - url should be container edit-media IRI
  def delete(url)

    dorequest("delete",url)

  end


  # private methods
  #private
  

  # wrap request in a redirect follower, up to 10 levels by default
  def dorequest(verb,path,body = nil,headers = {},limit = 10)
    raise SwordException, 'HTTP redirection is too deep...cannot retrieve requested path: ' + path if limit == 0
    response = request(verb,path,body,headers)
    #determine response
    case response
      when Net::HTTPSuccess     then response
      when Net::HTTPRedirection then dorequest(verb,response['location'],body,headers,limit - 1)
    else
      response.error!
    end
  end

  # send request to the sword server
  def request(verb,path,content,headers = {},attempts = 0,&block)

    # get the content open for sending
    if !content.nil? and File.exists?(content)
      if headers.has_key?('Content-Type')
        if headers['Content-Type'].match('^text\/.*') #check if MIME Type begins with "text/"
          body = File.open(content) # open as normal (text-based format)
        else
          body = File.open(content, 'rb') # open in Binary file mode
        end
      else
        body = File.open(content, 'rb') # open in Binary file mode
      end
    else
      body = content
    end

    # If body was already read once, may need to rewind it
    body.rewind if body.respond_to?(:rewind) unless attempts.zero?      
    
    # build "request" procedure
    requester = Proc.new do 

      # init request type
      request = Net::HTTP.const_get(verb.to_s.capitalize).new(path.to_s, headers)

      # set standard auth request headers
      request['User-Agent'] ||= "Ruby SWORD Client"
      request.basic_auth @username, @password if @username and @password
      request['On-Behalf-Of'] ||= @on_behalf_of.to_s if @on_behalf_of

      if body
        # if body can be read, stream it
        if body.respond_to?(:read)                                                                
          request.content_length = body.respond_to?(:lstat) ? body.lstat.size : body.size
          request.body_stream = body
        else
          # otherwise just add as is
          request.body = body                                                                     
        end
      end
      
      @connection.request(request, &block)
    end
    
    # do the request
    @connection.start(&requester)
  rescue Errno::EPIPE, Timeout::Error, Errno::EPIPE, Errno::EINVAL
    # try 3 times before failing altogether
    attempts == 3 ? raise : (attempts += 1; retry)
  rescue Errno::ECONNREFUSED => error_msg
    raise SwordException, "connection to sword Server (path='#{path}') was refused! Is it up?\n\nUnderlying error: " + error_msg
  end

end