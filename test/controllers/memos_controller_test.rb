require "test_helper"

class MemosControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:one)
    @other_user = users(:two)
    @book = books(:one)
    @other_book = books(:two)
    @memo = memos(:one)
    @other_memo = memos(:two)
  end

  # 認証テスト
  test "未認証ユーザーはindexにアクセスできない" do
    get book_memos_path(@book)
    assert_redirected_to new_user_session_path
  end

  test "未認証ユーザーはcreateできない" do
    post book_memos_path(@book), params: { memo: { content: "テストメモ" } }
    assert_redirected_to new_user_session_path
  end

  test "未認証ユーザーはupdateできない" do
    patch book_memo_path(@book, @memo), params: { memo: { content: "更新メモ" } }
    assert_redirected_to new_user_session_path
  end

  test "未認証ユーザーはdestroyできない" do
    delete book_memo_path(@book, @memo)
    assert_redirected_to new_user_session_path
  end

  # アクセス制御テスト
  test "他のユーザーの本のメモにはアクセスできない" do
    sign_in @user
    # 他のユーザーの本にアクセスしようとすると、find_byではなくfindを使っているためエラーになる
    begin
      get book_memos_path(@other_book)
      # もしエラーが発生しなかった場合は何らかのエラーレスポンスであることを確認
      assert_not_equal 200, response.status
    rescue ActiveRecord::RecordNotFound
      # これが期待される動作
      assert true
    end
  end

  # indexアクションのテスト
  test "indexで本のメモ一覧が表示される" do
    sign_in @user
    get book_memos_path(@book)
    assert_response :success
    assert_includes response.body, @memo.content
    assert_select "form[action='#{book_memos_path(@book)}']"
  end

  test "indexで新しいメモフォームが表示される" do
    sign_in @user
    get book_memos_path(@book)
    assert_response :success
    assert_select "form[action='#{book_memos_path(@book)}']"
    assert_select "textarea[name='memo[content]']"
  end

  # createアクションのテスト
  test "有効なデータでメモを作成できる" do
    sign_in @user
    assert_difference "Memo.count", 1 do
      post book_memos_path(@book), params: {
        memo: {
          content: "新しい読書メモです",
          is_public: true
        }
      }
    end
    assert_redirected_to book_path(@book)
    assert_equal "メモが正常に作成されました。", flash[:notice]

    created_memo = Memo.last
    assert_equal @user, created_memo.user
    assert_equal @book, created_memo.book
    assert_equal "新しい読書メモです", created_memo.content
    assert created_memo.is_public
  end

  test "is_publicがfalseでもメモを作成できる" do
    sign_in @user
    assert_difference "Memo.count", 1 do
      post book_memos_path(@book), params: {
        memo: {
          content: "非公開メモです",
          is_public: false
        }
      }
    end
    assert_redirected_to book_path(@book)

    created_memo = Memo.last
    assert_not created_memo.is_public
  end

  test "無効なデータでメモ作成に失敗する" do
    sign_in @user
    assert_no_difference "Memo.count" do
      post book_memos_path(@book), params: {
        memo: {
          content: "",
          is_public: false
        }
      }
    end
    assert_response :unprocessable_entity
    assert_select ".error", /can't be blank/
  end

  test "長すぎるコンテンツでメモ作成に失敗する" do
    sign_in @user
    assert_no_difference "Memo.count" do
      post book_memos_path(@book), params: {
        memo: {
          content: "a" * 2001,
          is_public: false
        }
      }
    end
    assert_response :unprocessable_entity
    assert_select ".error", /is too long/
  end

  # updateアクションのテスト
  test "有効なデータでメモを更新できる" do
    sign_in @user
    patch book_memo_path(@book, @memo), params: {
      memo: {
        content: "更新されたメモ内容",
        is_public: true
      }
    }
    assert_redirected_to book_path(@book)
    assert_equal "メモが正常に更新されました。", flash[:notice]

    @memo.reload
    assert_equal "更新されたメモ内容", @memo.content
    assert @memo.is_public
  end

  test "無効なデータでメモ更新に失敗する" do
    sign_in @user
    original_content = @memo.content
    patch book_memo_path(@book, @memo), params: {
      memo: {
        content: "",
        is_public: false
      }
    }
    assert_redirected_to book_path(@book)
    assert_equal "メモの更新に失敗しました。", flash[:alert]

    @memo.reload
    assert_equal original_content, @memo.content
  end

  test "長すぎるコンテンツでメモ更新に失敗する" do
    sign_in @user
    original_content = @memo.content
    patch book_memo_path(@book, @memo), params: {
      memo: {
        content: "a" * 2001,
        is_public: false
      }
    }
    assert_redirected_to book_path(@book)
    assert_equal "メモの更新に失敗しました。", flash[:alert]

    @memo.reload
    assert_equal original_content, @memo.content
  end

  # destroyアクションのテスト
  test "自分のメモを削除できる" do
    sign_in @user
    assert_difference "Memo.count", -1 do
      delete book_memo_path(@book, @memo)
    end
    assert_redirected_to book_memos_path(@book)
    assert_equal "メモが削除されました。", flash[:notice]
  end

  test "削除後にメモが存在しないことを確認" do
    sign_in @user
    memo_id = @memo.id
    delete book_memo_path(@book, @memo)
    assert_raises(ActiveRecord::RecordNotFound) do
      Memo.find(memo_id)
    end
  end

  # エッジケーステスト
  test "存在しない本に対してメモ操作しようとすると404エラー" do
    sign_in @user
    begin
      get book_memos_path(99999)
      assert_not_equal 200, response.status
    rescue ActiveRecord::RecordNotFound
      assert true
    end
  end

  test "パラメータなしでメモ作成しようとするとバリデーションエラー" do
    sign_in @user
    assert_no_difference "Memo.count" do
      post book_memos_path(@book), params: { memo: { content: "" } }
    end
    assert_response :unprocessable_entity
  end

  # === 削除機能の詳細テスト ===

  test "メモを削除すると正しいflashメッセージが表示される" do
    sign_in @user
    delete book_memo_path(@book, @memo)
    assert_redirected_to book_memos_path(@book)
    follow_redirect!
    assert_includes response.body, "メモが削除されました。"
  end

  test "削除後にメモが完全に削除されている" do
    sign_in @user
    memo_id = @memo.id
    delete book_memo_path(@book, @memo)

    assert_raises(ActiveRecord::RecordNotFound) do
      Memo.find(memo_id)
    end
  end

  test "他のユーザーのメモは削除できない" do
    sign_in @user
    original_count = Memo.count

    begin
      delete book_memo_path(@other_book, @other_memo)
      assert_not_equal 200, response.status
    rescue ActiveRecord::RecordNotFound
      assert true
    end

    # メモが削除されていないことを確認
    assert_equal original_count, Memo.count
  end

  test "存在しないメモを削除しようとすると404エラー" do
    sign_in @user

    begin
      delete book_memo_path(@book, 99999)
      assert_not_equal 200, response.status
    rescue ActiveRecord::RecordNotFound
      assert true
    end
  end

  test "削除処理はDELETEメソッドのみ受け付ける" do
    sign_in @user

    # POSTメソッドでは削除できない
    assert_no_difference("Memo.count") do
      begin
        post book_memo_path(@book, @memo)
        # ルートが存在しないため404エラーになる
        assert_not_equal 200, response.status
      rescue ActionController::RoutingError
        assert true
      end
    end
  end

  test "削除権限：自分のメモのみ削除可能" do
    sign_in @user

    # 自分のメモは削除可能
    assert_difference("Memo.count", -1) do
      delete book_memo_path(@book, @memo)
    end

    # 他のユーザーのメモは削除できない（既にテスト済みだが、権限テストとして明示）
    other_memo = @other_book.memos.create!(
      user: @other_user,
      content: "他のユーザーのメモ",
      is_public: false
    )

    assert_no_difference("Memo.count") do
      begin
        delete book_memo_path(@other_book, other_memo)
        assert_not_equal 200, response.status
      rescue ActiveRecord::RecordNotFound
        assert true
      end
    end
  end
end
