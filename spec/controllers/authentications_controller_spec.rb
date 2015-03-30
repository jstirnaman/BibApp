require File.dirname(__FILE__) + '/../spec_helper'

describe AuthenticationsController do

  it 'authenticates user' do
    lambda do
      create_authentication
      response.should be_redirect
    end
  end

  describe 'authenticates person by orcid' do
    before do
      request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:orcid]
    end

    it 'has omniauth with orcid' do
      expect(request.env['omniauth.auth']['uid']).to match(/([0-9](-)?){4}/)
    end

    before(:each) do
      @person = build(:person, orcid: nil)
      @person.save
    end

    it 'matches verified email' do
      request.env['person'] = @person
      post :create, provider: :orcid
      response.should be_redirect
    end

    it 'matches orcid id' do
      @person.update_attributes(orcid: request.env['omniauth.auth']['uid'])
      @person.save
      request.env['person'] = @person
      post :create, provider: :orcid
      response.should be_redirect
    end

  end
end
