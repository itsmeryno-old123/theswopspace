require 'digest/sha1'

class UserMailer < ActionMailer::Base
  default :from => "ryno.genius@gmail.com"
  
  def welcome_email(user, host)
    #sends the validation email when a user signs up
    @user = user
    print "verify => " + user.verifyguid
    @confirm_url = host + "/access/verify?a=" + user.verifyguid + "&b=" + user.userid
    print "verify url => [" + @confirm_url + "]"
    mail(:to => user.email, :subject => "Please verify your email address")
  end
  
  def forgot_password_email(email) 
    
  end
end
