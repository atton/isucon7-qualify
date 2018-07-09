class RemakeHaveread < ActiveRecord::Migration[5.2]
  def change
    create_table(:haveread) do |t|
      t.bigint "user_id", null: false
      t.bigint "channel_id", null: false
      t.bigint "message_id"
      t.datetime "updated_at", null: false
      t.datetime "created_at", null: false
    end
  end
end
