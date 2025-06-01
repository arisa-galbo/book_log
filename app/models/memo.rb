class Memo < ApplicationRecord
  belongs_to :user
  belongs_to :book

  validates :content, presence: true, length: { minimum: 1, maximum: 2000 }
  validates :is_public, inclusion: { in: [ true, false ] }

  scope :public_memos, -> { where(is_public: true) }
  scope :private_memos, -> { where(is_public: false) }
  scope :by_book, ->(book) { where(book: book) }
  scope :by_user, ->(user) { where(user: user) }
  scope :recent, -> { order(created_at: :desc) }

  def public?
    is_public
  end

  def private?
    !is_public
  end
end
