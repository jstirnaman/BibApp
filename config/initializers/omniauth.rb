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
        if v['key']
          provider k, v['key'], v['secret']
        end
        if k['cas']          
            @params = { 
              :host => v['host'], 
              :login_url => v['login_url'], 
              :service_validate_url => v['service_validate_url'], 
              :disable_ssl_verification => v['disable_ssl_verification'], 
              }
            provider k, @params
        end
        if k['SAML']         
            @params = { 
              :assertion_consumer_service_url => v['assertion_consumer_service_url'], 
              :issuer => v['issuer'], :idp_sso_target_url => v['idp_sso_target_url'], 
              :name_identifier_format => v['name_identifier_format']
              }        
            provider k, @params
        end
      end
    end
  end
if Rails.env.production?
  OmniAuth.config.full_host = $APPLICATION_URL
end
#Bibapp::Application.config.oauth_config =
#    if File.exists?(File.join(Rails.root, 'config', 'oauth.yml'))
#      YAML.load_file(File.join(Rails.root, 'config', 'oauth.yml'))
#    else
#      nil
#    end
#
#Rails.application.config.middleware.use OmniAuth::Builder do
#  if Bibapp::Application.config.oauth_config
#    Bibapp::Application.config.oauth_config.each do |k, v|
#      provider k, v['key'], v['secret']
#    end
#  end
#end

