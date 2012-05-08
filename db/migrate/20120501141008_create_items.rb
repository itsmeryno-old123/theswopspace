class CreateItems < ActiveRecord::Migration
  def change
    create_table :items do |t|
      t.string        :description
      t.boolean       :visible
      t.integer       :category_id
      t.integer       :user_id
    end
  end
end
