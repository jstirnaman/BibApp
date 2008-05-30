# This controller signs up new users, and activates their accounts
class UsersController < ApplicationController
  
  # Don't write passwords as plain text to the log files  
  filter_parameter_logging :password, :password_confirmation  
   
  make_resourceful do 
    build :new, :edit
  end
 
  # Create - signs up a new user
  def create
    cookies.delete :auth_token
    # protects against session fixation attacks, wreaks havoc with 
    # request forgery protection.
    # uncomment at your own risk
    # reset_session
    @user = User.new(params[:user])
    @user.save
    if @user.errors.empty?
      flash[:notice] = "Thanks for signing up!  You should receive an email (#{@user.email}) shortly which will allow you to activate your account."
      redirect_back_or_default($APPLICATION_URL)
    else
      render :action => 'new'
    end
  end
  
  
  # Update - update user email
  def update
    @user = User.find(params[:id])    
    @user.email = params[:user][:email] if params[:user][:email]
    @user.save

    if @user.errors.empty?
      flash[:notice] = "Your account was updated successfully."
      redirect_back_or_default($APPLICATION_URL)
    else
      render :action => 'edit'
    end
  end

  # Activates a new user account (after user clicks on link in activation email)
  def activate
    user = params[:activation_code].blank? ? false : User.find_by_activation_code(params[:activation_code])
    if !user.active?
      user.activate
      flash[:notice] = "Signup is complete!  You may now login using your username and password."
    end
    redirect_back_or_default($APPLICATION_URL)
  end

end
