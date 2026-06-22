import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "form", "progress", "progressBar", "progressText", "result", "resultText"]

  connect() {
    this.uploading = false
  }

  upload() {
    if (this.uploading) return
    if (!this.inputTarget.files.length) return

    this.uploading = true
    this.showProgress()

    const formData = new FormData(this.formTarget)
    const xhr = new XMLHttpRequest()

    xhr.upload.addEventListener("progress", (e) => {
      if (e.lengthComputable) {
        const percent = Math.round((e.loaded / e.total) * 100)
        this.updateProgress(percent)
      }
    })

    xhr.addEventListener("load", () => {
      this.uploading = false
      if (xhr.status === 200 || xhr.status === 302) {
        const response = JSON.parse(xhr.responseText)
        this.showResult(response.processed, response.skipped)
      } else {
        this.showResult(0, 0, true)
      }
    })

    xhr.addEventListener("error", () => {
      this.uploading = false
      this.showResult(0, 0, true)
    })

    xhr.open("POST", this.formTarget.action)
    xhr.setRequestHeader("Accept", "application/json")
    xhr.setRequestHeader("X-CSRF-Token", document.querySelector('meta[name="csrf-token"]').content)
    xhr.send(formData)
  }

  showProgress() {
    this.progressTarget.classList.remove("hidden")
    this.resultTarget.classList.add("hidden")
    this.updateProgress(0)
  }

  updateProgress(percent) {
    this.progressBarTarget.style.width = `${percent}%`
    this.progressTextTarget.textContent = `${percent}%`
  }

  showResult(processed, skipped, error = false) {
    this.progressTarget.classList.add("hidden")
    this.resultTarget.classList.remove("hidden")

    if (error) {
      this.resultTarget.className = this.resultTarget.className.replace(/bg-\w+-50/, 'bg-red-50').replace(/border-\w+-200/, 'border-red-200').replace(/text-\w+-700/, 'text-red-700')
      this.resultTextTarget.textContent = "Upload failed. Please try again."
    } else {
      this.resultTarget.className = this.resultTarget.className.replace(/bg-\w+-50/, 'bg-green-50').replace(/border-\w+-200/, 'border-green-200').replace(/text-\w+-700/, 'text-green-700')
      this.resultTextTarget.innerHTML = `<strong>${processed}</strong> users queued for onboarding.` + (skipped > 0 ? ` <strong>${skipped}</strong> rows skipped.` : '')
    }

    this.inputTarget.value = ""
  }
}
