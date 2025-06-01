require "test_helper"

class MemoTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @book = books(:one)
    @memo = Memo.new(
      user: @user,
      book: @book,
      content: "これは読書メモです。とても興味深い内容でした。",
      is_public: false
    )
  end

  test "有効なデータでバリデーションを通過する" do
    assert @memo.valid?
  end

  test "コンテンツが必須である" do
    @memo.content = ""
    assert_not @memo.valid?
    assert_includes @memo.errors[:content], "can't be blank"
  end

  test "コンテンツが空白のみの場合はバリデーションに失敗する" do
    @memo.content = "   "
    assert_not @memo.valid?
  end

  test "コンテンツの最大長が2000文字である" do
    @memo.content = "a" * 2001
    assert_not @memo.valid?
    assert_includes @memo.errors[:content], "is too long (maximum is 2000 characters)"
  end

  test "コンテンツの最大長2000文字でバリデーションを通過する" do
    @memo.content = "a" * 2000
    assert @memo.valid?
  end

  test "ユーザーが必須である" do
    @memo.user = nil
    assert_not @memo.valid?
    assert_includes @memo.errors[:user], "must exist"
  end

  test "本が必須である" do
    @memo.book = nil
    assert_not @memo.valid?
    assert_includes @memo.errors[:book], "must exist"
  end

  test "is_publicのデフォルト値がfalseである" do
    memo = Memo.new(user: @user, book: @book, content: "テストメモ")
    memo.save!
    assert_not memo.is_public
  end

  test "is_publicがtrueに設定できる" do
    @memo.is_public = true
    assert @memo.valid?
    @memo.save!
    assert @memo.is_public
  end

  test "public?メソッドが正しく動作する" do
    @memo.is_public = true
    assert @memo.public?

    @memo.is_public = false
    assert_not @memo.public?
  end

  test "private?メソッドが正しく動作する" do
    @memo.is_public = false
    assert @memo.private?

    @memo.is_public = true
    assert_not @memo.private?
  end

  test "scopeが正しく動作する" do
    # テスト用のメモを作成
    public_memo = Memo.create!(
      user: @user,
      book: @book,
      content: "公開メモ",
      is_public: true
    )

    private_memo = Memo.create!(
      user: @user,
      book: @book,
      content: "非公開メモ",
      is_public: false
    )

    # public_memosスコープのテスト
    public_memos = Memo.public_memos
    assert_includes public_memos, public_memo
    assert_not_includes public_memos, private_memo

    # private_memosスコープのテスト
    private_memos = Memo.private_memos
    assert_includes private_memos, private_memo
    assert_not_includes private_memos, public_memo

    # by_bookスコープのテスト
    book_memos = Memo.by_book(@book)
    assert_includes book_memos, public_memo
    assert_includes book_memos, private_memo

    # by_userスコープのテスト
    user_memos = Memo.by_user(@user)
    assert_includes user_memos, public_memo
    assert_includes user_memos, private_memo
  end

  test "関連が正しく動作する" do
    @memo.save!

    # UserからMemoへのアクセス
    assert_includes @user.memos, @memo

    # BookからMemoへのアクセス
    assert_includes @book.memos, @memo

    # MemoからUser, Bookへのアクセス
    assert_equal @user, @memo.user
    assert_equal @book, @memo.book
  end
end
