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
      t.timestamps

      t.references :user_profile
    end

    create_table :items do |t|
      t.integer :code, limit: 2
      t.string :name
      t.float :price, precision: 8, scale: 2
      t.string :payload

      t.timestamps
    end

    create_join_table :users, :items

    create_table :images, primary_key: :uid do |t|
      t.string :thumb
      t.references :owner, polymorphic: true
      t.timestamps
    end
  end
end

CreateAllTables.migrate(:up)