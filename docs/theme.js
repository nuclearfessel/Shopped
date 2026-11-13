(function () {
  var STORAGE_KEY = "shopped-theme";
  var root = document.documentElement;
  var media = window.matchMedia("(prefers-color-scheme: dark)");

  function stored() {
    try {
      return localStorage.getItem(STORAGE_KEY) || "system";
    } catch (error) {
      return "system";
    }
  }

  function resolved(preference) {
    if (preference === "light" || preference === "dark") return preference;
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

  function apply(preference) {
    var theme = resolved(preference);
    root.setAttribute("data-theme", theme);
    root.setAttribute("data-theme-preference", preference);
    syncThemedSources(theme);
    document.querySelectorAll("[data-theme-toggle]").forEach(function (button) {
      var next =
        preference === "system" ? "light" : preference === "light" ? "dark" : "system";
      button.setAttribute("aria-pressed", preference === "system" ? "mixed" : "true");
      button.setAttribute(
        "aria-label",
        preference === "system"
          ? "Theme: system. Switch to light."
          : preference === "light"
            ? "Theme: light. Switch to dark."
            : "Theme: dark. Switch to system."
      );
      button.dataset.nextTheme = next;
      var label = button.querySelector("[data-theme-label]");
      if (label) {
        label.textContent =
          preference === "system" ? "System" : preference === "light" ? "Light" : "Dark";
      }
    });
  }

  function save(preference) {
    try {
      localStorage.setItem(STORAGE_KEY, preference);
    } catch (error) {
      /* ignore quota / private mode */
    }
    apply(preference);
  }

  apply(stored());
  document.addEventListener("DOMContentLoaded", function () {
    apply(stored());
  });

  document.addEventListener("click", function (event) {
    var button = event.target.closest("[data-theme-toggle]");
    if (!button) return;
    save(button.dataset.nextTheme || "system");
  });

  if (media.addEventListener) {
    media.addEventListener("change", function () {
      if (stored() === "system") apply("system");
    });
  } else if (media.addListener) {
    media.addListener(function () {
      if (stored() === "system") apply("system");
    });
  }

  window.ShoppedTheme = { apply: apply, save: save, stored: stored };
})();
