class MemosController < ApplicationController
  before_action :authenticate_user!
  before_action :set_book
  before_action :set_memo, only: [ :update, :destroy ]

  def index
    @memos = @book.memos.includes(:user).recent
    @memo = @book.memos.build
  end

  def create
    @memo = @book.memos.build(memo_params)
    @memo.user = current_user

    if @memo.save
      redirect_to book_path(@book), notice: "メモが正常に作成されました。"
    else
      @memos = @book.memos.includes(:user).recent
      render :index, status: :unprocessable_entity
    end
  end

  def update
    if @memo.update(memo_params)
      redirect_to book_path(@book), notice: "メモが正常に更新されました。"
    else
      redirect_to book_path(@book), alert: "メモの更新に失敗しました。"
    end
  end

  def destroy
    @memo.destroy
    redirect_to book_memos_path(@book), notice: "メモが削除されました。"
  end

  private

  def set_book
    @book = current_user.books.find(params[:book_id])
  end

  def set_memo
    @memo = @book.memos.where(user: current_user).find(params[:id])
  end

  def memo_params
    params.require(:memo).permit(:content, :is_public)
  end
end
