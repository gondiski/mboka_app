import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  connect() {
    if (!this.hasInputTarget) return

    this.flatpickr = flatpickr(this.inputTarget, {
      monthSelectorType: "dropdown",
            altInput: true,
      altFormat: "F j, Y"
    })
  }

  disconnect() {
    if (this.flatpickr) {
      this.flatpickr.destroy()
    }
  }
}
