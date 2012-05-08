class CreateImages < ActiveRecord::Migration
  def up
    create_table :images do |t|
      t.string        :filename
      t.string        :content_type
      t.binary        :binary_data
      t.references    :imageable, :polymorphic => true
    end
  end
end
