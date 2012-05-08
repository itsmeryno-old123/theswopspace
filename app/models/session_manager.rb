class SessionManager
  include Singleton
  
  def initialize
    @authenticated = false
  end
  
  def authenticated
    @authenticated
  end
  
  def authenticated=(authenticated)
    @authenticated=authenticated
  end
  
  def session
    @session
  end
  
  def session=(session)
    @session=session
  end
end