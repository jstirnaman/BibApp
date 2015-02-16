orcid_document_on(xml) do
  (xml << render(:partial => "people/package", :locals => {:person => @person})) if @person
end
