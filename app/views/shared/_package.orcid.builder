# Based on ORCID Message 1.1 for Works
xml.tag!('orcid-work') do
  xml.tag!('work-title', h(work.title_primary))
  xml.tag!('journal-title', (work.publication.name)) if work.publication_id.present?
  xml.tag!('short-description', h(work.abstract)) if work.abstract.present?
#   xml.tag!('work-citation') do
#     xml.tag!('work-citation-type', "formatted-apa")
#     xml.citation(h(apa)) unless apa.nil?
#   end
  xml.tag!('work-citation') do
    xml.tag!('work-citation-type', "bibtex")
    bibtex = export.drive_csl('bibtex', work).strip
    xml.citation(h(bibtex)) unless bibtex.nil?
  end  
  xml.tag!('work-type', to_orcid_type(work))
  xml.tag!('publication-date') do
    xml.year(h(work.year)) if work.year.present?
    xml.month(h(work.publication_date_month)) if work.publication_date_month.present?
  end
  xml.tag!('work-contributors') do
		if work.authors.present?
		  work.authors.each_with_index do |a, i|
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