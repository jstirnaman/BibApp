# Be sure to restart your server when you modify this file.

# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf
# Mime::Type.register_alias "text/html", :iphone

#### Register METS as XML MIME Type, so we can provide RESTful METS ####
Mime::Type.register_alias "text/xml", :mets

#### Register RDF as XML MIME Type, so we can provide RESTful RDF ####
Mime::Type.register_alias "text/xml", :rdf

#### Register RSS as XML MIME Type, so we can provide RESTful RSS ####
Mime::Type.register_alias "application/rss+xml", :rss

#### Register  as XML MIME Type, so we can provide RESTful Google Promotions for Google Custom Search ####
Mime::Type.register_alias "text/xml", :googlepromotions

#### Register ORCID-XML as XML MIME Type, so we can provide RESTful ORCID-XML ####
Mime::Type.register_alias "application/orcid+xml", :orcid