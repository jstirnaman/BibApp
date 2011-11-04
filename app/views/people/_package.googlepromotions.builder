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
      kw << kwords.first(3).map{|k|k.name.to_s.gsub(/\W/,' ')}
      queries = [queries, kw].join(", ")
    end
    
    if p.full_name
      title = p.full_name + " - Research and Collaborations - Meet Our Experts"
    end
    
    url = person_url(p.id)
    
    unless p.image_url = "man.jpg"
      image_url = $APPLICATION_URL + p.image_url
    end
    
    description = p.research_focus
    
    xml.Promotion({'queries'=>queries, 'title'=>title, 'url'=>url, 'image_url'=>image_url, 'description'=>description})
  end
end