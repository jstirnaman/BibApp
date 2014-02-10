# encoding: utf-8
#requires author name argument
xml.description ("My latest research")
@works.each do |work|
  w = Work.find(work['pk_i'])
    @author_names = ''
    if w.authors.present?
      @author_names = w.authors.collect{|a| a[:name].force_encoding('iso-8859-1') }.join(';')
    end
  xml << render('shared/rss_item', :work => work, :author_name => @author_names)
end
