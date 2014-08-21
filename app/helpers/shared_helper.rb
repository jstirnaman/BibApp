# encoding utf-8
# coding utf-8
require "addressable/template"

#this helper is for views in the shared folder
#since we don't know from whence they are called this is included into all views by ApplicationController -
#nevertheless, I want the separation from the methods in ApplicationHelper - these are really specific to
#the shared views, not all views
module SharedHelper
  include TranslationsHelper

  def letter_link_for(letters, letter, current, path)
    li_opts = (current == true) ? {:class => "current"} : {}
    link = path ? "#{path[:path]}?page=#{letter}" : {:page => letter}
    content_tag(:li, (letters.index(letter) ? link_to(letter, link, :class => "some") : content_tag(:a, letter, :class => 'none')), li_opts)
  end

  def link_to_authors(work)
    name_string_links(work['authors_data'], '', '', work['pk_i'])
  end

  def link_to_editors(work)
    name_string_links(work['editors_data'], work['authors_data'] ? (t('common.shared.in') + ' ') : '',
                      " (#{t 'common.shared.eds'})", work['pk_i'])
  end

  def name_string_links(name_string_data, prefix, postfix, work_id)
    return '' if name_string_data.blank?
    links = name_string_data.first(5).collect do |datum|
      name, id = NameString.parse_solr_data(datum)
      link_to(("#{name.force_encoding('utf-8').gsub(",", ", ")}"), name_string_path(id), {:class => "name_string"})
    end
    if name_string_data.size > 5
      links << link_to(t('common.shared.more'), work_path(work_id))
    end
    return [prefix, links.join("; "), postfix].join.html_safe
  end

  def link_to_work_publication(work)
    link_to_work_pub_common(work['publication_data'], Publication, :publication_path)
  end

  def link_to_work_publisher(work)
    link_to_work_pub_common(work['publisher_data'], Publisher, :publisher_path)
  end

  def link_to_work_pub_common(pub_data, klass, path_helper_name)
    return t('app.unknown') if pub_data.blank?
    name, id = klass.parse_solr_data(pub_data)
    link_to("#{name_or_unknown(name).force_encoding('UTF-8')}", self.send(path_helper_name, id), {:class => "source"})
  end

  def add_filter(params, facet, value, count, label = nil)
    label ||= value
    filter = Hash.new
    if params[:fq]
      filter[:fq] = params[:fq].collect.to_a
    else
      filter[:fq] = []
    end

    filter[:fq] << "#{facet}:\"#{value.force_encoding('utf-8')}\""
    filter[:fq].uniq!

    link_to "#{label.force_encoding('utf-8')} (#{count})", params.merge(filter)
  end

  def remove_filter(params, facet)
    filter = Hash.new
    if params[:fq]
      filter[:fq] = params[:fq].collect.to_a
      filter[:fq].delete(facet)
      filter[:fq].uniq!

      #Split filter into field name and display value (they are separated by a colon)
      field_name, display_value = facet.split(':')
      link_to "#{display_value.force_encoding('utf-8')}", params.merge(filter)
    end
  end

  def facet_remove_filter(filter, object = nil)
    filter.clone.tap do |remove_filter|
      # Delete any filters pertaining to current object from removal list
      # Delete any filters pertaining to Work status (as different statuses are currently never shown intermixed)
      # Delete any filters pertaining to Person's active status (since we only want to see active people)
      remove_filter.delete_if do |f|
        (object and f.include?(object.solr_filter)) or
            f.include?(Work.solr_status_field) or
            f.include?("person_active:")
      end
    end
  end

  def keyword_filter(keyword, object)
    filter = [%Q(keyword_facet:"#{keyword.name}")]
    filter << %Q(#{object.class.to_s.downcase}_facet:"#{object.name}") if object
    filter
  end

  #Take the list of facets of person data
  #skip those that we don't want to show, convert those we do want to show to a hash, end if we reach a maximum number
  def convert_and_filter_people_facets(person_facets, max_count, group, check_group, randomize)
    person_facets ||= []
    person_facets = person_facets.shuffle if randomize
    acc = Array.new
    counter = 0
    person_facets.each do |facet|
      last_name, id, image_url, group_ids, active, research_focus = Person.parse_solr_data(facet.name)
      next if active.blank? or active == 'false'
      next if check_group and group_ids.exclude?(group.id)
      break if max_count and counter >= max_count
      counter += 1
      acc << {:last_name => last_name, :id => id, :value => facet.value, :image_url => image_url}
    end
    return acc
  end

  def work_action_link(link_type, solr_work, return_path = nil, saved = nil)
    work_id = solr_work['pk_i']
    case link_type
      when :find_it
        link_to_findit(solr_work)
      when :saved
        if saved and saved.items and saved.items.include?(work_id.to_i)
          content_tag(:strong, "#{t 'app.saved'} - ") +
              link_to(t('app.remove'), remove_from_saved_work_url(work_id))
        else
          link_to t('app.save'), add_to_saved_work_url(work_id)
        end
      when :edit
        link_to t('app.edit'), edit_work_path(work_id, :return_path => return_path)
      else
        nil
    end
  end

  def alpha_pagination_items(include_numbers = false)
    items = ('A'..'Z').to_a
    items = ('0'..'9').to_a + items if include_numbers
    return items
  end

  def subclass_partial_for(work)
    file_name = "shared/work_subclasses/#{work['type'].downcase.gsub(" ", "_")}"
    File.exists?(File.join(Rails.root, 'app', 'views', file_name)) ? file_name : 'shared/work_subclasses/generic'
  end
  
  ## DUPLICATING METHODS FROM WORKS_HELPER. Need to DRY this up.
  
    #heuristic attempt to get best results here
  #We split the string of links on newlines or semicolons
  #Then we throw away everything until the first alphanumeric character
  #Then we throw away everything including and after the first whitespace character
  #This should preserve anything that is actually a good link, e.g. http://whatever.com, 10.1000/doistuff,
  #www.urlwithoutprotocal.com, etc. while solving some common problem cases.
  #Another method will be tasked with determining what these actually are (or may be) and trying to link them
  #appropriately.
  def split_potential_links(work)
    work.links.split(/[\n;]+/).collect { |l| l.sub(/^\W+/, '').sub(/\s.*$/, '') }
  end

  #We try to make a reasonable link if 'link' looks like something linkable. Otherwise just return it unchanged.
  #It might be desirable to try to link to things like 'www.example.com/some/path', but it's not actually easy to figure
  #out the difference between that and 'somerandomtext' in general.
  def link_potential_link(link)
    return link_to(link, link) if looks_like_url(link)
    return link_to(link, doi_link(link)) if looks_like_doi(link)
    link
  end

  #very crude check for linkable url
  def looks_like_url(link)
    link.match(/^http/)
  end

  #crude check for doi
  def looks_like_doi(link)
    link.match(/^10\.\w+\/\S+/)
  end

  def doi_link(link)
    "http://dx.doi.org/#{CGI.escape(link)}"
  end
  
  def looks_like_pmid(link)
    begin
			uri = URI.parse(link)
		rescue
		  return nil
		end
    if uri.host == "www.ncbi.nlm.nih.gov"
			template = Addressable::Template.new("http://www.ncbi.nlm.nih.gov/{db}/{id}")
			if template.extract(uri) && template.extract(uri)["id"]
			  template.extract(uri)["id"]
			else
			  template = Addressable::Template.new("http://www.ncbi.nlm.nih.gov/{db}/term?{id}")
			  if template.extract(uri) && template.extract(uri)["db"] = "pubmed"
			    template.extract(uri)["id"]
			  end
			end
		else
		  return nil
		end
  end

	def to_orcid_type(work)
		orcid_types = {
			"JournalArticle" => "journal-article"
		}
		orcid_types[work.type]
	end  
  ## WORKS_HELPER METHODS.

end
