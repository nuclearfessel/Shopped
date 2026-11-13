(function () {
  var STORAGE_KEY = "shopped-theme";
  var root = document.documentElement;
  var media = window.matchMedia("(prefers-color-scheme: dark)");

  function stored() {
    try {
      var value = localStorage.getItem(STORAGE_KEY);
      if (value === "light" || value === "dark") return value;
      // Migrate the old "system" preference to a concrete theme.
      if (value === "system") {
        return media.matches ? "dark" : "light";
      }
    } catch (error) {
      /* ignore */
    }
    return media.matches ? "dark" : "light";
  }

  function syncThemedSources(theme) {
    document.querySelectorAll("[data-theme-src-light][data-theme-src-dark]").forEach(
      function (image) {
        var next =
          theme === "dark"
            ? image.getAttribute("data-theme-src-dark")
            : image.getAttribute("data-theme-src-light");
        if (next && image.getAttribute("src") !== next) {
          image.setAttribute("src", next);
        }
      }
    );
  }

  function apply(theme) {
    if (theme !== "light" && theme !== "dark") {
      theme = media.matches ? "dark" : "light";
    }
    root.setAttribute("data-theme", theme);
    syncThemedSources(theme);
    document.querySelectorAll("[data-theme-toggle]").forEach(function (button) {
      var next = theme === "light" ? "dark" : "light";
      button.setAttribute("aria-pressed", "true");
      button.setAttribute(
        "aria-label",
        theme === "light" ? "Theme: light. Switch to dark." : "Theme: dark. Switch to light."
      );
      button.dataset.nextTheme = next;
      var label = button.querySelector("[data-theme-label]");
      if (label) {
        label.textContent = theme === "light" ? "Light" : "Dark";
      }
    });
  }

  function save(theme) {
    try {
      localStorage.setItem(STORAGE_KEY, theme);
    } catch (error) {
      /* ignore quota / private mode */
    }
    apply(theme);
  }

  apply(stored());
  document.addEventListener("DOMContentLoaded", function () {
    apply(stored());
  });

  document.addEventListener("click", function (event) {
    var button = event.target.closest("[data-theme-toggle]");
    if (!button) return;
    save(button.dataset.nextTheme || "dark");
  });

  window.ShoppedTheme = { apply: apply, save: save, stored: stored };
})();
