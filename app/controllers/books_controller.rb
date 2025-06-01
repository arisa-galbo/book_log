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

  private

  def set_book
    @book = current_user.books.find(params[:id])
  end

  def book_params
    params.require(:book).permit(:title, :author, :isbn, :published_date, :description, :progress_status)
  end
end
