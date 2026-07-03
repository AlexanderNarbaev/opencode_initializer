// Click-to-zoom for Mermaid diagrams and images
document.addEventListener("DOMContentLoaded", () => {
  // Create modal overlay
  const overlay = document.createElement("div")
  overlay.className = "diagram-overlay"
  overlay.innerHTML = '<div class="diagram-overlay-content"></div>'
  overlay.addEventListener("click", () => overlay.classList.remove("active"))
  document.body.appendChild(overlay)

  // Add click handler to all Mermaid diagrams
  document.querySelectorAll(".mermaid").forEach(el => {
    el.style.cursor = "zoom-in"
    el.title = "Click to enlarge"
    el.addEventListener("click", (e) => {
      e.stopPropagation()
      const content = overlay.querySelector(".diagram-overlay-content")
      content.innerHTML = el.outerHTML
      // Re-render mermaid in the modal
      if (window.mermaid) {
        content.querySelector(".mermaid").removeAttribute("data-processed")
        window.mermaid.run({ nodes: [content.querySelector(".mermaid")] })
      }
      overlay.classList.add("active")
    })
  })

  // Add click handler to images (except icons/avatars)
  document.querySelectorAll("article img:not(.twemoji):not(.md-logo)").forEach(img => {
    img.style.cursor = "zoom-in"
    img.title = "Click to enlarge"
    img.addEventListener("click", (e) => {
      e.stopPropagation()
      const content = overlay.querySelector(".diagram-overlay-content")
      content.textContent = ''
      const zoomImg = document.createElement('img')
      zoomImg.src = img.src
      zoomImg.alt = img.alt
      zoomImg.style.cssText = 'max-width:95vw;max-height:95vh'
      content.appendChild(zoomImg)
      overlay.classList.add("active")
    })
  })
})
