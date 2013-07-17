# class for parsing a deposit receipt

require 'atom'

class Sword2Client::DepositReceipt

  attr_accessor :source, :receipt

  # read a deposit receipt - accepts a filepath, a URI or a string
  def initialize(source)

    @receipt = nil
    @source = source

    # assume URI
    begin
      @receipt = Atom::Entry.load_entry(URI.parse(@source))
    rescue Exception=>e
    end

    # assume file
    begin
      infile = File.open(@source)
      cont = infile.read
      infile.close
      @receipt = Atom::Entry.load_entry(cont)
    rescue Exception=>e
    end if @receipt.nil?

    # assume string
    begin
      @receipt = Atom::Entry.load_entry(@source)
    rescue Exception => e
      exception = SwordDepositReceiptParseException.new
      exception.source_xml = @source
      raise exception
    end if @receipt.nil?

    raise SwordException, "source provided could not be parsed as ATOM" if @receipt.nil?

  end


  # edit link
  def edit_link
    @receipt.edit_link.to_s
  end


  # extend ratom to have an edit-media link identifier
  def em_link
    @receipt.links.detect { |link| link.rel == 'edit-media' }.to_s
  end

end


