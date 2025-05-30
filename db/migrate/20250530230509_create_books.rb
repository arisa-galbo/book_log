class CreateBooks < ActiveRecord::Migration[8.0]
  def change
    create_table :books do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.string :author, null: false
      t.integer :progress_status, default: 0, null: false
      t.string :isbn
      t.date :published_date
      t.text :description

      t.timestamps
    end

    add_index :books, :title
    add_index :books, :author
    add_index :books, :progress_status
    add_index :books, :isbn, unique: true
    add_index :books, [ :user_id, :title, :author ], unique: true, name: 'index_books_on_user_title_author'
  end
end
