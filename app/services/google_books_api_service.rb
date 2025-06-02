require "httparty"

class GoogleBooksApiService
  include HTTParty

  BASE_URL = "https://www.googleapis.com/books/v1/volumes"
  base_uri "https://www.googleapis.com/books/v1"

  def self.find_book_by_isbn(isbn)
    # ISBNの形式をクリーンアップ（ハイフンなどを削除）
    clean_isbn = clean_isbn_format(isbn)
    return error_response("ISBNが無効です") if clean_isbn.empty?

    begin
      response = get("/volumes", query: { q: "isbn:#{clean_isbn}" })

      if response.success?
        parse_response(response)
      else
        Rails.logger.error "Google Books API error: HTTP #{response.code} - #{response.message}"
        error_response("APIエラー: #{response.code} - #{response.message}")
      end
    rescue StandardError => e
      Rails.logger.error "Google Books API communication error: #{e.message}"
      error_response("通信エラー: #{e.message}")
    end
  end

  # 簡単な使用のためのシンプルなメソッドも提供
  def self.search_by_isbn(isbn)
    result = find_book_by_isbn(isbn)
    return nil unless result[:success]

    data = result[:data]
    {
      title: data[:title],
      author: data[:authors]&.join(", "),
      description: data[:description],
      published_date: data[:published_date],
      cover_image_url: data.dig(:image_links, :thumbnail)
    }
  end

  private

  def self.clean_isbn_format(isbn)
    isbn.to_s.gsub(/[^0-9X]/i, "")
  end

  def self.error_response(message)
    {
      success: false,
      error: message,
      data: nil
    }
  end

  def self.parse_response(response)
    data = response.parsed_response

    if data["totalItems"].to_i == 0 || !data["items"]
      Rails.logger.info "No books found for the given ISBN"
      return error_response("指定されたISBNの書籍が見つかりませんでした")
    end

    book = data["items"].first["volumeInfo"]
    Rails.logger.info "Successfully retrieved book: #{book['title']}"

    {
      success: true,
      error: nil,
      data: {
        title: book["title"],
        subtitle: book["subtitle"],
        authors: book["authors"] || [],
        published_date: book["publishedDate"],
        description: book["description"],
        page_count: book["pageCount"],
        categories: book["categories"] || [],
        language: book["language"],
        preview_link: book["previewLink"],
        info_link: book["infoLink"],
        image_links: {
          small_thumbnail: book.dig("imageLinks", "smallThumbnail"),
          thumbnail: book.dig("imageLinks", "thumbnail"),
          small: book.dig("imageLinks", "small"),
          medium: book.dig("imageLinks", "medium"),
          large: book.dig("imageLinks", "large")
        },
        industry_identifiers: book["industryIdentifiers"] || [],
        publisher: book["publisher"],
        average_rating: book["averageRating"],
        ratings_count: book["ratingsCount"]
      }
    }
  end
end
