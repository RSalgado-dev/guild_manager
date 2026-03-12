class AddSquadProfileReviewAndInvitations < ActiveRecord::Migration[8.1]
  def change
    add_column :squads, :tag, :string
    add_column :squads, :pending_profile_changes, :jsonb, null: false, default: {}
    add_column :squads, :profile_change_status, :string, null: false, default: "none"
    add_column :squads, :profile_change_requested_at, :datetime
    add_column :squads, :profile_change_reviewed_at, :datetime
    add_column :squads, :profile_change_reviewed_by_id, :integer
    add_column :squads, :profile_change_rejection_reason, :text
    add_column :squads, :last_profile_change_approved_at, :datetime

    add_index :squads, :profile_change_status
    add_index :squads, [ :guild_id, :tag ], unique: true
    add_foreign_key :squads, :users, column: :profile_change_reviewed_by_id

    create_table :squad_invitations do |t|
      t.references :squad, null: false, foreign_key: true
      t.references :inviter, null: false, foreign_key: { to_table: :users }
      t.references :invitee, null: false, foreign_key: { to_table: :users }
      t.string :status, null: false, default: "pending"
      t.datetime :expires_at, null: false
      t.datetime :responded_at
      t.text :note

      t.timestamps
    end

    add_index :squad_invitations, [ :invitee_id, :status ]
    add_index :squad_invitations, [ :squad_id, :invitee_id, :status ], name: "idx_squad_invites_unique_pending", unique: true, where: "status = 'pending'"
  end
end
