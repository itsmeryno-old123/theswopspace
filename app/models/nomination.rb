class Nomination < ActiveRecord::Base
  belongs_to  :user
  belongs_to  :item
  has_many    :votes
end
