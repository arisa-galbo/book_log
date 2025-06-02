require "test_helper"

class GoogleBooksApiServiceTest < ActiveSupport::TestCase
  test "find_book_by_isbnで有効なISBNの書籍情報を取得できる" do
    # テスト用のISBN（例として）
    isbn = "9784163239804"

    result = GoogleBooksApiService.find_book_by_isbn(isbn)

    assert result[:success], "APIリクエストが成功するべき"
    assert_not_nil result[:data], "書籍データが返されるべき"
    assert_not_nil result[:data][:title], "書籍タイトルが含まれるべき"
  end

  test "無効なISBNでエラーが返される" do
    invalid_isbn = "invalid_isbn"

    result = GoogleBooksApiService.find_book_by_isbn(invalid_isbn)

    assert_not result[:success], "無効なISBNでは失敗するべき"
    assert_not_nil result[:error], "エラーメッセージが含まれるべき"
    assert_nil result[:data], "データはnilであるべき"
  end

  test "ISBNのハイフンが自動的に除去される" do
    isbn_with_hyphens = "978-4-16-323980-4"

    result = GoogleBooksApiService.find_book_by_isbn(isbn_with_hyphens)

    assert result[:success], "ハイフン付きISBNでもAPIリクエストが成功するべき"
    assert_not_nil result[:data], "書籍データが返されるべき"
  end

  test "search_by_isbnでシンプルな形式の書籍情報を取得できる" do
    isbn = "9784163239804"

    result = GoogleBooksApiService.search_by_isbn(isbn)

    assert_not_nil result, "結果が返されるべき"
    assert_not_nil result[:title], "タイトルが含まれるべき"
    assert_not_nil result[:author], "著者が含まれるべき"
  end

  test "search_by_isbnで書籍が見つからない場合nilが返される" do
    invalid_isbn = "invalid_isbn"

    result = GoogleBooksApiService.search_by_isbn(invalid_isbn)

    assert_nil result, "無効なISBNではnilが返されるべき"
  end

  test "空のISBNでエラーが返される" do
    empty_isbn = ""

    result = GoogleBooksApiService.find_book_by_isbn(empty_isbn)

    assert_not result[:success], "空のISBNでは失敗するべき"
    assert_equal "ISBNが無効です", result[:error], "適切なエラーメッセージが返されるべき"
  end
end
