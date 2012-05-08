class SwopController < ApplicationController
  def start
    @other = User.find_by_userguid(params[:id])    
    @pending = Swop.notdeclined.find_all_by_recipient_user_id(SessionManager.instance.session[:user].userguid).count
  end
  
  def suggest
    logger.debug("suggest()")
    
    send = String.new
    receive = String.new
    
    params.each do |p|
      name = p[0].to_s()
      value = p[1]
      
      if (name.starts_with?("item_to_"))
        rem = name.length - 8
        logger.debug("remainder length is " + rem.to_s())
        itemguid = name[8, rem]
        send << (itemguid + ",")
        
      elsif (name.starts_with?("item_from_"))
        rem = name.length - 10
        logger.debug("remainder length is " + rem.to_s())
        itemguid = name[10, rem]
        receive << (itemguid + ",")        
      end
    end
    
    swop = Swop.new
    
    swop.initiator_user_id = SessionManager.instance.session[:user].userguid
    swop.recipient_user_id = params[:recipient]
    swop.swop_date = DateTime.now
    swop.declined = false
    swop.swopguid = SecureRandom.hex(32)
    swop.send_items = send
    swop.receive_items = receive
    
    swop.save
    
    redirect_to '/swop/index'
  end
  
  def index
    @pending = Swop.notdeclined.find_all_by_recipient_user_id(SessionManager.instance.session[:user].userguid).count
  end
  
  def pending
    @pending = Swop.notdeclined.find_all_by_recipient_user_id(SessionManager.instance.session[:user].userguid)
    @users = User.all
  end
  
  def update
    @swop = Swop.notdeclined.find_by_swopguid(params[:swopguid])
    
    if (params[:swopaction] == "Reject")
      @swop.declined = true
      @swop.save      
    end
    
    redirect_to '/swop/index'
  end
  
  def details
    @pending = Swop.notdeclined.find_all_by_recipient_user_id(SessionManager.instance.session[:user].userguid).count
    @swop = Swop.notdeclined.find_by_swopguid(params[:id])
    
    @offer = Array.new
    @requested = Array.new
    
    i1 = 0
    i2 = 0
    
    offer_tmp = @swop.send_items.split(",")
    req_tmp = @swop.receive_items.split(",")
    
    offer_tmp.each do |t|
      item = Item.find_by_itemguid(t)
      
      if (!item.nil?)
        @offer[i1] = item
        i1 += 1
      end
    end
    
    req_tmp.each do |t|
      item = Item.find_by_itemguid(t)
      
      if (!item.nil?)
        @requested[i2] = item
        i2 += 1
      end
    end
  end
  
  def requireauth
    true
  end
end
