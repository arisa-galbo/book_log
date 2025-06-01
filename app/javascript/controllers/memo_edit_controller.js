import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display", "edit"]

  toggleEdit() {
    if (this.editTarget.style.display === "none") {
      // 編集モードに切り替え
      this.displayTarget.style.display = "none"
      this.editTarget.style.display = "block"
      
      // テキストエリアにフォーカス
      const textarea = this.editTarget.querySelector('textarea')
      if (textarea) {
        textarea.focus()
        // カーソルを末尾に移動
        textarea.setSelectionRange(textarea.value.length, textarea.value.length)
      }
    } else {
      // 表示モードに切り替え
      this.editTarget.style.display = "none"
      this.displayTarget.style.display = "block"
    }
  }
} 