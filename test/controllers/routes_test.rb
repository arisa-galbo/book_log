require "test_helper"

class RoutesTest < ActionDispatch::IntegrationTest
  test "ルートパスが正しく設定されている" do
    assert_generates "/", controller: "home", action: "index"
  end

  test "Deviseのユーザー認証ルートが正しく設定されている" do
    # Deviseのデフォルトルートをテスト
    assert_routing "/users/sign_in", { controller: "devise/sessions", action: "new" }
    assert_routing "/users/sign_up", { controller: "devise/registrations", action: "new" }
    assert_routing({ method: "delete", path: "/users/sign_out" }, { controller: "devise/sessions", action: "destroy" })
  end
end
