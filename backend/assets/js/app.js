// We import the CSS which is extracted to its own file by esbuild.
// Remove this line if you add a your own CSS build pipeline (e.g postcss).
// import "../css/app.css"

// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

// Define hooks for timezone handling
let Hooks = {}

// Timezone hook to format timestamps
Hooks.LocalTime = {
  mounted() {
    this.updated();
  },
  updated() {
    const utcTime = this.el.getAttribute('data-utc');
    if (utcTime) {
      const localTime = new Date(utcTime);
      const formatted = localTime.toLocaleString('en-US', {
        month: 'numeric',
        day: 'numeric',
        hour: 'numeric',
        minute: '2-digit',
        hour12: true
      });
      this.el.textContent = formatted;
    }
  }
};

// Hook to detect and send client timezone
Hooks.TimezoneDetector = {
  mounted() {
    const timezone = Intl.DateTimeFormat().resolvedOptions().timeZone;
    this.pushEvent('timezone-detected', {timezone: timezone});
  }
};

// Hook to handle date input changes reliably
Hooks.DateSelector = {
  mounted() {
    this.el.addEventListener('change', (e) => {
      const selectedDate = e.target.value;
      if (selectedDate) {
        this.pushEvent('select_date', {date: selectedDate});
      }
    });
  }
};

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: Hooks
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket