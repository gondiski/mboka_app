import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container"]
  static values = { page: Number, totalPages: Number, baseUrl: String }

  connect() {
    this.loading = false
    this.trigger = null

    this.observer = new IntersectionObserver(
      entries => this.handleIntersection(entries),
      { rootMargin: "400px", threshold: 0 }
    )

    this.findAndObserveTrigger()
  }

  disconnect() {
    this.observer.disconnect()
  }

  findAndObserveTrigger() {
    this.trigger = this.element.querySelector("[data-infinite-scroll-trigger]")
    if (this.trigger && this.pageValue < this.totalPagesValue) {
      this.observer.observe(this.trigger)
    }
  }

  handleIntersection(entries) {
    entries.forEach(entry => {
      if (entry.isIntersecting && !this.loading && this.pageValue < this.totalPagesValue) {
        this.loadNextPage()
      }
    })
  }

  goToPage(event) {
    const page = parseInt(event.currentTarget.dataset.pageNum)
    if (page && page !== this.pageValue && !this.loading) {
      this.loadSpecificPage(page)
    }
  }

  async loadSpecificPage(targetPage) {
    this.loading = true
    const url = new URL(window.location.origin + this.baseUrlValue)
    url.searchParams.set("page", targetPage)

    try {
      const response = await fetch(url.toString(), { headers: { "Accept": "text/html" } })
      const html = await response.text()
      const parser = new DOMParser()
      const doc = parser.parseFromString(html, "text/html")

      const newCards = doc.querySelectorAll("[data-digest-card]")
      if (newCards.length > 0) {
        while (this.containerTarget.firstChild) {
          this.containerTarget.removeChild(this.containerTarget.firstChild)
        }
        newCards.forEach(card => this.containerTarget.appendChild(document.adoptNode(card)))
      }

      this.pageValue = targetPage
      this.animatePageNumber(targetPage)
      this.replaceTrigger(doc)
    } catch (error) {
      console.error("Infinite scroll error:", error)
    } finally {
      this.loading = false
    }
  }

  async loadNextPage() {
    this.loading = true
    const nextPage = this.pageValue + 1
    const url = new URL(window.location.origin + this.baseUrlValue)
    url.searchParams.set("page", nextPage)

    try {
      const response = await fetch(url.toString(), { headers: { "Accept": "text/html" } })
      const html = await response.text()
      const parser = new DOMParser()
      const doc = parser.parseFromString(html, "text/html")

      const newCards = doc.querySelectorAll("[data-digest-card]")
      if (newCards.length > 0) {
        newCards.forEach(card => this.containerTarget.appendChild(document.adoptNode(card)))
      }

      this.pageValue = nextPage
      this.animatePageNumber(nextPage)
      this.replaceTrigger(doc)
    } catch (error) {
      console.error("Infinite scroll error:", error)
    } finally {
      this.loading = false
    }
  }

  replaceTrigger(doc) {
    if (this.trigger) {
      this.observer.unobserve(this.trigger)
      this.trigger.remove()
    }

    if (this.pageValue < this.totalPagesValue) {
      const newTrigger = doc.querySelector("[data-infinite-scroll-trigger]")
      if (newTrigger) {
        const imported = document.adoptNode(newTrigger)
        const table = this.containerTarget.closest("table")
        if (table) {
          table.after(imported)
        } else {
          this.containerTarget.after(imported)
        }
        this.trigger = imported
        this.observer.observe(this.trigger)
      }
    }
  }

  animatePageNumber(page) {
    const el = document.querySelector("[data-current-page]")
    if (el) {
      const digits = page.toString().split("")
      el.innerHTML = digits.map(d => `<span class="digit inline-block digit-animate">${d}</span>`).join("")
    }

    document.querySelectorAll("[data-page-num]").forEach(circle => {
      const p = parseInt(circle.dataset.pageNum)
      circle.classList.toggle("bg-brand-500", p === page)
      circle.classList.toggle("text-white", p === page)
      circle.classList.toggle("scale-110", p === page)
      circle.classList.toggle("shadow-lg", p === page)
      circle.classList.toggle("bg-gray-100", p !== page)
      circle.classList.toggle("text-gray-400", p !== page)
      circle.classList.toggle("scale-100", p !== page)
      circle.classList.toggle("ring-2", p === page)
      circle.classList.toggle("ring-brand-300", p === page)
    })
  }
}
