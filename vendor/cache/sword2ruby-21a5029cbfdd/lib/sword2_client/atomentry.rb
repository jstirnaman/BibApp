# build an atom entry object by sending in a metadata array of ATOM info
# and optionally a sub-array of DC info

# then access the .xml to get the atom entry as xmk
# or access the .entry to get the Atom object

require 'atom'

class Sword2Client::AtomEntry

  attr_accessor :object

  # initialize with an array of info to go in an atom object
  # expects ATOM metadata at the top level, and a hash of dc metadata can also be provided
  def initialize( metadata = { "id" => "atomtestid", "authors" => ["Mark","Richard"], "dc" => { "title" => "dctesttitle" } } )

    entry = Atom::Entry.new do |entry|
      # add ATOM stuff
      entry.id = metadata["id"] if metadata.has_key?("id")
      entry.updated = metadata["updated"] if metadata.has_key?("updated")
      entry.published = metadata["published"] if metadata.has_key?("published")
      entry.title = metadata["title"] if metadata.has_key?("title")
      entry.summary = metadata["summary"] if metadata.has_key?("summary")
      entry.rights = metadata["rights"] if metadata.has_key?("rights")
      entry.source = metadata["source"] if metadata.has_key?("source")
      entry.content = metadata["content"] if metadata.has_key?("content")
      metadata["authors"].each { |author| entry.authors << Atom::Person.new(:name => author) } if metadata.has_key?("authors")
      metadata["contributors"].each { |contributor| entry.contributors << Atom::Person.new(:name => contributor) } if metadata.has_key?("contributors")
      metadata["links"].each { |link| entry.links << Atom::Link.new(:href => link) } if metadata.has_key?("links")
      metadata["categories"].each { |category| entry.links << Atom::Categories.new(:category => category) } if metadata.has_key?("categories")

      # add DCTERMS stuff - just presume passed keys are valid
      metadata["dc"].each { |key,value| entry["http://purl.org/dc/terms/", key] << metadata["dc"][key] } if metadata.has_key?("dc")
    end

    @object = entry
    
  end

  def xml
    @object.to_xml
  end

end

