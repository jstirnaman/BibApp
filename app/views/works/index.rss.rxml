rss_document_on(xml) do
  xml.channel do
    xml.title do |c|
      c << t('personalize.university_short_name') + ": Works" 
      if @query
        c << " results for &quot;#{@query}&quot;"
      end
    end
    @works.each do |work|
      author_names = {}
      if work['name_strings']
        author_names = work['name_strings'].join("; ")
      end
      xml << render('shared/rss_item', :work => work, :author_name => author_names  )
    end
  end
end
