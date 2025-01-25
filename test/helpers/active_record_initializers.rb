require_relative  "../models/application_record"
require_relative  "../models/user"
require_relative  "../models/admin"
require_relative  "../models/avatar"
require_relative  "../models/item"
require_relative  "../models/user_profile"

ActiveRecord::Base.establish_connection(
  adapter:  'sqlite3',
  database: ':memory:'
)
class CreateAllTables < ActiveRecord::Migration[6.0]
  def change
    create_table :users do |t|
      t.string :name
      t.string :email
      t.integer :membership, limit: 2
      t.string :stats

      t.timestamps
    end

    create_table :user_profiles do |t|
      t.string :address
      t.string :zip_code
      t.string :bio

      t.references :user
    end

    create_table :avatars do |t|
      t.string :img_url

      t.references :user_profile
    end

    create_table :admins do |t|
      t.string :name
      t.string :email
    end

    create_join_table :users, :items

    create_table :items do |t|
      t.integer :code, limit: 2
      t.string :name
      t.float :price, precision: 8, scale: 2
      t.string :payload

      t.timestamps
    end
  end
end

CreateAllTables.migrate(:up)