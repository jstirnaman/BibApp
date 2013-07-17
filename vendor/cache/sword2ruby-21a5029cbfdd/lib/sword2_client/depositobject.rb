# create a deposit object

class Sword2Client::DepositObject

  attr_accessor :method, :on, :url, :filepath, :metadata, :repo, :atomentry, :multipart

  def initialize(method="get",on="collection",url=nil,filepath=nil,metadata={},heads={},repo=nil)

    # set defaults
    @method = method
    @on = on
    @url = url
    @filepath = filepath
    @metadata = metadata
    @supplied_heads = heads
    @repo = repo

    # build necessary parts - identify based on the information provided at init
    @atomentry = Sword2Client::AtomEntry.new(@metadata) if type != "file"
    @multipart = Sword2Client::MultiPart.new(@atomentry,@filepath,@supplied_heads) if type == "multipart"

    # raise exceptions if all required is not available
    raise SwordException, "could not find file at " + filepath if ( !filepath.nil? and !File.exists?(filepath) )
    #raise SwordException, "requested collection does not exist! - " + url if !url.nil? and repo.collection(url).nil? and @on == "collection"
    #raise SwordException, "the requested collection does not accept " + headers[packaging] if false

  end

  # return the type of object
  def type
    stype = "file"
    stype = "atom" if @filepath.nil? and !@metadata.empty?
    stype = "multipart" if !@filepath.nil? and !@metadata.empty?
    stype
  end

  # return the headers for this object
  # default User-Agent, auth and on-behalf-of are set at SwordClient::Connection.request
  # Content-Length is also set at SwordClient::Connection.request if required
  def headers(hds = @supplied_heads)

    case type
      when "file"
        case method
          when "post","put"
            hds['Content-Type'] ||= 'binary/octet-stream' if !hds.has_key?('Content-Type')
            hds['Content-MD5'] ||= Digest::MD5.hexdigest(File.read(@filepath)) if !hds.has_key?('Content-MD5')
            hds['Content-Disposition'] ||= "attachment; filename=" + File.basename(@filepath).to_s if !hds.has_key?("Content-Disposition")
            #hds['Packaging'] ||= "http://purl.org/net/sword/package/Binary" if !hds.has_key?('Packaging')            
        end

      when "atom"
        hds['Content-Type'] ||= "application/atom+xml"

      when "multipart"
        # for a multipart the headers are set in multipart
        # make sure content type, disposition, md5 is unset if in the incoming headers
    end

    hds
  end

  # return the object, depending on what is already available
  def object
    case type
      when "file" then @filepath
      when "atom" then @atomentry.xml
      when "multipart" then @multipart.filepath
    end
  end


  # GET collection ATOM description     url should be collection IRI
  # GET container ATOM receipt          url should be container edit IRI
  # GET container content               url should be container edit-media IRI
  # POST new package and/or metadata    url should be collection IRI
  # POST additional content             url should be container edit IRI
  # PUT new metadata                    url should be container edit IRI
  # PUT totally new content             url should be container edit-media IRI
  # DELETE container                    url should be container edit IRI
  # DELETE content (default)            url should be container edit-media IRI

  # return the URL required for the selected operation
  # either the edit IRI or the edit-media IRI or the collection IRI
  def target(method=@method,on=@on,url=@url)
    case on
      when "collection" then
        @targeturl = url
        @targeturl = @repo.default['deposit_url'] if @targeturl.nil? and ( method == "get" or method == "post" )
      when "edit" then
        @targeturl = url
      when "edit-media" then
        # get the em-link for this container
        dr = Sword2Client::DepositReceipt.new(url)
        @targeturl = dr.em_link
    end if !@targeturl
    # set the default collection url if nothing else available, and the action is safe, e.g. GET
    @targeturl
  end


end