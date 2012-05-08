class CreateRatings < ActiveRecord::Migration
  def change
    create_table :ratings do |t|
      t.integer         :value
      t.datetime        :ratingdate
      t.references      :rateable, :polymorphic => true
      t.integer         :createdby
    end
  end
end
