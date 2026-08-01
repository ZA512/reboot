{{flutter_js}}
{{flutter_build_config}}

const rebootServiceWorker = (() => {
  if (!("serviceWorker" in navigator)) {
    return Promise.resolve(null);
  }

  const workerUrl = new URL("reboot_service_worker.js", document.baseURI);
  const scopeUrl = new URL("./", document.baseURI);

  return navigator.serviceWorker
    .register(workerUrl, {
      scope: scopeUrl.pathname,
      updateViaCache: "none",
    })
    .then((registration) => {
      const announceUpdate = (worker) => {
        worker.addEventListener("statechange", () => {
          if (
            worker.state === "installed" &&
            navigator.serviceWorker.controller
          ) {
            window.dispatchEvent(new Event("reboot-pwa-update-ready"));
          }
        });
      };

      if (registration.installing) {
        announceUpdate(registration.installing);
      }
      registration.addEventListener("updatefound", () => {
        if (registration.installing) {
          announceUpdate(registration.installing);
        }
      });

      return registration;
    })
    .catch((error) => {
      console.warn("REBOOT offline shell unavailable.", error);
      return null;
    });
})();

window.rebootPwa = Object.freeze({
  serviceWorker: rebootServiceWorker,
  activateWaitingWorker: async () => {
    const registration = await rebootServiceWorker;
    registration?.waiting?.postMessage({ type: "REBOOT_ACTIVATE_UPDATE" });
  },
});

_flutter.loader.load();
