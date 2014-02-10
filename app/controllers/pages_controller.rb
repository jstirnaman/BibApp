class PagesController < ApplicationController

  def render_html
    render :template => "pages/#{params[:page]}" if template_exists?("pages/#{params[:page]}")
  end
end
