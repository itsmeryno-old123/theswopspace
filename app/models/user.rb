class User < ActiveRecord::Base
  validates :username, :uniqueness => { :is => true, :message => "has already been taken. Please choose another username" }
  validates :email, :uniqueness => { :is => true, :message => "has already been used for registration" }, :format => { :with => /^([^\s]+)((?:[-a-z0-9]\.)[a-z]{2,})$/i, :message => "is not a valid email address" }
  validates :username, :email, :presence => { :is => true, :message => "needs to be supplied" }
  #validates :password_hash, :presence => {:is => true, :message => ""}
  
  has_one :image, :as => :imageable
  has_many :items
  has_many :ratings, :as => :rateable
  
  scope :activeusers, where(:verified => true) 
end
