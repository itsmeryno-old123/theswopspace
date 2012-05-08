class ChangeSwopIdToString < ActiveRecord::Migration
  def up
    change_table :swops do |t|
        t.change     :initiator_user_id,       :string
        t.change     :recipient_user_id,       :string
    end
  end

  def down
  end
end
