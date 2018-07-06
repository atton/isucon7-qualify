class AddIndexForUser < ActiveRecord::Migration[5.2]
  def change
    add_index :user, :name
  end
end
