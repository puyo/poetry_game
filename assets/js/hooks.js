Hooks = {}

Hooks.GameSize = {
  mounted() {
    this.width = 0
    this.height = 0

    this.resize = (e) => {
      const newWidth = this.el.clientWidth
      const newHeight = this.el.clientHeight

      if ((newWidth > 0 && newHeight > 0) &&
        (newWidth !== this.width || newHeight !== this.height)) {

        this.width = newWidth
        this.height = newHeight

        this.pushEvent("resize", {width: newWidth, height: newHeight})
      }
    }

    this.resizeObserver = new ResizeObserver((entries) => {
      this.resize()
    })

    this.resizeObserver.observe(this.el)
  },
  unmounted() {
    this.resizeObserver.unobserve(this.el)
  }
}

export default Hooks

