class CreateAuditLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :audit_logs do |t|
      t.references :user, null: true, foreign_key: true
      t.references :guild, null: true, foreign_key: true

      t.string :action, null: false

      t.string :entity_type, null: true
      t.bigint :entity_id, null: true

      t.jsonb :metadata, null: true, default: {}

      t.timestamps
    end

    add_index :audit_logs, [ :entity_type, :entity_id ]
    add_index :audit_logs, :action
    add_index :audit_logs, :created_at
  end
end
