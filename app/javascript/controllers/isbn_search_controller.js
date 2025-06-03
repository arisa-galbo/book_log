import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "button", "result", "title", "author", "description", "publishedDate"]
  
  search(event) {
    event.preventDefault()
    
    const isbn = this.inputTarget.value.trim()
    
    if (!isbn) {
      this.showMessage('ISBNを入力してください', 'error')
      return
    }
    
    this.setLoadingState(true)

    const searchUrl = `/books/search_by_isbn?isbn=${encodeURIComponent(isbn)}`
    
    fetch(searchUrl, {
      method: 'GET',
      headers: {
        'Accept': 'application/json'
      }
    })
    .then(response => {
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }
      return response.json()
    })
    .then(data => {
      this.setLoadingState(false)
      
      if (data.success && data.book) {
        this.fillForm(data.book)
        this.showMessage('書籍情報を取得しました！', 'success')
      } else {
        this.showMessage(data.error || '書籍が見つかりませんでした', 'error')
      }
    })
    .catch(error => {
      console.error('Search error:', error)
      this.setLoadingState(false)
      this.showMessage('検索中にエラーが発生しました', 'error')
    })
  }
  
  handleKeypress(event) {
    if (event.key === 'Enter') {
      event.preventDefault()
      this.search(event)
    }
  }
  
  setLoadingState(loading) {
    const searchText = this.buttonTarget.querySelector('.search-text')
    const loadingText = this.buttonTarget.querySelector('.loading-text')
    
    if (searchText && loadingText) {
      if (loading) {
        searchText.style.display = 'none'
        loadingText.style.display = 'inline'
        this.buttonTarget.disabled = true
      } else {
        searchText.style.display = 'inline'
        loadingText.style.display = 'none'
        this.buttonTarget.disabled = false
      }
    }
  }
  
  fillForm(bookData) {
    if (this.hasTitleTarget && bookData.title) {
      this.titleTarget.value = bookData.title
    }
    
    if (this.hasAuthorTarget && bookData.author) {
      this.authorTarget.value = bookData.author
    }
    
    if (this.hasDescriptionTarget && bookData.description) {
      this.descriptionTarget.value = bookData.description
    }
    
    if (this.hasPublishedDateTarget && bookData.published_date) {
      this.publishedDateTarget.value = bookData.published_date
    }
  }
  
  showMessage(message, type) {
    if (this.hasResultTarget) {
      this.resultTarget.textContent = message
      this.resultTarget.className = `search-result-message ${type}`
      this.resultTarget.style.display = 'block'
      
      setTimeout(() => {
        this.resultTarget.style.display = 'none'
      }, 3000)
    } else {
      console.error("Result target not found for message display")
    }
  }
} 