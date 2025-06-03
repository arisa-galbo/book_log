class BooksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_book, only: [ :show, :edit, :update, :destroy ]

  def index
    @books = current_user.books.includes(:user)
    @books = @books.by_progress_status(params[:progress_status]) if params[:progress_status].present?
    @books = @books.search_by_title(params[:search]) if params[:search].present?
  end

  def show
    @memos = @book.memos.includes(:user).recent.limit(5)
    @memo = @book.memos.build
  end

  def new
    @book = current_user.books.build
  end

  def create
    @book = current_user.books.build(book_params)

    if @book.save
      redirect_to @book, notice: "本が正常に登録されました。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @book.update(book_params)
      redirect_to @book, notice: "本が正常に更新されました。"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @book.destroy
    redirect_to books_path, notice: "本が削除されました。"
  end

  def search_by_isbn
    respond_to do |format|
      format.json do
        isbn = params[:isbn]

        if isbn.blank?
          render json: { success: false, error: "ISBNを入力してください" }
          return
        end

        result = GoogleBooksApiService.find_book_by_isbn(isbn)

        if result[:success]
          book_data = result[:data]
          # 日付フォーマットを調整（YYYY-MM-DD形式に変換）
          published_date = parse_published_date(book_data[:published_date])

          render json: {
            success: true,
            book: {
              title: book_data[:title],
              author: book_data[:authors]&.join(", "),
              description: book_data[:description],
              published_date: published_date
            }
          }
        else
          render json: { success: false, error: result[:error] }
        end
      end
    end
  end

  private

  def set_book
    @book = current_user.books.find(params[:id])
  end

  def book_params
    params.require(:book).permit(:title, :author, :isbn, :published_date, :description, :progress_status)
  end

  def parse_published_date(date_string)
    return nil if date_string.blank?

    # "2005-06" や "2005" などの形式を YYYY-MM-DD に変換
    case date_string.length
    when 4 # "2005"
      "#{date_string}-01-01"
    when 7 # "2005-06"
      "#{date_string}-01"
    when 10 # "2005-06-15" (既に正しい形式)
      date_string
    else
      # その他の形式の場合は年だけ抽出を試行
      year = date_string.match(/\d{4}/)&.to_s
      year ? "#{year}-01-01" : nil
    end
  end
end
