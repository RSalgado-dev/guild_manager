class CreateStoreItems < ActiveRecord::Migration[8.1]
  def change
    create_table :store_items do |t|
      t.references :guild, null: false, foreign_key: { on_delete: :cascade }
      t.string :name, null: false
      t.text :description
      t.string :category
      t.integer :price, null: false, default: 0
      t.integer :stock_quantity
      t.string :status, null: false, default: "active"
      t.string :fulfillment_type, null: false, default: "manual"

      t.timestamps
    end

    add_index :store_items, [ :guild_id, :status ]
    add_index :store_items, [ :guild_id, :category ]
    add_index :store_items, [ :guild_id, :name ]
  end
end
