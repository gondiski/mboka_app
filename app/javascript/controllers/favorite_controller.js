// app/javascript/controllers/favorite_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  toggle(event) {
    event.stopPropagation()
    event.preventDefault()

    const star = this.element.querySelector("[data-star-icon]")
    if (star) {
      star.classList.remove("star-pop")
      void star.offsetWidth
      star.classList.add("star-pop")
    }

    this.element.querySelector("form").requestSubmit()
  }
}
