// app/javascript/controllers/favorite_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  toggle(event) {
    event.stopPropagation()
    event.preventDefault()
    this.element.querySelector("form").requestSubmit()
  }
}
