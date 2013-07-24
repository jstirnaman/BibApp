require File.expand_path('../application', __FILE__)
Bibapp::Application.initialize!
Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

# Override solr.rb settings in favor of Solr Multicore
# Solr core to use. Default to core1
SOLR_CORE = ENV['CORE_N'] || 1
SOLR_CORE = "1" unless defined? SOLR_CORE

# Build our Solr URL for Multicore setup
SOLR_URL = "http://127.0.0.1:#{SOLR_PORT}/solr/#{Rails.env}-core#{SOLR_CORE}"

# Solr Connection (used by /app/models/index.rb)
SOLRCONN = Solr::Connection.new(SOLR_URL)

SOLR_JAVA_OPTS = "-Xms1024M -Xmx1024M"
