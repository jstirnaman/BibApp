people = Person.includes(:contributorships)

xml.Promotions() do
  people.find_each do |p|
    promo_h = Hash.new
    
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
      promo_h.merge!('id' => pid)
     
    queries = []
      queries << p.last_name
      facets = {:keywords => p.keywords}     
      kwords = exclude_keywords(facets[:keywords])
      kwords = kwords.first(3)
      if kwords.length > 0
        kw = []   
        kw << kwords.map{|k|h(k.name.to_s.gsub(/\W/,' ').strip)}
        queries = [queries, kw].join(", ")
      end
      promo_h.merge!('queries' => queries)
      
    if p.full_name
      title = p.full_name + " - Meet Our Experts: Research and Collaborations"
    end    
      promo_h.merge!('title' => title)
            
    url = person_url(p.id)
     promo_h.merge!('url' => url)
    
    unless p.image_url == "man.jpg"
      promo_h.merge!('image_url' => $APPLICATION_URL + p.image_url)
    end
    
    if p.research_focus && p.research_focus.length > 1
      description = p.research_focus.strip
      description = description.squeeze(" ")
      description = description.gsub(/[\r\n]/,' ')      
      if description.length > 195
        description = description[0,195]
        period_or_space = description.rindex(/[.\s]/)
        description = description[0,period_or_space]
        description = description+'...'
      end
      description = h(description)
      promo_h.merge!('description' => description)d
    end    
    
    enabled = p.active ? 'true' : 'false'
      promo_h.merge!('enabled' => enabled)    
          
    xml.Promotion(promo_h)
   end   
end