class Item < ActiveRecord::Base
  has_many :images, :as => :imageable
  has_many :ratings, :as => :rateable
  
  scope :allsaved, where(:itemsaved => true)
end
