require "test_helper"

class IsbnSearchTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    sign_in @user
  end

  test "new book page でフォームが正常に表示される" do
    get new_book_path
    assert_response :success

    # Stimulus controller用のHTML要素の存在確認
    assert_select "[data-controller='isbn-search']"
    assert_select "[data-isbn-search-target='input']"
    assert_select "[data-isbn-search-target='button']"
    assert_select "[data-isbn-search-target='result']"
  end

  test "Stimulus controllerのdata-attributesが正しく設定されている" do
    get new_book_path
    assert_response :success

    # 必要なターゲットが全て設定されていることを確認
    assert_select "[data-isbn-search-target='title']"
    assert_select "[data-isbn-search-target='author']"
    assert_select "[data-isbn-search-target='description']"
    assert_select "[data-isbn-search-target='publishedDate']"
  end
end
