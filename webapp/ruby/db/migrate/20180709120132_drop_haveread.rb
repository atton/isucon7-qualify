class DropHaveread < ActiveRecord::Migration[5.2]
  def change
    drop_table :haveread
  end
end
