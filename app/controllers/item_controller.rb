class ItemController < ApplicationController
  def new
    @categories = Category.all
  end
  
  def manage
    @items = SessionManager.instance.session[:user].items.reload
  end
  
  def save(params)
    print "adding item to database "
      guid = params[:itemref]
     
      @item = Item.find_by_itemguid(guid)
      @item.itemsaved = true;
      @item.description = params[:description]
      @item.category_id = params[:category]
      
      if (!params[:visible].nil? && params[:visible] == "on")
        @item.visible = true
        
        news = News.new
        news.description = "#{SessionManager.instance.session[:user].username} added a new item - #{@item.description}"
        news.link = "/items/details/#{guid}"
        news.date = DateTime.now
        
        news.save
      else
        @item.visible = false
      end
      
      @item.user_id = SessionManager.instance.session[:user].id
      
      @item.save
      
      redirect_to '/user/inventory/manage'
  end
  
  def newimg(params)
    guid = params[:itemref]
      print "saving image to item [" + guid + "]"
      @item = Item.find_by_itemguid(guid)
      
      input = params[:image]
      
      filename = input.original_filename
      content_type = input.content_type.chomp
      binary_data = input.read
      imageguid = SecureRandom.hex(32)
      
      @item.images.create(:filename => filename, :content_type => content_type, :binary_data => binary_data, :imageguid => imageguid)  
      
      @item.save      
          
      @categories = Category.all
      render 'new'
  end
  
  def imagesforitem
    itemguid = params[:id]
    item = Item.find_by_itemguid(itemguid)
    
    coll = Array.new
    i = 0
    
    item.images.each do |img|
      coll[i] = img.imageguid
      i += 1
    end
    
    render :json => coll
  end
  
  def create
    item = Item.new
    
    item.itemsaved = true;
    item.description = params[:description]
    item.category_id = params[:category]
    item.itemguid = SecureRandom.hex(32)
    
    #need to call save here in order to create image children
    item.save
    
    params.each do |p|
      name = p[0].to_s()
      value = p[1]
      
      #loop through all images submitted, add to the item
      if (name.starts_with?("image_"))
        filename = value.original_filename
        logger.debug("adding image => [#{filename}]")
        content_type = value.content_type.chomp
        binary_data = value.read
        imageguid = SecureRandom.hex(32)
        
        item.images.create(:filename => filename, :content_type => content_type, :binary_data => binary_data, :imageguid => imageguid)  
      end
    end
    
    if (!params[:visible].nil? && params[:visible] == "on")
      item.visible = true
      
      news = News.new
      news.description = "#{SessionManager.instance.session[:user].username} added a new item - #{item.description}"
      news.link = "/items/details/#{item.itemguid}"
      news.date = DateTime.now
      
      news.save
    else
      item.visible = false
    end
    
    item.user_id = SessionManager.instance.session[:user].id
    
    item.save
  
    redirect_to '/user/inventory/manage'
  end
  
  def edit
    if (params[:submit] == "Delete Selected")
      delete(params)
    elsif (params[:submit] == "Add Item")
      redirect_to '/user/inventory/new'
    end
  end
  
  def edititem
    @item = Item.find_by_itemguid(params[:id])
    @categories = Category.all
    render 'new'
  end
  
  def delete(params)
    params.each do |p|
      name = p[0].to_s()
      value = p[1].to_s()
      
      if (name.starts_with?("item_"))
        logger.debug("selected => [" + name + "]")
        rem = name.length - 5
        logger.debug("remainder length is " + rem.to_s())
        itemguid = name[5, rem]
        logger.debug("itemguid => [" + itemguid + "]")
        item = Item.find_by_itemguid(itemguid)
        
        if (item.nil?)
          print "could not find item "
        else
          print "item found. id => [" + item.id.to_s() + "]"
          Item.delete(item.id)
        end
      end
    end
    
    redirect_to '/user/inventory/manage'
  end
  
  def browse
    #filter 
    cat = params[:category]
    search = params[:filter_string]
    
    if (!search.nil? && !search.empty?)   
      logger.debug("search supplied => [#{search}]")
         
      if (!cat.nil? && cat != "-1")
        logger.debug("category supplied => [#{cat}]")
        @items = Item.allsaved.where("description like ?", "%#{search}%").find_all_by_category_id(cat)
      else
        logger.debug("no category supplied");
        @items = Item.allsaved.where("description like ?", "%#{search}%")
      end
    elsif (!cat.nil? && cat != "-1")
      @items = Item.allsaved.find_all_by_category_id(cat)      
    else
      @items = Item.allsaved
    end  
    
    @categories = Category.all
  end 
  
  def details
    itemguid = params[:id]
    @item = Item.allsaved.find_by_itemguid(itemguid)
    @category = Category.find_by_id(@item.category_id)
  end
  
  def rate
    itemguid = params[:itemguid]
    rating = params[:rating]
    
    userid = SessionManager.instance.session[:user].id
    
    @item = Item.allsaved.find_by_itemguid(itemguid)
    @item.ratings.create(:value => rating, :createdby => :userid, :ratingdate => DateTime.now)
    @item.save
    
    render 'details'
  end
  
  def nominate
    itemguid = params[:itemguid]
    @item = Item.find_by_itemguid(itemguid)
    
    #first check if this item has been nominated in this month before
    @nomination = Nomination.find_by_item_id_and_month(@item.id, DateTime.now.month)
    
    if (!@nomination.nil?)
      @nomination.errors[:base] << "This item has already been nominated in the current month"
    else
      @nomination = Nomination.new
      @nomination.finished = false
      @nomination.month = DateTime.now.month
    
      @nomination.save
    
      @nomination.user = SessionManager.instance.session[:user]
      @nomination.item = @item
    
      @nomination.save
    end
    
    render 'details'
  end
  
  def requireauth
    true
  end
end
