(function () {
  function readJson(id) {
    const node = document.getElementById(id);
    if (!node) return null;
    try {
      return JSON.parse(node.textContent || "null");
    } catch (_error) {
      return null;
    }
  }

  const data = readJson("mbor-data") || {};
  const actions = readJson("mbor-actions") || [];
  const components = readJson("mbor-components") || [];
  const forms = readJson("mbor-forms") || [];
  const islands = document.querySelectorAll("[data-mbor-island]");

  islands.forEach((node) => {
    const mode = node.getAttribute("data-mbor-hydration") || "manual";
    node.setAttribute("data-mbor-hydrated", "pending");
    if (mode === "client:visible") {
      const observer = new IntersectionObserver((entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            node.setAttribute("data-mbor-hydrated", "true");
            observer.disconnect();
          }
        });
      });
      observer.observe(node);
      return;
    }
    if (mode === "client:idle" && "requestIdleCallback" in window) {
      window.requestIdleCallback(() => {
        node.setAttribute("data-mbor-hydrated", "true");
      });
      return;
    }
    node.setAttribute("data-mbor-hydrated", "true");
  });

  window.mbtOnRails = {
    data,
    actions,
    components,
    forms,
    async callAction(name, payload) {
      const action = actions.find((entry) => entry.name === name);
      if (!action) {
        throw new Error("Unknown server action: " + name);
      }
      const response = await fetch(action.route, {
        method: "POST",
        headers: {
          "content-type": "application/json",
        },
        body: JSON.stringify(payload || {}),
      });
      return response.json();
    },
  };

  document.dispatchEvent(
    new CustomEvent("mbor:hydrate", {
      detail: {
        data,
        actions,
        components,
        forms,
      },
    }),
  );
})();
