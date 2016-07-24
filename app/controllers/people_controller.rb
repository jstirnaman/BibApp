
require 'author_webservice'
require 'bibapp_ldap'
require 'orcid_client'

class PeopleController < ApplicationController
  include GoogleChartsHelper
  include KeywordCloudHelper
  include Orcid
  # Make set_keywords, the keyword exclusion methods, available to people templates.
  # Had to do this specifically to make them available to Google Promotions builder template.
  add_template_helper KeywordCloudHelper

  # Require a user be logged in to create / update / destroy
  before_filter :login_required, :only => [:new, :create, :edit, :update, :destroy, :batch_csv_show, :batch_csv_create]
  
  caches_page :show, :if => Proc.new { |c| c.request.format.orcid? }

  make_resourceful do
    build :index, :new, :create, :show, :edit, :update, :destroy

    publish :xml, :json, :yaml, :attributes => [
        :id, :name, :first_name, :middle_name, :last_name, :prefix, :suffix, :phone, :email, :im, :office_address_line_one, :office_address_line_two, :office_city, :office_state, :office_zip, :research_focus, :active, :image_url,
        {:name_strings => [:id, :name]},
        {:groups => [:id, :name]},
        {:contributorships => [:work_id]}]

    #Add a response for RSS
    response_for :show do |format|
      format.html #loads show.html.haml (HTML needs to be first, so I.E. views it by default)
      format.rss #loads show.rss.builder
      format.rdf
      format.orcid
    end
    response_for :show_fails do |format|
        format.html do
          @status ||= status
          @error_message ||= @status.to_s
          render :template => "errors/error_#{@status}", :layout => 'layouts/application', :status => @status  
        end
        format.rss do
          @status ||= status
          @error_message ||= @status.to_s
          render :xml => ('<?xml version="1.0" encoding="UTF-8"?>
            <errors>
            <error code="' + @status.to_s + '">' + @error_message + '</error></errors>'),
          :content_type => 'application/xml', 
          :status => @status
        end
        format.rdf
    end

    response_for :index do |format|
      format.html
      format.rdf
      format.googlepromotions
    end

    response_for :destroy do |format|
      format.html { redirect_to @return_path }
      format.xml { head :ok }
    end

    before :index do

      # for groups/people
      if params[:group_id]
        @group = Group.find_by_id(params[:group_id].split("-")[0])

        if params[:q]
          @current_objects = current_objects
        else
          @a_to_z = Array.new
          @group.people.each do |person|
            @a_to_z << person.last_name[0, 1].upcase
          end
          @a_to_z = @a_to_z.uniq
          @page = params[:page] || @a_to_z[0]
          @current_objects = @group.people.where(:active => true).order("upper(last_name), upper(first_name)")
          @current_objects = @current_objects.where("upper(last_name) like ?", "#{@page}%") unless @page == 'all'
        end

        @title = "#{@group.name} - #{NameString.model_name.human_pl}"
      else

        if params[:q]
          @current_objects = current_objects
        else
          @a_to_z = Person.letters
          @page = params[:page] || @a_to_z[0]
          @current_objects = Person.where(:active => true).where("upper(last_name) like ?", "#{@page}%").order("upper(last_name), upper(first_name)")
        end
        @title = Person.model_name.human_pl
      end
    end

    before :new do
      if params[:q]
      # Replaced LDAP lookup with KUMC local directory webservice search.
        begin
          @ldap_results = AuthorWebservice.instance.search(params[:q])
        rescue StandardError => e
          @fail_message = e.message
        end
        if @ldap_results.nil?
          @fail = true
        else
          @ldap_results.compact!
        end
      end            
#       if params[:q]
#         begin
#           @ldap_results = BibappLdap.instance.search(params[:q])
#         rescue BibappLdapConfigError
#           @fail_message = t('common.people.ldap_fail_configuration')
#         rescue BibappLdapConnectionError
#           @fail_message = t('common.people.ldap_fail_authentication')
#         rescue BibappLdapTooManyResultsError
#           @fail_message = t('common.people.ldap_fail_too_many')
#         rescue BibappLdapError => e
#           @fail_message = e.message
#         end
#         if @ldap_results.nil?
#           @fail = true
#         else
#           @ldap_results.compact!
#         end
#       end
      @title = t('common.people.new')
    end

    before :show do
      search(params)
      @person = @current_object
      work_count = @q.data['response']['numFound']

      if work_count > 0
        @chart_url = google_chart_url(@facets, work_count)
        @keywords = set_keywords(@facets)
      end

      # Collect a list of the person's top-level groups for the tree view
      @top_level_groups = Array.new
      @person.memberships.active.collect { |m| m unless m.group.hide? }.each do |m|
        @top_level_groups << m.group.top_level_parent unless m.nil? or m.group.top_level_parent.hide?
      end
      @top_level_groups.uniq!
    end

    after :show do
      perform_orcid
    end

    before :destroy do
      permit "admin"
      person = Person.find(params[:id])
      @return_path = params[:return_path] || people_url
      person.destroy if person
      #flash[:notice] = "#{person.display_name} was successfully deleted."
    end

    before :edit do
      @title = t('common.people.edit_title', :name => @person.display_name)
    end

  end

  def show
    before :show
    unless current_user and current_user.has_role?('admin')
      if @person.person_active == "false"
        response.status = 410 
        @error_message = 'We have data for ' + @person.id.to_s + '-' + @person.display_name + ', but this person is no longer at KUMC.'
        set_default_flash :error, @error_message
      end
    end
    response_for :show
  rescue
    response_for :show_fails
  else
    after :show if request.format.html?
  end

  def create

    #Check if user hit cancel button
    if params['cancel']
      #just return back to 'new' page
      respond_to do |format|
        format.html { redirect_to new_person_url }
        format.xml { head :ok }
      end

    else #Only perform create if 'save' button was pressed

      @person = Person.new(params[:person])
      @dupeperson = Person.find_by_uid(@person.uid)

      if @dupeperson.nil?
        respond_to do |format|
          if @person.save
            flash[:notice] = t('common.people.flash_create_success')
            format.html { redirect_to new_person_pen_name_path(@person.id) }
            #TODO: not sure this is right
            format.xml { head :created, :location => person_url(@person) }
          else
            flash[:warning] = t('common.people.flash_create_field_missing')
            format.html { render :action => "new" }
            format.xml { render :xml => @person.errors.to_xml }
          end
        end
      else
        respond_to do |format|
          flash[:error] = t('common.people.flash_create_person_exists_html', :url => person_path(@dupeperson.id))
          format.html { render :action => "new" }
          #TODO: what will the xml response be?
          #format.xml  {render :xml => "error"}
        end
      end
    end
  end

  def update

    @person = Person.find(params[:id])

    #Check if user hit cancel button
    if params['cancel']
      #just return back to 'new' page
      respond_to do |format|
        format.html { redirect_to person_url(@person) }
        format.xml { head :ok }
      end

    else #Only perform create if 'save' button was pressed

      @person.update_attributes(params[:person])

      respond_to do |format|
        if @person.save
          flash[:notice] = t('common.people.flash_update_success')
          format.html { redirect_to new_person_pen_name_path(@person.id) }
          #TODO: not sure this is right
          format.xml { head :created, :location => person_url(@person) }
        else
          flash[:warning] = t('common.people.flash_update_failure')
          format.html { render :action => "new" }
          format.xml { render :xml => @person.errors.to_xml }
        end
      end
    end
  end

  def load_reftype_chart
    @person = Person.find(params[:person_id])

    #generate the google chart URI
    #see http://code.google.com/apis/chart/docs/making_charts.html
    #
    chd = "chd=t:"
    chl = "chl="
    chdl = "chdl="
    chdlp = "chdlp=b|"
    @person.publication_reftypes.each_with_index do |r, i|
      percent = (r.count.to_f/@person.works.size.to_f*100).round.to_s
      chd += "#{percent},"
      ref = r[:type].to_s == 'BookWhole' ? 'Book' : r[:type].to_s
      chl += "#{ref.titleize.pluralize}|"
      chdl += "#{percent}% #{ref.titleize.pluralize}|"
      chdlp += "#{i.to_s},"
    end
    chd.chop!
    chl.chop!
    @chart_url = "https://chart.googleapis.com/chart?cht=p&chco=346090&chs=350x100&#{chd}&#{chl}"

    render :update do |page|
      page.replace_html "loading_reftype_chart", "<img src='#{@chart_url}' alt='work-type chart' style='margin-left: -50px;margin-bottom:20px;' />"
    end

  end

  def batch_csv_show
    permit "admin"
  end

  def batch_csv_create
    permit "admin"
    @message = ''
    begin
      filename = params[:person][:data].original_filename
      str = params[:person][:data].read
      unless str.is_utf8?
        encoding = CMess::GuessEncoding::Automatic.guess(str)
        unless encoding.nil? or encoding.empty? or encoding==CMess::GuessEncoding::Encoding::UNKNOWN
          str = Iconv.iconv('UTF-8', encoding, str).to_s
        else
          flash[:notice] = t('common.people.flash_batch_csv_create_bad_encoding')
          @message = t('common.people.file_unconvertible')
        end
      end
      if @message.empty?
        BatchUpload::CsvPeople.new(str, current_user.id, filename).delay.perform
        @message = t('common.people.file_accepted')
      end
    rescue Exception => e
      flash[:notice] = t('app.exception_with_message', :message => e.to_s)
      @message = t('common.people.batch_csv_error')
    end

    render 'batch_csv_show'
  end

  def perform_orcid
    if session[:omniauth] && session[:omniauth]['provider'] == 'orcid'
      if session[:omniauth]['uid'] == @person.orcid
        omniauth = session[:omniauth]
        @orcid_client ||= Orcid::OrcidApi.new(as_member: true, token: omniauth.credentials.token)
        if omniauth['info']['scope'] =~ /#{@orcid_client.works_create_scope} | #{@orcid_client.affiliations_create_scope} | #{@orcid_client.external_id_create_scope}/
          person_to_orcid(@person)
        end
      end
    end
  end

  private
  def person_to_orcid(person)
    profile = orcid_profile(person.id)
    if profile != ""
      post_to_orcid(:works, profile)
      post_to_orcid(:affiliations, profile)
      post_to_orcid(:external_id, profile)
      redirect_to orcid_person_url
    else
      response.status = 404
      @error_message = "We are unable to send data to ORCID.org because ORCID data was missing."
      set_default_flash :error, @error_message
    end
  end

  def orcid_profile(person_id)
   cached_profile = Rails.root.to_s + "/public/orcid/#{person_id}.orcid"
   if File.exists?(cached_profile)
     File.open(cached_profile, 'r') do |f|
       (f.read).gsub(/\>\s*\n\s*\</,'><').strip()
     end
   else
     render_to_string(:action => "show", :formats => [:orcid])
   end
   
  end

  def orcid_person_url
    "https://sandbox.orcid.org/" + session[:omniauth].uid
  end

  def post_to_orcid(type, body)
    omniauth = session[:omniauth] || return
    unless body.nil?
      orcid_request = case type
        when :affiliations
          @orcid_client.post_affiliations(omniauth.uid, options = {:body => body} )
        when :external_id
          @orcid_client.post_external_id(omniauth.uid, options = {:body => body} )
        when :works
          @orcid_client.post_works(omniauth.uid, options = {:body => body} )
      end
      orcid_request
    end
  end

end
