// Click-to-zoom for Mermaid diagrams and images — with SPA navigation support
function setupZoom() {
  const existing = document.querySelector(".diagram-overlay")
  if (existing) return
  const overlay = document.createElement("div")
  overlay.className = "diagram-overlay"
  overlay.innerHTML = '<div class="diagram-overlay-content"></div>'
  overlay.addEventListener("click", () => overlay.classList.remove("active"))
  document.body.appendChild(overlay)

  function attachZoom() {
    document.querySelectorAll(".mermaid").forEach(el => {
      if (el.dataset.zoom) return; el.dataset.zoom = "1"
      el.style.cursor = "zoom-in"; el.title = "Click to enlarge"
      el.addEventListener("click", (e) => {
        e.stopPropagation()
        const content = overlay.querySelector(".diagram-overlay-content")
        content.innerHTML = el.outerHTML
        if (window.mermaid) {
          const node = content.querySelector(".mermaid")
          node.removeAttribute("data-processed")
          window.mermaid.run({ nodes: [node] })
        }
        overlay.classList.add("active")
      })
    })
    document.querySelectorAll("article img:not(.twemoji):not(.md-logo)").forEach(img => {
      if (img.dataset.zoom) return; img.dataset.zoom = "1"
      img.style.cursor = "zoom-in"; img.title = "Click to enlarge"
      img.addEventListener("click", (e) => {
        e.stopPropagation()
        const content = overlay.querySelector(".diagram-overlay-content")
        content.textContent = ''
        const zoomImg = document.createElement('img')
        zoomImg.src = img.src; zoomImg.alt = img.alt
        zoomImg.style.cssText = 'max-width:95vw;max-height:95vh'
        content.appendChild(zoomImg)
        overlay.classList.add("active")
      })
    })
  }

  // Initial load
  attachZoom()
  // Material for MkDocs instant navigation
  if (typeof document$ !== "undefined" && document$.subscribe) {
    document$.subscribe(() => { attachZoom() })
  }
  // Fallback for non-instant navigation
  document.addEventListener("DOMContentLoaded", attachZoom)
}

// Run on script load (inline scripts execute before DOMContentLoaded)
if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", setupZoom)
} else {
  setupZoom()
}
