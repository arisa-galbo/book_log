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
    # bookページのルートをテスト
    assert_routing "/books", { controller: "books", action: "index" }
    assert_routing "/books/new", { controller: "books", action: "new" }
    assert_routing "/books/1", { controller: "books", action: "show", id: "1" }
    assert_routing "/books/1/edit", { controller: "books", action: "edit", id: "1" }
    assert_routing({ method: "patch", path: "/books/1" }, { controller: "books", action: "update", id: "1" })
    assert_routing({ method: "delete", path: "/books/1" }, { controller: "books", action: "destroy", id: "1" })
  end
end
