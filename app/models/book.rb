class Book < ApplicationRecord
  belongs_to :user

  enum :progress_status, {
    unread: 0,        # 未読
    reading: 1,       # 読書中
    completed: 2      # 読了
  }

  validates :title, presence: true, length: { maximum: 255 }
  validates :author, presence: true, length: { maximum: 255 }
  validates :progress_status, presence: true
  validates :isbn, length: { maximum: 20 }, uniqueness: { allow_blank: true }
  validates :description, length: { maximum: 2000 }

  # 同じユーザーが同じタイトル・著者の本を重複して登録することを防ぐ
  validates :title, uniqueness: { scope: [ :user_id, :author ], message: "この本は既に登録されています" }

  has_many :memos, dependent: :destroy

  scope :by_progress_status, ->(status) { where(progress_status: status) }
  scope :search_by_title, ->(query) { where("title ILIKE ?", "%#{query}%") }
  scope :search_by_author, ->(query) { where("author ILIKE ?", "%#{query}%") }
end
