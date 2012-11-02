rdf_document_on(xml) do
  @works.each do |w|
    work = Work.find(w['pk_i'])
    (xml << render(:partial => "shared/package", :locals => {:work => work})) if work
  end
  if @has_next_page
    @page = @page == 0 ? 1 : @page
		  xml.oslc(:ResponseInfo, 
		           'rdf:about' => "#{request.protocol}#{request.host_with_port}#{request.fullpath}?page=#{@page.to_i}&oslc.paging=true",
               'xmlns:oslc' => "http://open-services.net/ns/core#ResponseInfo" ) do
        xml.oslc(:nextPage, 'rdf:resource' => "#{request.protocol}#{request.host_with_port}#{request.fullpath}?page=#{@page.to_i+1}")
      end
  end
end
