class AddGuidToItem < ActiveRecord::Migration
  def change
    change_table :items do |t|
      t.string        :itemguid
    end
  end
end
