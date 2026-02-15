class GameCharacter < ApplicationRecord
  belongs_to :user
  
  # Imagem do status do personagem
  has_one_attached :status_screenshot
  
  validates :nickname, presence: true, length: { minimum: 2, maximum: 50 }
  validates :level, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 999 }
  validates :power, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :user_id, uniqueness: true
  
  validate :status_screenshot_format
  
  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "id", "level", "nickname", "power", "updated_at", "user_id"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["user", "status_screenshot_attachment", "status_screenshot_blob"]
  end
  
  private
  
  def status_screenshot_format
    return unless status_screenshot.attached?
    
    unless status_screenshot.content_type.in?(%w[image/jpeg image/jpg image/png image/webp])
      errors.add(:status_screenshot, "deve ser uma imagem (JPEG, PNG ou WEBP)")
    end
    
    if status_screenshot.byte_size > 5.megabytes
      errors.add(:status_screenshot, "deve ter no máximo 5MB")
    end
  end
end
