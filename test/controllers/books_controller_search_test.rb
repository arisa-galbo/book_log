require "test_helper"

class BooksControllerSearchTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one) # fixtures のユーザーを使用（必要に応じて調整）
    sign_in @user
  end

  test "search_by_isbn で有効なISBNの書籍情報を取得できる" do
    get search_by_isbn_books_path(format: :json), params: { isbn: "9784163239804" }

    assert_response :success
    json_response = JSON.parse(response.body)

    assert json_response["success"]
    assert_not_nil json_response["book"]
    assert_not_nil json_response["book"]["title"]
  end

  test "search_by_isbn で空のISBNの場合エラーが返される" do
    get search_by_isbn_books_path(format: :json), params: { isbn: "" }

    assert_response :success
    json_response = JSON.parse(response.body)

    assert_not json_response["success"]
    assert_equal "ISBNを入力してください", json_response["error"]
  end

  test "search_by_isbn で無効なISBNの場合エラーが返される" do
    get search_by_isbn_books_path(format: :json), params: { isbn: "invalid_isbn" }

    assert_response :success
    json_response = JSON.parse(response.body)

    assert_not json_response["success"]
    assert_not_nil json_response["error"]
  end
end
