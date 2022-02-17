const Hooks = {};

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
    const scrollToBottom = () => {
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

Hooks.UserForm = {
  mounted() {
    this.el.addEventListener("submit", (e) => {
      e.preventDefault();
      const data = new FormData(e.target);
      fetch(`/api/session`, { method: "post", body: data }).then(() => {
        const obj = Object.fromEntries(data.entries());
        this.pushEventTo(".user-live", "submit", {
          user: {
            name: data.get("user[name]"),
            color: data.get("user[color]"),
          },
        });
      });
    });
  },
};

Hooks.CopyToClipboard = {
  mounted() {
    const oldText = this.el.textContent;
    const onClick = (e) => {
      e.preventDefault();
      const input = document.querySelector(this.el.dataset.copy);
      input.select();
      input.setSelectionRange(0, 99999);
      document.execCommand("copy");
      input.setSelectionRange(0, 0);
      input.blur();
      this.el.innerText = "Copied!";
      const timer = setTimeout(() => {
        this.el.innerText = oldText;
      }, 1000);
    };

    this.el.addEventListener("click", onClick);
  },
};

export default Hooks;
