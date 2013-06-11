require File.dirname(__FILE__) + '/../spec_helper'

describe PeopleController do

  it 'returns results from a directory' do
    lambda do
      params[:q] = "Stirn"
      new
      response.should be_hash
    end.should
  end


end
