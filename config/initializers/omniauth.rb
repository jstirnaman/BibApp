#To use OAuth you need to copy config/oauth.yml.example to
#config/oauth.yml and fill in sections for each oauth provider
#that you want to use. Consult the Omniauth documentation for
#more details.
#Note that as Bibapp currently works, the OAuth provider must
#return an email address for the user as one of the attributes
#for OAuth to be usable.
#Note that the view code does not currently provide anything
#to send you to your oauth provider - that would need to
#be customized as well.

Bibapp::Application.config.oauth_config =
    if File.exists?(File.join(Rails.root, 'config', 'oauth.yml'))
      YAML.load_file(File.join(Rails.root, 'config', 'oauth.yml'))
    else
      nil
    end

Rails.application.config.middleware.use OmniAuth::Builder do
  if Bibapp::Application.config.oauth_config
    Bibapp::Application.config.oauth_config.each do |k, v|
      params = {}
      v.each do |k, v|
        params[k.to_sym] = v
      end
      if k['orcid']
         # Add ORCID provider with default settings and
         # allow for further setup in the controller
         # so we can change the scope as needed.
         provider :orcid, params[:client_id], params[:client_secret],
          :client_options => params,
          :authorize_params => { :scope => params[:scope] } #,
          #:setup => true
      else
        provider k.to_sym, params
      end
    end
  end
end
if Rails.env.production?
  OmniAuth.config.full_host = $APPLICATION_URL
end

