class AddImageGuid < ActiveRecord::Migration
  def up
    change_table :images do |t|
      t.string        :imageguid
    end
  end

  def down
  end
end
