# GoogleBooksApiService

HTTPartyを使用してGoogle Books APIからISBNで書籍情報を取得するサービスクラスです。

## 機能

- ✅ ISBNの自動クリーンアップ（ハイフン、スペースなどを自動除去）
- ✅ 詳細なエラーハンドリングとログ出力
- ✅ 2つの使用方法：詳細情報取得とシンプル情報取得
- ✅ 構造化されたレスポンス形式

## 使用方法

### 基本的な使用方法（詳細情報）

```ruby
# ハイフン付きISBNでもOK
result = GoogleBooksApiService.find_book_by_isbn("978-4-16-323980-4")

if result[:success]
  book_data = result[:data]
  puts "書籍タイトル: #{book_data[:title]}"
  puts "著者: #{book_data[:authors].join(', ')}"
  puts "出版日: #{book_data[:published_date]}"
  puts "ページ数: #{book_data[:page_count]}"
else
  puts "エラー: #{result[:error]}"
end
```

### シンプルな使用方法（基本情報のみ）

```ruby
# より簡単な使用方法
book = GoogleBooksApiService.search_by_isbn("9784163239804")

if book
  puts "タイトル: #{book[:title]}"
  puts "著者: #{book[:author]}"
  puts "カバー画像: #{book[:cover_image_url]}"
else
  puts "書籍が見つかりませんでした"
end
```

### ISBNの自動クリーンアップ

以下の形式のISBNは全て自動的にクリーンアップされます：

```ruby
# 全て同じように処理されます
GoogleBooksApiService.find_book_by_isbn("9784163239804")
GoogleBooksApiService.find_book_by_isbn("978-4-16-323980-4")  # ハイフン付き
GoogleBooksApiService.find_book_by_isbn("978 4 16 323980 4")  # スペース付き
GoogleBooksApiService.find_book_by_isbn("ISBN: 978-4-16-323980-4")  # プレフィックス付き
```

### レスポンス形式

#### find_book_by_isbn（詳細情報）

**成功時:**
```ruby
{
  success: true,
  error: nil,
  data: {
    title: "書籍タイトル",
    subtitle: "サブタイトル",
    authors: ["著者1", "著者2"],
    published_date: "2005-06",
    description: "書籍の説明",
    page_count: 275,
    categories: ["カテゴリ"],
    language: "ja",
    preview_link: "プレビューリンク",
    info_link: "詳細情報リンク",
    image_links: {
      small_thumbnail: "小サムネイル画像URL",
      thumbnail: "サムネイル画像URL",
      small: "小画像URL",
      medium: "中画像URL",
      large: "大画像URL"
    },
    industry_identifiers: [
      {"type" => "ISBN_10", "identifier" => "4163239804"},
      {"type" => "ISBN_13", "identifier" => "9784163239804"}
    ],
    publisher: "出版社",
    average_rating: 4.0,
    ratings_count: 5
  }
}
```

**失敗時:**
```ruby
{
  success: false,
  error: "エラーメッセージ",
  data: nil
}
```

#### search_by_isbn（シンプル情報）

**成功時:**
```ruby
{
  title: "書籍タイトル",
  author: "著者1, 著者2",
  description: "書籍の説明",
  published_date: "2005-06",
  cover_image_url: "カバー画像URL"
}
```

**失敗時:**
```ruby
nil
```

### エラーの種類

1. **ISBNが無効**: 空文字やnilの場合
2. **通信エラー**: インターネット接続やAPIサーバーの問題
3. **APIエラー**: Google Books APIからのエラーレスポンス
4. **書籍が見つからない**: 指定されたISBNの書籍が存在しない

### 使用例

#### コントローラーでの使用（詳細情報）
```ruby
class BooksController < ApplicationController
  def show
    isbn = params[:isbn]
    @book_result = GoogleBooksApiService.find_book_by_isbn(isbn)
    
    if @book_result[:success]
      @book = @book_result[:data]
    else
      flash[:error] = @book_result[:error]
      redirect_to root_path
    end
  end
end
```

#### コントローラーでの使用（シンプル情報）
```ruby
class BooksController < ApplicationController
  def quick_search
    isbn = params[:isbn]
    @book = GoogleBooksApiService.search_by_isbn(isbn)
    
    if @book.nil?
      flash[:error] = "書籍が見つかりませんでした"
      redirect_to root_path
    end
  end
end
```

#### バックグラウンドジョブでの使用
```ruby
class BookImportJob < ApplicationJob
  def perform(isbn)
    result = GoogleBooksApiService.find_book_by_isbn(isbn)
    
    if result[:success]
      Book.create!(result[:data])
    else
      Rails.logger.error "書籍インポートエラー: #{result[:error]}"
    end
  end
end
```

## ログ出力

サービスは以下の情報をRails.loggerに出力します：

- 成功時: 取得した書籍のタイトル
- エラー時: 詳細なエラー情報
- 書籍が見つからない場合: 検索結果なしの情報

## テスト

```bash
rails test test/services/google_books_api_service_test.rb
```

## 必要なGem

- httparty

```ruby
# Gemfile
gem "httparty"
``` 