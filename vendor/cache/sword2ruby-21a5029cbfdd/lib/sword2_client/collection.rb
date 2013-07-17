# parse a SWORD collection document

require 'atom'

class Sword2Client::Collection

  attr_accessor :source, :collection

  # given a collection url, read it and get the edit links to the items in the collection
  def initialize(source)

    @collection = nil
    @source = source

    # assume URI
    begin
      @collection = Atom::Feed.load_feed(URI.parse(@source))
    rescue Exception=>e
    end

    # assume file
    begin
      infile = File.open(@source)
      cont = infile.read
      infile.close
      @collection = Atom::Feed.load_feed(cont)
    rescue Exception=>e
    end if @collection.nil?

    # assume string
    begin
      @collection = Atom::Feed.load_feed(@source)
    rescue Exception=>e
    end if @collection.nil?

    raise SwordException, "source provided could not be parsed as ATOM" if @collection.nil?

  end


  # return a list of the URLs to the items in this collection
  def items(collection = @collection)

    links = Array.new

    collection.entries.each { |entry| links << entry.edit_link.to_s }

    links
  end


end