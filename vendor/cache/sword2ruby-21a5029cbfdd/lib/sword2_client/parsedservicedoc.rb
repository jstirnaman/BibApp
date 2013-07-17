# ParsedServiceDoc
#
# this class gives an object that contains the parsed contents
# of a SWORD Service Document.
#
class Sword2Client::ParsedServiceDoc

  # SWORD version & other top level properties specified in Service Doc
  attr_accessor :version, :verbose, :max_upload_size, :collections, :repository_name, :no_op

  #Array of collections found in Service Doc
  # Each Parsedcollection is represented by a Hash
  # of the following general structure
  # (which mirrors SWORD structure under <collection> tag):
  #
  #   {'title' => <Parsedcollection Title>,
  #    'abstract' => <Parsedcollection Description>,
  #    'deposit_url' => <Parsedcollection Deposit URL>,
  #    'accept' => <Accepted MIME Types>,
  #    'acceptPackaging' =>
  #         {'rank' => <format rank between 0-1>,
  #          'value' => <Accepted package format> },
  #    'collectionPolicy' => <Parsedcollection License / Policy>,
  #    'mediation' => <Whether or not Mediation is supported>,
  #    'treatment' => <SWORD treatment statement> }

  # what about new ones:
# <accept alternate="multipart-related">*/*</accept>
# <sword:service>http://localhost/sss/sd-uri/00505887-49ec-4f16-9a6c-61f99cf84bda</sword:service>

  def initialize
    #initialize collection array
    @collections = []
  end

end

