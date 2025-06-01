require "test_helper"

class BooksControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = users(:one)
    @other_user = users(:two)
    @book = books(:one)
    @other_user_book = books(:two)
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
    assert_includes response.body, @book.title
  end

  test "本の詳細画面でメモが表示される" do
    memo = @book.memos.create!(
      user: @user,
      content: "テストメモ内容",
      is_public: false
    )

    get book_url(@book)
    assert_response :success
    assert_includes response.body, memo.content
  end

  test "本の詳細画面でメモ作成フォームが表示される" do
    get book_url(@book)
    assert_response :success
    assert_select "form[action='#{book_memos_path(@book)}']"
    assert_select "textarea[name='memo[content]']"
    assert_select "input[name='memo[is_public]']"
  end

  test "本の詳細画面から簡単メモを作成できる" do
    assert_difference "@book.memos.count", 1 do
      post book_memos_path(@book), params: {
        memo: {
          content: "書籍詳細から作成したメモ",
          is_public: false
        }
      }
    end
    follow_redirect!
    assert_includes response.body, "書籍詳細から作成したメモ"
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

  # === ユーザー間アクセス制御テスト ===

  test "ログインユーザーは自分の本のみ表示される" do
    get books_url
    assert_response :success
    assert_includes response.body, @book.title
    assert_not_includes response.body, @other_user_book.title
  end

  test "他のユーザーの本の詳細を直接表示しようとすると404エラー" do
    begin
      get book_url(@other_user_book)
      assert_not_equal 200, response.status
    rescue ActiveRecord::RecordNotFound
      assert true
    end
  end

  test "他のユーザーの本を編集しようとすると404エラー" do
    begin
      get edit_book_url(@other_user_book)
      assert_not_equal 200, response.status
    rescue ActiveRecord::RecordNotFound
      assert true
    end
  end

  test "他のユーザーの本を更新しようとすると404エラー" do
    begin
      patch book_url(@other_user_book), params: {
        book: {
          title: "悪意のある更新",
          author: @other_user_book.author
        }
      }
      assert_not_equal 200, response.status
    rescue ActiveRecord::RecordNotFound
      assert true
    end
  end

  test "他のユーザーの本を削除しようとすると404エラー" do
    original_count = Book.count
    begin
      delete book_url(@other_user_book)
      assert_not_equal 200, response.status
    rescue ActiveRecord::RecordNotFound
      assert true
    end
    # 他のユーザーの本が削除されていないことを確認
    assert_equal original_count, Book.count
  end

  test "作成した本は自動的に現在のユーザーに紐づく" do
    post books_url, params: {
      book: {
        title: "テスト本",
        author: "テスト著者",
        progress_status: "unread"
      }
    }

    created_book = Book.last
    assert_equal @user, created_book.user
  end

  test "未認証時の各アクションでログイン画面にリダイレクト" do
    sign_out @user

    # index
    get books_url
    assert_redirected_to new_user_session_url

    # show
    get book_url(@book)
    assert_redirected_to new_user_session_url

    # new
    get new_book_url
    assert_redirected_to new_user_session_url

    # edit
    get edit_book_url(@book)
    assert_redirected_to new_user_session_url

    # create
    post books_url, params: { book: { title: "テスト", author: "テスト" } }
    assert_redirected_to new_user_session_url

    # update
    patch book_url(@book), params: { book: { title: "テスト" } }
    assert_redirected_to new_user_session_url

    # destroy
    delete book_url(@book)
    assert_redirected_to new_user_session_url
  end

  test "ログアウト後に再ログインしても自分の本のみアクセス可能" do
    sign_out @user
    sign_in @other_user

    get books_url
    assert_response :success
    assert_includes response.body, @other_user_book.title
    assert_not_includes response.body, @book.title
  end

  test "URLを直接指定しても他ユーザーの本にはアクセスできない" do
    # 他のユーザーでログイン
    sign_out @user
    sign_in @other_user

    begin
      get book_url(@book)  # @userの本にアクセス
      assert_not_equal 200, response.status
    rescue ActiveRecord::RecordNotFound
      assert true
    end
  end

  test "異なるユーザーが同じタイトル・著者の本を登録できる" do
    # 最初のユーザーが本を登録
    book_params = {
      title: "共通の本",
      author: "共通の著者",
      progress_status: "unread"
    }

    post books_url, params: { book: book_params }
    assert_response :redirect

    user1_book = Book.last
    assert_equal @user, user1_book.user

    # 別のユーザーで同じ本を登録
    sign_out @user
    sign_in @other_user

    assert_difference("Book.count") do
      post books_url, params: { book: book_params }
    end

    user2_book = Book.last
    assert_equal @other_user, user2_book.user
    assert_equal user1_book.title, user2_book.title
    assert_equal user1_book.author, user2_book.author
  end

  # === 削除機能の詳細テスト ===

  test "本を削除すると正しいflashメッセージが表示される" do
    delete book_url(@book)
    assert_redirected_to books_url
    follow_redirect!
    assert_includes response.body, "本が削除されました。"
  end

  test "削除後に本が完全に削除されている" do
    book_id = @book.id
    delete book_url(@book)

    assert_raises(ActiveRecord::RecordNotFound) do
      Book.find(book_id)
    end
  end

  test "本を削除すると関連するメモも削除される" do
    # テスト用のメモを作成
    memo1 = @book.memos.create!(
      user: @user,
      content: "削除テスト用メモ1",
      is_public: false
    )
    memo2 = @book.memos.create!(
      user: @user,
      content: "削除テスト用メモ2",
      is_public: true
    )

    memo1_id = memo1.id
    memo2_id = memo2.id

    # 本に関連するメモの総数を取得
    related_memos_count = @book.memos.count

    # 本を削除
    assert_difference("Book.count", -1) do
      assert_difference("Memo.count", -related_memos_count) do
        delete book_url(@book)
      end
    end

    # メモも削除されていることを確認
    assert_raises(ActiveRecord::RecordNotFound) do
      Memo.find(memo1_id)
    end
    assert_raises(ActiveRecord::RecordNotFound) do
      Memo.find(memo2_id)
    end
  end

  test "存在しない本を削除しようとすると404エラー" do
    begin
      delete book_url(99999)
      assert_not_equal 200, response.status
    rescue ActiveRecord::RecordNotFound
      assert true
    end
  end

  test "削除処理はDELETEメソッドのみ受け付ける" do
    # POSTメソッドでは削除できない
    assert_no_difference("Book.count") do
      post book_url(@book)
      # ルートが存在しないため、エラーになるか適切にハンドリングされる
    end
  end
end
