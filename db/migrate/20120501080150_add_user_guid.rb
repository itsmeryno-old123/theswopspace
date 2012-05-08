class AddUserGuid < ActiveRecord::Migration
  def up
    change_table :users do |t|
      t.string        :userguid
    end
  end

  def down
  end
end
