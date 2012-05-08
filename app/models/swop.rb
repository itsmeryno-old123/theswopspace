class Swop < ActiveRecord::Base
  scope :notdeclined, where(:declined => false)
end
