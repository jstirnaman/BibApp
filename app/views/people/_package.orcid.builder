# xml.rdf(:Description, {'rdf:about'=>person_url(person)}) do
# 	xml.rdf(:type, {'rdf:resource'=>"http://xmlns.com/foaf/0.1/Person"})
# 	xml.core(:hasUNI, {'rdf:datatype'=>"http://www.w3.org/2001/XMLSchema#string"}, person.uid)
# 	xml.foaf(:lastName, {'rdf:datatype'=>"http://www.w3.org/2001/XMLSchema#string"}, person.last_name)
# 	xml.foaf(:firstName, {'rdf:datatype'=>"http://www.w3.org/2001/XMLSchema#string"}, person.first_name)
# 	if person.middle_name.present?
# 		xml.core(:middleName, {'rdf:datatype'=>"http://www.w3.org/2001/XMLSchema#string"}, person.middle_name)
# 	end
# 	if person.research_focus.present?
# 		xml.core(:researchFocus, {'rdf:datatype'=>"http://www.w3.org/2001/XMLSchema#string"}, h(person.research_focus))
# 	end
# 	if person.email.present?
# 		xml.core(:workEmail, {'rdf:datatype'=>"http://www.w3.org/2001/XMLSchema#string"}, person.email)
# 	end
# 	if person.phone.present?
# 		xml.core(:workPhone, {'rdf:datatype'=>"http://www.w3.org/2001/XMLSchema#string"}, person.phone)
# 	end
# 	person.works.each do |w|
# 		xml.core(:authorInAuthorship, {'rdf:resource'=>"#{work_url(w)}#Authorship"})
# 	end
# end

  xml.tag!("message-version", "1.1")
  xml.tag!("orcid-profile") do
    xml.tag!("orcid-bio") do
      xml.tag!("external-identifiers") do
        xml.tag!("external-identifier") do
          xml.tag!("external-id-orcid") do
          
          end
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

