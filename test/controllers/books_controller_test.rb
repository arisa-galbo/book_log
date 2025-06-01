require "test_helper"

class BooksControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = users(:one)
    @book = books(:one)
    sign_in @user
  end

  test "一覧画面が表示される" do
    get books_url
    assert_response :success
  end

  test "新規登録画面が表示される" do
    get new_book_url
    assert_response :success
  end

  test "本の新規登録ができる" do
    assert_difference("Book.count") do
      post books_url, params: {
        book: {
          title: "新しい本",
          author: "新しい著者",
          isbn: "978-4-123456-78-9",
          progress_status: "unread"
        }
      }
    end

    assert_redirected_to book_url(Book.last)
  end

  test "本の詳細画面が表示される" do
    get book_url(@book)
    assert_response :success
  end

  test "本の編集画面が表示される" do
    get edit_book_url(@book)
    assert_response :success
  end

  test "本の編集ができる" do
    patch book_url(@book), params: {
      book: {
        title: "更新されたタイトル",
        author: @book.author,
        isbn: "978-4-987654-32-1",
        progress_status: @book.progress_status
      }
    }
    assert_redirected_to book_url(@book)
  end

  test "本の削除ができる" do
    assert_difference("Book.count", -1) do
      delete book_url(@book)
    end

    assert_redirected_to books_url
  end

  test "認証が必要な画面にアクセスした場合、ログイン画面にリダイレクトされる" do
    sign_out @user

    get books_url
    assert_redirected_to new_user_session_url

    get new_book_url
    assert_redirected_to new_user_session_url

    post books_url, params: { book: { title: "テスト", author: "テスト" } }
    assert_redirected_to new_user_session_url
  end

  test "進捗状況で本を絞り込める" do
    get books_url, params: { progress_status: "unread" }
    assert_response :success
  end

  test "タイトルで本を検索できる" do
    get books_url, params: { search: @book.title }
    assert_response :success
  end
end
