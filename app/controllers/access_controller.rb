require 'digest/sha1'

class AccessController < ApplicationController
  def authenticate
    username = params[:username]
    password = params[:password]
    loginfrom = params[:loginfrom]
    
    print "username => " + username
    
    password_hash = Digest::SHA1.hexdigest(password)
    
    print "password_hash => " + password_hash
    
    user = User.find_by_username_and_password_hash(username, password_hash)
    
    if (user.nil?)
      print "user was not found"
    else
      print "user found. verified => [" + user.verified.to_s() + "]"
      
      if (user.image.nil?)
        print "user does not have an avatar "
      else
        print "user has avatar => [" + user.image.filename + "] "
      end
    end
    
    SessionManager.instance.session = Hash.new
    
    if (user.nil? || user.verified == false)
      SessionManager.instance.session[:authenticated] = false
      SessionManager.instance.session[:loginfailed] = true
    else
      SessionManager.instance.session[:authenticated] = true
      SessionManager.instance.session[:user] = user
    end
    
    unless loginfrom.nil?
      print "user came from page => " + loginfrom
      redirect_to loginfrom
    else
      redirect_to '/'
    end
  end
 
  def resetpassword
    print "password request for => " + params[:email]
  end
  
  def logout
    #just destroy the session here ...
    SessionManager.instance.session = nil
    redirect_to '/'
  end
  
  def register
  end
  
  def doregister
    print "doregister "
    @user = User.new
    
    @user.username = params[:username]
    @user.email = params[:email]
    @user.verified = false
    
    verify = SecureRandom.hex(32)
    salt = SecureRandom.hex(16)
    userid = Digest::SHA1.hexdigest((@user.username + salt))
    
    pwd = params[:password]
    pwd_confirm = params[:password_confirmation]
    
    continue = true
    
    if (!pwd.empty? && !pwd_confirm.empty? && (pwd == pwd_confirm))
      print "passwords match " 
      password_hash = Digest::SHA1.hexdigest(pwd)
      @user.password_hash = password_hash
    else
      print "passwords do not match "
      continue = false
    end
      
    @user.verifyguid = verify
    @user.userid = userid
    
    print "created vguid => [" + verify + "] userid => [" + userid + "]"
    
    print "continue => [" + continue.to_s() + "] "
    
    valid = @user.valid?
    
    print "valid => [" + valid.to_s() + "]"
    
    if (!continue)
      @user.errors[:base] << "The passwords entered do not match"
    end
    
    if (continue && valid)
      @user.save
      #user saved successfully, send out the welcome email, prompt user to verify account
      UserMailer.welcome_email(@user, currenthost).deliver
      render 'thankyou'
    else
      #there were errors, probably validation. display the errors on the page
      render 'register'
    end
  end
  
  def verify
    userid = params[:b]
    verifyguid = params[:a]
    
    pending = User.find_by_userid(userid)
    
    if (pending.verified)
      #do nothing, user has been verified already
    else
      pending.verified = true
      
      #DateTime.now gives us in GMT timezone, need to use DateTime.new to add the offset for correct timezone
      x = DateTime.now
      #curr = DateTime.new(x.year, x.month, x.day, x.hour, x.min, x.sec, x.sec_fraction, x.offset)
      #pending.membersince = curr
      pending.membersince = x
      pending.userguid = SecureRandom.hex(32)
      
      pending.save
      
      news = News.new
      news.description = "#{pending.username} just joined the site"
      
      news.link = "/user/viewprofile/#{pending.userguid}"
      news.date = DateTime.now
      
      news.save
    end
    
    redirect_to '/'
  end
end
