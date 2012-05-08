class CreateNominations < ActiveRecord::Migration
  def change
    create_table :nominations do |t|
      t.integer         :item_id
      t.integer         :user_id
      t.integer         :month
      t.boolean         :finished
    end
  end
end
