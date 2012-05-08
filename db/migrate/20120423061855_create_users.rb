class CreateUsers < ActiveRecord::Migration
  def up
    create_table :users do |t|
      t.string            :username
      t.string            :password_hash
      t.string            :userid
      t.boolean           :verified
      t.string            :verifyguid
      t.datetime          :membersince
      t.string            :email
    end
  end
end
