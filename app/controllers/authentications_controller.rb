require 'orcid_client'
class AuthenticationsController < ApplicationController
  include Orcid
  def create
    session[:omniauth] = request.env['omniauth.auth']
    session[:params] = params
    omniauth = session[:omniauth]
    if session[:omniauth]['provider'] == 'orcid'
      @orcid ||= Orcid::OrcidApi.new
      @orcid.as_member(omniauth.credentials.token)
      if session[:person].nil?
        session[:person] = authenticate_by_orcid
      end
      if session[:person] && request.env['omniauth.auth']['info']['scope'] == @orcid.bio_read_scope
        redirect_to("/auth/orcid?scope=#{@orcid.works_create_scope}")
      end
      if session[:person] && request.env['omniauth.auth']['info']['scope'] == @orcid.works_create_scope
        session[:omniauth] = request.env['omniauth.auth']
        post_to_orcid(:works)
        redirect_to("/auth/orcid?scope=#{@orcid.affiliations_create_scope}")
      end
      if session[:person] && request.env['omniauth.auth']['info']['scope'] == @orcid.affiliations_create_scope
        post_to_orcid(:affiliations)
        redirect_to("/auth/orcid?scope=#{@orcid.external_id_create_scope}")
      end
      if session[:person] && request.env['omniauth.auth']['info']['scope'] == @orcid.external_id_create_scope
        post_to_orcid(:external_id)
        redirect_to("https://sandbox.orcid.org/" + session[:omniauth].uid)
      end
      session.destroy
     else
       authentication = Authentication.find_by_provider_and_uid(omniauth['provider'], omniauth['uid'])
       if authentication
         # User is already registered with application
         flash[:info] = t('common.authentications.flash_sign_in')
         sign_in_and_redirect(authentication.user)
       else
         authenticate_user
       end
     end
  end

  def authenticate_by_orcid
    orcid = (session[:omniauth]).uid
    person = Person.find_by_im(orcid)
    if person.nil?
      person = orcid_match_by_email(session[:omniauth])
    end
    person
  end

  def orcid_match_by_email(omniauth)
          # Match person by email address
          bio = Nokogiri::XML(@orcid.bio(orcid).body)
          email_props = bio.css('email')
          orcidemail = email_props.xpath('./@verified').text() == "true" ? email_props.text() : nil
          if orcidemail.nil?
            @fl_msg = "We could not find a verified email account in your ORCID profile. Please go to ORCID and allow LIMITED access to your campus email address."
          else
            person = Person.find_by_email(orcidemail)
            if person
              person.update_attributes(:im => orcid)
              person.save!
            else
               @fl_msg = "We could not find an account that matched your ORCID-registered email account."
            end
          end
     person
  end

  def orcid_person
    omniauth = session[:omniauth] || return
    @person = Person.find_by_im(omniauth.uid)
    orcid_person = render_to_string( 'people/show.orcid.builder', :layout => false, :locals => {:format => 'orcid'} )
    orcid_person = orcid_person.gsub(/\>\s*\n\s*\</,'><').strip()
  end

  def post_to_orcid(type)
    omniauth = session[:omniauth] || return
    body = orcid_person
    unless body.nil?
      orcid_request = case type
        when :affiliations
          @orcid.post_affiliations(omniauth.uid, options = {:body => body} )
        when :external_id
          @orcid.post_external_id(omniauth.uid, options = {:body => body} )
        when :works
          @orcid.post_works(omniauth.uid, options = {:body => body} )
      end
      logger.debug(orcid_request.inspect)
      orcid_request
    end
  end

  def authenticate_by_cas   # Lookup and add user's email to omniauth variable to satisfy User model
      casemail = session[:omniauth]['extra']['user'] + '@' + Bibapp::Application.config.oauth_config['cas']['host'][/[a-z,0-9]*\.(.*)/, 1] 
      casuser = User.find_by_sql ["SELECT email FROM users WHERE email LIKE ? LIMIT 1", casemail]
      if casuser.empty?
        session[:omniauth]['info'] = {}
        @fl_msg = "CAS authentication succeeded, but we were unable to find a matching registered email address. Please register or contact us to update your email address."
      else
        session[:omniauth]['info'] = { 'email' => casuser[0]['email'] }
      end
  end

  def authenticate_user
    if omniauth['provider'] == 'cas'
      authenticate_by_cas
      omniauth = session[:omniauth]
    end
    user = current_user || User.find_by_email(omniauth['info']['email'])
    if !user.nil?
      # User is signed in but has not already authenticated with this social network
      # OR user already has a local account - connect it properly to an authentication
      user.authentications.create!(:provider => omniauth['provider'], :uid => omniauth['uid'])
      user.apply_omniauth(omniauth)
      user.save
      flash[:info] = t('common.authentications.flash_authentication')
      redirect_to root_url
    else
      # User is new to this application
      user = User.new
      user.apply_omniauth(omniauth)
      if user.save
        flash[:info] = t('common.authentications.flash_create')
        user.authentications.create(:provider => omniauth['provider'], :uid => omniauth['uid'])
        user.activate
        sign_in_and_redirect(user)
      else
        session[:omniauth] = omniauth.except('extra')
        flash[:notice] = "We could not find a matching username." + " " + @fl_msg.to_s
        redirect_to signup_path
      end
    end
  end

  def destroy
    @authentication = current_user.authentications.find(params[:id])
    @authentication.destroy
    flash[:notice] = t('common.authentications.flash_destroy')
    redirect_to authentications_url
  end

  private
  def sign_in_and_redirect(user)
    unless current_user
      user_session = UserSession.new(user)
      user_session.save
    end
   redirect_to request.env['omniauth.origin'] || root_url
  end
end
