people = Person.includes(:contributorships).where("active")

xml.Promotions({'num'=>people.count, 'total'=>people.count}) do
  people.find_each do |p|
    queries = []
    queries << p.last_name
    
    if p.keywords.any?
      kwords = p.keywords
      keywords_to_hide = $KEYWORDS_TO_HIDE
      keywords_to_hide.split('|').each do |kh|
        kwords.delete_if {|kw| kw.name.match(kh)}
      end
      kw = []
      kw << kwords.first(3).map{|k|h(k.name.to_s.gsub(/\W/,' ').strip)}
      queries = [queries, kw].join(", ")
    end
    
    if p.email?
      top_level_domain = p.email.rindex(/[.]/)
      top_level_domain ||= p.email.size
      pid = p.email[0,top_level_domain]
      pid = pid.gsub(/[@.]/,'_')
      pid = pid.gsub(/-/,'')
    else
      pid = p.machine_name.gsub(/[\s]/,'_')
      pid = pid[0,30]
    end    
    pid = "Experts_" + pid.downcase
    
    if p.full_name
      title = p.full_name + " - Research and Collaborations - Meet Our Experts"
    end
    
    url = person_url(p.id)
    
    unless p.image_url == "man.jpg"
      image_url = $APPLICATION_URL + p.image_url
    end
    
    if p.research_focus
      description = p.research_focus.strip
      description = description.gsub(/\s{2,}/, ' ')
      description = description.gsub(/[\r\n]/,' ')      
      if description.size > 195
        description = description[0,195]
        period_or_space = description.rindex(/[.\s]/)
        description = description[0,period_or_space]
        description = description+'...'
      end
      description = h(description)
    end
    
    xml.Promotion({'id'=>pid, 'queries'=>queries, 'title'=>title, 'url'=>url, 'image_url'=>image_url, 'description'=>description}.delete_if{ |k,v| v == '' || v.nil? })
  end
end