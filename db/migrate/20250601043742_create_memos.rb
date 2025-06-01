class CreateMemos < ActiveRecord::Migration[8.0]
  def change
    create_table :memos do |t|
      t.references :user, null: false, foreign_key: true
      t.references :book, null: false, foreign_key: true
      t.text :content, null: false
      t.boolean :is_public, default: false, null: false

      t.timestamps
    end

    add_index :memos, :is_public
    add_index :memos, [ :book_id, :created_at ]
    add_index :memos, [ :user_id, :is_public ]
  end
end
