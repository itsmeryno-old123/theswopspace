class UserController < ApplicationController
  def profile
    @user = SessionManager.instance.session[:user]
  end
  
  def saveprofile
    print "saveprofile "
    avatar = params[:avatar]
    img = UploadProcessor.new.save_image(avatar)
    @user = SessionManager.instance.session[:user]    
    @user.image = img
    @user.save
    SessionManager.instance.session[:user] = @user   
    redirect_to '/user/profile/manage'
  end
  
  def editprofile
    @user = SessionManager.instance.session[:user]
  end
  
  def userlist
    @users = User.activeusers
  end
  
  def viewprofile
    @user = User.find_by_userguid(params[:id])
  end
  
  def requireauth
    true
  end
end
