# create a multipart object by providing:
# an atom object (e.g. the .object generated from passing a metadata hash to atomentry.rb)
# a filepath to some content
# some extra headers if required

# then access the multipart object at .object
# or access the temp file directly from .tmp

require 'atom'
require 'tempfile'
require 'digest/md5'

class Sword2Client::MultiPart

  attr_accessor :filepath, :tmp

  # build a multipart object
  # expects a SwordClient::AtomEntry and a filepath
  def initialize(atom,filepath,headers={})
    # create an identifier in the atom object that points to the content part
    uniqueid = "unique_" + Time.now.to_i.to_s
    contenttype = ""
    atom.object.content = Atom::Content::Base.new(:src=>uniqueid,:type=>contenttype)

    # make a unique boundary identifer
    boundary = "========" + Time.now.to_i.to_s + "=="

    # create a new temp file on the system to make the multipart object
    @tmp = Tempfile.new('multipartfile_' + Time.now.to_i.to_s)

    # write boundary identifer to temp file
    @tmp << 'Content-Type: multipart/related; boundary="' + boundary + '"; type="application/atom+xml"' + "\r\n"
    @tmp << "MIME-Version: 1.0\r\n"
    @tmp << "--" + boundary + "\r\n"

    # write atomobject relevant headers to temp file
    @tmp << 'Content-Type: application/atom+xml; charset="utf-8"' + "\r\n"
    @tmp << 'Content-Disposition: attachment; name="atom"' + "\r\n"
    @tmp << "MIME-Version: 1.0\r\n\r\n"

    # write atomobject to temp file
    @tmp << atom.xml

    # write boundary identifier to temp file
    @tmp << "--#{boundary}\r\n"

    # write main content header to temp file
    @tmp << "Content-Type: " + contenttype + "\r\n"
    @tmp << 'Content-Disposition: attachment; name=payload; filename="' + File.basename(filepath).to_s + '"' + "\r\n"
    @tmp << "Packaging: #{headers["Packaging"]}\r\n" if headers.has_key?("Packaging")
    @tmp << "Content-MD5: " + Digest::MD5.hexdigest(File.read(filepath)) + "\r\n"
    @tmp << "MIME-Version: 1.0\r\n\r\n"

    # write the file base64 encoded to temp file
    infile = File.open(filepath,'r')
    while (line = infile.gets)
      @tmp << Base64.encode64(line)
    end
    infile.close

    # write boundary identifier to temp file
    @tmp << "--#{boundary}--"

    # write the temp file path
    @filepath = @tmp.path

    @tmp.close

  end


end