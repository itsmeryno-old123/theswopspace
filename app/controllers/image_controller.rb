class ImageController < ApplicationController
  def get_image
    guid = params[:id]
    a = Image.find_by_imageguid(guid)
    
    if (!a.nil?)
      send_data a.binary_data, :type => a.content_type, :disposition => 'inline'
    else
      send_data nil
    end
  end
  
  def get_avatar
    logger.debug("get_avatar")
    
    user = params[:id]
    u = User.find_by_userguid(user)
    
    if (!u.nil?)
      if (!u.image.nil?)
        logger.debug("image not null, returning avatar")
        send_data u.image.binary_data, :type => u.image.content_type, :disposition => 'inline'
      else
        logger.debug("no avatar, returning nil")
        send_data nil
      end
    else
      logger.debug("no user found")
      send_data nil
    end
  end
end
