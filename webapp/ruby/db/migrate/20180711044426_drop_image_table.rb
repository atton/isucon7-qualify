class DropImageTable < ActiveRecord::Migration[5.2]
  def change
    drop_table :image
  end
end
