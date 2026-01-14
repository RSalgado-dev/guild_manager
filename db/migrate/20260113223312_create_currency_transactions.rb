class CreateCurrencyTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :currency_transactions do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.integer :amount, null: false
      t.integer :balance_after, null: false
      t.string :reason_type
      t.bigint :reason_id
      t.string :description
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :currency_transactions, [ :reason_type, :reason_id ]
    add_index :currency_transactions, :created_at
  end
end
