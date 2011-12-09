require File.expand_path('../application', __FILE__)
Bibapp::Application.initialize!

# Override solr.rb settings in favor of Solr Multicore
# Solr core to use. Default to core1
SOLR_CORE = ENV['CORE_N'] || 1
SOLR_CORE = "1" unless defined? SOLR_CORE

# Build our Solr URL for Multicore setup
SOLR_URL = "http://localhost:#{SOLR_PORT}/solr/#{[Rails.env]}-core#{SOLR_CORE}"

# Solr Connection (used by /app/models/index.rb)
SOLRCONN = Solr::Connection.new(SOLR_URL)

SOLR_JAVA_OPTS = "-Xms1024M -Xmx1024M"