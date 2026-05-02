class CreateStoreOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :store_orders do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.references :store_item, null: false, foreign_key: true
      t.integer :price_paid, null: false
      t.string :status, null: false, default: "pending"
      t.text :admin_notes
      t.datetime :fulfilled_at
      t.datetime :rejected_at
      t.datetime :canceled_at
      t.datetime :refunded_at
      t.references :fulfilled_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.references :rejected_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.references :canceled_by, foreign_key: { to_table: :users, on_delete: :nullify }

      t.timestamps
    end

    add_index :store_orders, [ :user_id, :status ]
    add_index :store_orders, [ :store_item_id, :status ]
    add_index :store_orders, :status
  end
end
