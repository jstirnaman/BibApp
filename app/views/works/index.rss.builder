rss_document_on(xml) do
  xml.channel do
    xml.title do |c|
      c << t('personalize.university_short_name') + ": Works" 
      if @query
        c << " results for &quot;#{@query}&quot;"
      end
    end
    @works.each do |work|
      w = Work.find(work['pk_i'])
      @author_names = ''
      if w.authors.present?
        #@author_names = w.authors.collect{|a| a[:name].force_encoding('iso-8859-1') }.join(';')
      end
      xml << render('shared/rss_item', :work => work, :author_name => @author_names  )
    end
  end
end
