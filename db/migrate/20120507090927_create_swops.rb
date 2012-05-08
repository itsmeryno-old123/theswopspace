class CreateSwops < ActiveRecord::Migration
  def change
    create_table :swops do |t|
      t.integer     :initiator_user_id
      t.integer     :recipient_user_id
      t.string      :send_items
      t.string      :receive_items
      t.datetime    :swop_date
      t.boolean     :declined
      t.string      :swopguid
    end
  end
end
