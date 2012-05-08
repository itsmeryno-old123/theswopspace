class CreateNews < ActiveRecord::Migration
  def change
    create_table :news do |t|
      t.string          :description
      t.datetime        :date
      t.string          :link
    end
  end
end
