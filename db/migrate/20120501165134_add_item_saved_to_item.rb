class AddItemSavedToItem < ActiveRecord::Migration
  def change
    change_table :items do |t|
      t.boolean         :itemsaved
    end
  end
end
