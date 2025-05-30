require "test_helper"

class UserTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @new_user = User.new(email: "test@example.com", password: "password123", password_confirmation: "password123")
  end

  test "バリデーションを通過する" do
    assert @new_user.valid?
  end

  test "emailが空の場合はバリデーションに失敗する" do
    @new_user.email = ""
    assert_not @new_user.valid?
  end

  test "emailが重複している場合はバリデーションに失敗する" do
    @new_user.email = @user.email
    @new_user.save
    assert_not @new_user.valid?
  end

  test "emailが有効な形式でない場合はバリデーションに失敗する" do
    invalid_emails = %w[user@example,com user_at_foo.org user.name@example.]
    invalid_emails.each do |invalid_email|
      @new_user.email = invalid_email
      assert_not @new_user.valid?, "#{invalid_email.inspect} should be invalid"
    end
  end

  test "passwordが空の場合はバリデーションに失敗する" do
    @new_user.password = @new_user.password_confirmation = " " * 6
    assert_not @new_user.valid?
  end

  test "passwordが6文字未満の場合はバリデーションに失敗する" do
    @new_user.password = @new_user.password_confirmation = "a" * 5
    assert_not @new_user.valid?
  end
end
