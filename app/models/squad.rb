class Squad < ApplicationRecord
  belongs_to :guild
  has_many :users, dependent: :nullify

  has_one_attached :emblem
  has_one_attached :emblem_pending

  belongs_to :leader, class_name: "User"
  belongs_to :emblem_uploaded_by, class_name: "User", optional: true
  belongs_to :emblem_reviewed_by, class_name: "User", optional: true

  enum :emblem_status, {
    no_emblem: "none",
    pending:   "pending",
    approved:  "approved",
    rejected:  "rejected"
  }, validate: true

  validates :name, presence: true
end
