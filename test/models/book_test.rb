require "test_helper"

class BookTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @book = Book.new(
      user: @user,
      title: "テスト本",
      author: "テスト著者",
      progress_status: :unread
    )
  end

  test "有効なデータでバリデーションを通過する" do
    assert @book.valid?
  end

  test "タイトルが必須である" do
    @book.title = ""
    assert_not @book.valid?
    assert_includes @book.errors[:title], "can't be blank"
  end

  test "著者が必須である" do
    @book.author = ""
    assert_not @book.valid?
    assert_includes @book.errors[:author], "can't be blank"
  end

  test "ユーザーが必須である" do
    @book.user = nil
    assert_not @book.valid?
    assert_includes @book.errors[:user], "must exist"
  end

  test "タイトルの最大長が255文字である" do
    @book.title = "a" * 256
    assert_not @book.valid?
    assert_includes @book.errors[:title], "is too long (maximum is 255 characters)"
  end

  test "著者の最大長が255文字である" do
    @book.author = "a" * 256
    assert_not @book.valid?
    assert_includes @book.errors[:author], "is too long (maximum is 255 characters)"
  end

  test "ISBNがユニークである" do
    @book.isbn = "1234567890"
    @book.save!

    duplicate_book = Book.new(
      user: users(:two),
      title: "別の本",
      author: "別の著者",
      isbn: "1234567890"
    )
    assert_not duplicate_book.valid?
    assert_includes duplicate_book.errors[:isbn], "has already been taken"
  end

  test "同じユーザーが同じタイトル・著者の本を重複登録できない" do
    @book.save!

    duplicate_book = Book.new(
      user: @user,
      title: "テスト本",
      author: "テスト著者"
    )
    assert_not duplicate_book.valid?
    assert_includes duplicate_book.errors[:title], "この本は既に登録されています"
  end

  test "異なるユーザーは同じタイトル・著者の本を登録できる" do
    @book.save!

    another_user_book = Book.new(
      user: users(:two),
      title: "テスト本",
      author: "テスト著者"
    )
    assert another_user_book.valid?
  end

  test "progress_statusのenumが正しく動作する" do
    @book.unread!
    assert @book.unread?
    assert_equal 0, @book.progress_status_before_type_cast

    @book.reading!
    assert @book.reading?
    assert_equal 1, @book.progress_status_before_type_cast

    @book.completed!
    assert @book.completed?
    assert_equal 2, @book.progress_status_before_type_cast
  end

  test "scopeが正しく動作する" do
    @book.save!
    reading_book = Book.create!(
      user: @user,
      title: "読書中の本",
      author: "読書中著者",
      progress_status: :reading
    )

    unread_books = Book.by_progress_status(:unread)
    reading_books = Book.by_progress_status(:reading)

    assert_includes unread_books, @book
    assert_includes reading_books, reading_book
    assert_not_includes unread_books, reading_book
    assert_not_includes reading_books, @book
  end
end
