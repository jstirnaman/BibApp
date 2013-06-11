class AuthenticationsController < ApplicationController
  def create
    omniauth = request.env['omniauth.auth']
    authentication = Authentication.find_by_provider_and_uid(omniauth['provider'], omniauth['uid'])
    specific_msg = ""
      # KUMC.JTS Hack to lookup and add user's email to omniauth variable to satisfy User model since I can't
      # get the user attributes from CAS/SAML. I'm not happy with
      # this nor how tightly the User model is woven with the email address from the oauth response.
    if omniauth['provider'] == 'cas'
      casuser = User.find_by_sql ["SELECT email FROM users WHERE email LIKE ? LIMIT 1", omniauth['uid']+"@kumc.edu"]
      if casuser.empty?
        omniauth['user_info'] = {}
        specific_msg = "Signup or double-check that your CAS login matches your registered email."
      else
        omniauth['user_info'] = { 'email' => casuser[0]['email'] }
      end
      
    end
    
    if authentication
      # User is already registered with application
      flash[:info] = t('common.authentications.flash_sign_in')

    elsif user = current_user || User.find_by_email(omniauth['user_info']['email'])

      # User is signed in but has not already authenticated with this social network
      # OR
      #user already has a local account - connect it properly to an authentication
      user.authentications.create!(:provider => omniauth['provider'], :uid => omniauth['uid'])
      user.apply_omniauth(omniauth)
      user.save
      flash[:info] = t('common.authentications.flash_authentication')
      redirect_to root_url
    else
      # User is new to this application
      logger.debug(omniauth.inspect)
      user = User.new
      user.apply_omniauth(omniauth)
      if user.save
        flash[:info] = t('common.authentications.flash_create')
        user.authentications.create(:provider => omniauth['provider'], :uid => omniauth['uid'])
        user.activate
        sign_in_and_redirect(user)
      else         
        session[:omniauth] = omniauth.except('extra')
        flash[:notice] = "We could not find a matching username." + " " + specific_msg
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
    redirect_to root_url
  end
end
