class AddEventProgressionFields < ActiveRecord::Migration[8.0]
  def change
    change_table :events, bulk: true do |t|
      t.string :recurrence, null: false, default: "unique"
    end

    change_table :event_participations, bulk: true do |t|
      t.string :final_status
      t.text :justification
      t.integer :reward_currency_awarded, null: false, default: 0
      t.integer :reward_xp_awarded, null: false, default: 0
      t.datetime :responded_at
    end

    change_column_default :event_participations, :rsvp_status, from: nil, to: "pending"

    reversible do |dir|
      dir.up do
        execute <<~SQL
          UPDATE event_participations
          SET rsvp_status = CASE rsvp_status
            WHEN 'yes' THEN 'confirmed'
            WHEN 'no' THEN 'declined'
            ELSE 'pending'
          END
        SQL
      end

      dir.down do
        execute <<~SQL
          UPDATE event_participations
          SET rsvp_status = CASE rsvp_status
            WHEN 'confirmed' THEN 'yes'
            WHEN 'declined' THEN 'no'
            ELSE NULL
          END
        SQL
      end
    end
  end
end
