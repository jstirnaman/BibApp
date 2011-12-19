#To use OAuth you need to copy config/oauth.yml.example to 
#config/oauth.yml and fill in sections for each oauth provider
#that you want to use. Consule the Omniauth documentation for
#more details.
#Note that as Bibapp currently works the OAuth provider must
#return an email address for the user as one of the attributes
#for OAuth to be useable.
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
        STDERR.puts k          
          @params = {:cas_server => v['cas_server'], :cas_login_url => v['cas_login_url'], :cas_service_validate_url => v['cas_service_validate_url'], :cas_disable_ssl_verification => v['cas_disable_ssl_verification'], :cas_extra_attributes => v['cas_extra_attributes']}        
          STDERR.puts @params.to_s
          provider k, @params
      end
      if k['saml']
        STDERR.puts k          
          @params = {:assertion_consumer_service_url => v['assertion_consumer_service_url'], :issuer => v['issuer'], :idp_sso_target_url => v['idp_sso_target_url'], :name_identifier_format => v['name_identifier_format']}        
          STDERR.puts @params.to_s
          provider 'SAML', @params
      end
    end
  end
end
