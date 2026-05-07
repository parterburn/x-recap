class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :x_access_token
      t.string :x_refresh_token
      t.string :x_uid
      t.string :x_username
      t.string :raindrop_api_key
      t.timestamps
    end

    add_index :users, :email, unique: true
  end
end
