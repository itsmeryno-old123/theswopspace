class IotmController < ApplicationController
  def list
    @nominations = Nomination.find_all_by_month(DateTime.now.month)
  end
  
  def vote
    itemguid = params[:itemguid]
    logger.debug("vote for => [#{itemguid}]")
  end

  def previous
    months = Nomination.select(:month).uniq
    @winners = Array.new
    i = 0
    
    months.each do |month|
      if (month.month == DateTime.now.month)
        logger.debug("current month, not processing")
        next
      end
      
      logger.debug("processing nominations for month => [#{month.month}]")
      nominations = Nomination.find_all_by_month(month.month)
      current = nominations.first
      
      nominations.each do |n|
        if (!n.votes.empty? && !current.votes.empty? && n.votes.count > current.votes.count)
          current = n
        end
      end
      
      if (!current.nil? && !current.votes.empty?)
        logger.debug("adding to list of winners => [#{current.item.description}], with #{current.votes.count} votes")
        @winners[i] = current
        i += 1
      end
    end
  end
  
  def requireauth
    true
  end
end