Hooks = {};

Hooks.GameSize = {
  mounted() {
    this.width = 0;
    this.height = 0;

    this.resize = (e) => {
      const newWidth = this.el.clientWidth;
      const newHeight = this.el.clientHeight;

      if (
        newWidth > 0 &&
        newHeight > 0 &&
        (newWidth !== this.width || newHeight !== this.height)
      ) {
        this.width = newWidth;
        this.height = newHeight;

        this.pushEvent("resize", { width: newWidth, height: newHeight });
      }
    };

    this.resizeObserver = new ResizeObserver(this.resize);
    this.resizeObserver.observe(this.el);
  },
  unmounted() {
    this.resizeObserver.unobserve(this.el);
  },
};

Hooks.ScrollToBottomOnInput = {
  mounted() {
    const scrollToBottom = (_e) => {
      this.el.scrollTop = this.el.scrollHeight - this.el.clientHeight;
    };
    const config = { childList: true };

    this.resizeObserver = new MutationObserver(scrollToBottom);
    this.resizeObserver.observe(this.el, config);
    scrollToBottom();
  },
  unmounted() {
    this.resizeObserver.unobserve(this.el);
  },
};

export default Hooks;
