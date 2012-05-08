class CreateVotes < ActiveRecord::Migration
  def change
    create_table :votes do |t|
      t.integer         :user_id
      t.integer         :nomination_id
      t.datetime        :date
    end
  end
end
