# This file is copied to spec/ when you run 'rails generate rspec:install'
 ENV["RAILS_ENV"] ||= 'test'
 require File.expand_path("../../config/environment", __FILE__)
 require 'rspec/rails'
 require 'rspec/autorun'
 require 'shoulda'
 require 'authlogic/test_case'
#

# # Omniauth response for ORCID API
  OmniAuth.config.test_mode = true
  omniauth_hash = { 'provider' => 'orcid',
                    'uid' => '0000-0002-8010-2941',
                    'info' => {
                        'name' => 'kumc orcid',
                        'email' => 'kumc.orcid@mailinator.com',
                        'scope' => "/orcid-bio/read-limited",
                      },
                    'credentials' => {
                      'access_token' => 'f6d49570-c048-45a9-951f-a81ebb1fa543',
                      'token_type' => 'bearer',
                      'expires_in' => 631138518,
                      'scope' => "/orcid-bio/read-limited",
                      'orcid' => '0000-0002-8010-2941'
                      },
                    'extra' => {'raw_info' =>
                                    {}
                      }
  }

  OmniAuth.config.add_mock(:orcid, omniauth_hash)
# # Requires supporting ruby files with custom matchers and macros, etc,
# # in spec/support/ and its subdirectories.
 Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }
 Dir[Rails.root.join("spec/factories/**/*.rb")].each { |f| require f }
 Dir[Rails.root.join("spec/behaviors/**/*.rb")].each {|f| require f}
 ActionMailer::Base.delivery_method = :test
#
 RSpec.configure do |config|
   config.include FactoryGirl::Syntax::Methods
   end
#
