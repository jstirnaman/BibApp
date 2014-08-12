locator = link_to_findit(work)
locator = locator.gsub(/<a\shref="/, "")
locator = locator.gsub(/">Find It<\/a>/, "")

peer_reviewed = ""
unless work.peer_reviewed.nil?
  peer_reviewed = work.peer_reviewed == true ? "true" : "false"
end
# ORCID Message 1.1 for Works:
# <orcid-work>
#   <work-title>
#     <title>API Test Title</title>
#     <subtitle>My Subtitle</subtitle>
#     <translated-title language-code="fr">API essai Titre</translated-title>
#   </work-title>
#   <journal-title>Journal Title</journal-title>
#     <work-contributors>
#     <contributor>
#       <credit-name>LastName, FirstName</credit-name>
#       <contributor-attributes>
#         <contributor-sequence>first</contributor-sequence>
#         <contributor-role>author</contributor-role>
#       </contributor-attributes>
#     </contributor>
#   </work-contributors>
#   <language-code>en</language-code>
#   <short-description>My Abstract</short-description>
#     <publication-date>
#     <year>2010</year>
#     <month>11</month>
#   </publication-date>
#     <work-external-identifiers>
#     <work-external-identifier>
#       <work-external-identifier-type>other-id</work-external-identifier-type>
#       <work-external-identifier-id>1234</work-external-identifier-id>
#     </work-external-identifier>
#   </work-external-identifiers>
#   <url>www.orcid.org</url>
#     <work-citation>
#     <work-citation-type>formatted-apa</work-citation-type>
#     <citation>My correctly formatted citation</citation>
#   </work-citation>
#             <work-type>journal-article [one of http://support.orcid.org/knowledgebase/articles/118795]</work-type>
# </orcid-work>
export = WorkExport.new
export.formatter = 'text'
apa = export.drive_csl('apa', work).strip
bibtex = export.drive_csl('bibtex', work).strip

def to_orcid_type(work)
  orcid_types = {
    "JournalArticle" => "journal-article"
  }
  orcid_types[work.type]
end

xml.tag!('orcid-work') do
  xml.tag!('work-title', h(work.title_primary))
  xml.tag!('journal-title', (work.publication.name)) if work.publication_id.present?
  xml.tag!('short-description', h(work.abstract)) if work.abstract.present?
  xml.tag!('work-citation') do
    xml.tag!('work-citation-type', "formatted-apa")
    xml.citation(h(apa))
  end
  xml.tag!('work-citation') do
    xml.tag!('work-citation-type', "bibtex")
    xml.citation(h(bibtex))
  end  
  xml.tag!('work-type', to_orcid_type(work))
  xml.tag!('publication-date') do
    xml.year(h(work.year)) if work.year.present?
    xml.month(h(work.publication_date_month)) if work.publication_date_month.present?
  end
  xml.tag!('work-contributors') do
		if work.authors.present?
		  work.authors.each_with_index do |a, i|
		  # If we have ORCID iD in the request, use it.
		  # Otherwise, last_name, first_name
  		  xml.contributor do
  		    xml.tag!('credit-name', a[:name])
  		    xml.tag!('contributor-sequence', i == 0? "first" : "additional")
  		    xml.tag!('contributor-role', "author")
  		  end
			end
		end
	end
	if work.links.present?
	  xml.tag!('work-external-identifiers') do
	    split_potential_links(work).each do |link|
	      if doi = looks_like_doi(link)
	        xml.tag!('work-external-identifier') do
	          xml.tag!('work-external-identifier-type', "doi")
	          xml.tag!('work-external-identifier-id', doi)
	        end
	      elsif pmid = looks_like_pmid(link)
	        xml.tag!('work-external-identifier') do
	          xml.tag!('work-external-identifier-type', "pmid")
	          xml.tag!('work-external-identifier-id', pmid)
	        end
	      end
	    end
	  end
	end
	xml.tag!('language-code', "en")
end


# xml.rdf(:Description, 'rdf:about'=>"#{work_url(work)}") do
#   xml.rdf(:type, 'rdf:resource'=>"http://purl.org/ontology/bibo/Document")
#   if work.authors.present?
#     xml.bibo(:authorList) do
#       xml.rdf(:Seq) do
#         work.authors.each do |a|
#           xml.rdf(:li, a[:name])
#         end
#       end
#     end
#   end
#   if work.editors.present?
#     xml.bibo(:editorList) do
#       xml.rdf(:Seq) do
#         work.editors.each do |e|
#           xml.rdf(:li, e[:name])
#         end
#       end
#     end
#   end
#   xml.core(:title, h(work.title_primary))
#   if work.abstract.present?
#     xml.bibo(:abstract, h(work.abstract))
#   end
#   if work.publication_id.present?
#     xml.core(:publishedInTitle, (work.publication.name))
#     xml.core(:publishedIn, 'rdf:resource' => publication_url(work.publication))
#   end
#   if work.year.present?
#     xml.core(:year, {'rdf:datatype'=>"http://www.w3.org/2001/XMLSchema#gYear"}, h(work.year))
#   end
#   if work.start_page.present?
#     xml.bibo(:pageStart, {'rdf:datatype'=>"http://www.w3.org/2001/XMLSchema#int"}, work.start_page)
#   end
#   if work.end_page.present?
#     xml.bibo(:pageEnd, {'rdf:datatype'=>"http://www.w3.org/2001/XMLSchema#int"}, h(work.end_page))
#   end
#   if peer_reviewed.present?
#     xml.core(:refereedStatus, {'rdf:datatype'=>"http://www.w3.org/2001/XMLSchema#boolean"}, peer_reviewed)
#   end
#   if work.links.present?
#     xml.bibo(:doi, {'rdf:datatype'=>"http://www.w3.org/2001/XMLSchema#string"}, h(work.links))
#   end
#   xml.core(:localLibraryLink, {'rdf:datatype'=>"http://www.w3.org/2001/XMLSchema#string"}, locator)
#   xml.bibo(:coins, {'rdf:datatype'=>"http://www.w3.org/2001/XMLSchema#string"}, h(coin(work)))
#   xml.vitro(:timekey, {'rdf:datatype'=>"http://www.w3.org/2001/XMLSchema#dateTime"}, work.created_at)
#   xml.vitro(:modTime, {'rdf:datatype'=>"http://www.w3.org/2001/XMLSchema#dateTime"}, work.updated_at)
#   if work.people.present?
#     xml.core(:informationResourceInAuthorship, {'rdf:resource' => "#{work_url(work)}#Authorship"})
#   end
# end
# 
# xml.rdf(:Description, {'rdf:about'=>"#{work_url(work)}#Authorship"}) do
#   xml.rdf(:type, {'rdf:resource'=>"http://vivoweb.org/ontology/core#Authorship"})
#   xml.core(:linkedInformationResource, {'rdf:resource'=> work_url(work)})
#   work.people.each do |p|
#     xml.core(:linkedAuthor, {'rdf:resource'=> person_url(p)})
#   end
# end
