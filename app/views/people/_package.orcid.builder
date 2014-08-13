xml.tag!("message-version", "1.1")
xml.tag!("orcid-profile") do
	xml.tag!("orcid-bio") do
	  xml.tag!("personal-details") do
	  	xml.tag!("given-names", @person.first_name)
		  xml.tag!("family-name", @person.last_name)
		  xml.tag!("other-names") do		    
 		    pen_names = @person.pen_names.map do |pen_name| 
		      NameString.find(pen_name.name_string_id).name
		    end
		    pen_names.uniq.each do |ns|
 		        xml.tag!("other-name", ns)
		    end
		  end 
	  end
### Example for adding keywords
# 	  xml.tag!("keywords") do
# 	    @person.works.map{|w| w.keywords.map{|k| k.name}}.flatten.uniq.each do |keyword|
# 	      xml.tag!("keyword", keyword)
# 	    end
# 	  end
###
		xml.tag!("external-identifiers") do
			xml.tag!("external-identifier") do
				xml.tag!("external-id-orcid", $ORCID_CLIENT_ID)
				xml.tag!("external-id-common-name", "#{t('personalize.university_full_name')} (#{t('personalize.university_short_name')}) #{t('personalize.application_name')}")
				xml.tag!("external-id-reference", @person.id)
				xml.tag!("external-id-url", person_url(@person))
			end
		end
	end
	xml.tag!("orcid-activities") do
		xml.tag!("orcid-works", 'visibility' => "public") do
			person.works.each do |w|
				xml << render(:partial => "shared/package", :locals => {:work => w}) 
			end      
		end
	end
end


# ORCID Message 1.1 for Works:
# <message-version>1.1</message-version>
#   <orcid-profile>
#     <orcid-activities>
#       <orcid-works visibility="public">
#           <orcid-work>
#             <work-title>
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
#           </orcid-work>
#         </orcid-works>
#     </orcid-activities>
#   </orcid-profile>
# </orcid-message>

