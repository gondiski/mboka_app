import { Controller } from "@hotwired/stimulus"
import Swal from "sweetalert2"

// Connects to data-controller="flash"
export default class extends Controller {
  static values = {
    type: String,
    message: String
  }

  connect() {
    const isSuccess = this.typeValue === "notice" || this.typeValue === "success"
    const iconType = isSuccess ? "success" : "error"
    const title = this.messageValue
    const bgColor = isSuccess ? '#f0fdf4' : '#fef2f2'
    const textColor = isSuccess ? '#15803d' : '#991b1b'

    // Play the existing sound if the function is defined
    if (typeof window.playToastSound === 'function') {
      window.playToastSound(iconType)
    }

    Swal.fire({
      toast: true,
      position: 'top-end',
      icon: iconType,
      title: title,
      showConfirmButton: false,
      timer: 4000,
      timerProgressBar: true,
      background: bgColor,
      color: textColor,
      customClass: { popup: 'swal2-toast-custom' },
      didOpen: (toast) => {
        toast.addEventListener('mouseenter', Swal.stopTimer)
        toast.addEventListener('mouseleave', Swal.resumeTimer)
      }
    })
  }
}
