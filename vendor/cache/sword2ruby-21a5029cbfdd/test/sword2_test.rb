# tests the sword2_client ruby client against a sword2_client server

require 'fileutils'
require 'test/unit'
require "#{File.expand_path(File.dirname(__FILE__))}/../lib/sword2_client.rb"


class Sword2test < Test::Unit::TestCase

  # set a test server to test against if so desired
  # probably in sword.yml anyway
  # but to get tests to pass without sword.yml config, set here


  TEST_SERVICE_DOC = "http://localhost:8080/sd-uri"
  TEST_SWORD_UN = "sword"
  TEST_SWORD_PW = "sword"
  TEST_DEFAULT_COLLECTION = "http://localhost:8080/col-uri/default"

  '
  TEST_SERVICE_DOC = "http://or11demo.swordapp.org/sword2/servicedocument"
  TEST_SWORD_UN = "richard@cottagelabs.com"
  TEST_SWORD_PW = "rjsword"
  TEST_DEFAULT_COLLECTION = "http://or11demo.swordapp.org/sword2/collection/123456789/2"
  '

  TEST_FIXTURES_DIR = "#{File.expand_path(File.dirname(__FILE__))}/fixtures"
  TEST_OUTPUT_DIR = "#{File.expand_path(File.dirname(__FILE__))}/fixtures/test_outputs"

  # setup for test
  def setup
    @config = {
            "username" => TEST_SWORD_UN,
            "password" => TEST_SWORD_PW,
            "service_doc_url" => TEST_SERVICE_DOC,
            "default_collection_url" => TEST_DEFAULT_COLLECTION
            }
  end

  # make a connection
  def test_connection
    conn = Sword2Client::Connection.new(TEST_SERVICE_DOC, @config )
    assert conn.class == Sword2Client::Connection
  end

  # test the sword client can be started from details in sword.yml
  def test_swordclient
    sword = Sword2Client.new
    assert sword.class == Sword2Client
  end

  # test to get the repo details
  def test_repo
    sword = Sword2Client.new(nil,@config)
    assert sword.repo.servicedoc
    assert sword.repo.parsedoc
    assert sword.repo.class == Sword2Client::Repository
  end

  # test an atomentry can be made
  # find the created test object in the test_outputs directory
  def test_atomentry
    atom = Sword2Client::AtomEntry.new
    File.open("#{TEST_OUTPUT_DIR}/atom.xml", "w"){ |f| f << atom.xml}
    assert_not_nil atom
  end

  # test a multipart object can be made
  # find the created test object in the test_outputs directory
  def test_multipart
    atom = Sword2Client::AtomEntry.new
    multi = Sword2Client::MultiPart.new(atom,"#{TEST_FIXTURES_DIR}/example.zip")
    FileUtils.cp(multi.filepath,"#{TEST_OUTPUT_DIR}/multi.dat")    
    assert_not_nil multi
  end

  # test a simple post to the repo
  def test_post
    sword = Sword2Client.new(nil,@config)
    posted = sword.execute("post","collection",nil,"#{TEST_FIXTURES_DIR}/example.zip")
    assert_not_nil posted
  end

  # test sending data to a repo
'  def test_content_operations
    metadata = {"identifier" => "ID", "title" => "my great book", "author" => "the great author"}
    sword = SwordClient.new

    # send a new collection and get edit-IRI back
    posted = sword.execute("post","collection",TEST_DEFAULT_COLLECTION,"#{TEST_FIXTURES_DIR}/example.zip",metadata)
    assert_not_nil posted

    # send new atom entry to the repo
    newatom = sword.execute("put","edit",posted,metadata)
    assert_not_nil newatom

    # post more content to the container
    more = sword.execute("post","edit",posted,"#{TEST_FIXTURES_DIR}/sample.odt")
    assert_not_nil more

    # replace the container content
    replaced = sword.execute("put","edit-media",posted,"#{TEST_FIXTURES_DIR}/example.zip")
    assert_not_nil replaced

    # test deleting the content
    empty = sword.execute("delete","edit-media",posted)
    assert_not_nil empty

    # test deleting the container
    deleted = sword.execute("delete","edit",posted)
    assert_not_nil deleted

    # test it is not there any more
    gone = sword.execute("get","edit",posted)
    assert gone == ""

  end
'

end

