class ApplicationController < ActionController::Base
  protect_from_forgery
  
  before_filter :init
  
  def init
    @session = SessionManager.instance.session
    @currenthost = "http://" + request.host + ":" + request.port.to_s()
    
    if (requireauth && (@session.nil? || @session[:user].nil?))
      #should maybe redirect to an error page here ?
      redirect_to '/'
    end
  end
  
  def currenthost
    @currenthost
  end
  
  def requireauth
    false
  end
end
