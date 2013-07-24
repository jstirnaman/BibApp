#require work and author name to be passed
xml.item do
  xml.title work['title']

  xml.description {
    xml.cdata!(work['type'])
    xml.cdata!(render(subclass_partial_for(work) + ".html.haml", :work => work))
    xml.cdata!(work['abstract']) if work['abstract']
  }

  xml.link work_url(:only_path => false, :id => work['id'].split("-")[1])

  xml.guid work_url(:only_path => false, :id => work['id'].split("-")[1])
  # Output names directly without Builder trying to escape them (and failing).
  # Ruby 1.9 throws exceptions if the string looks like ASCII and Builder
  # tries to wrap it in UTF-8.
  xml.author { xml << author_name }
end
