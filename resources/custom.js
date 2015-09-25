// single-window mode, sets all UI links to open in the same window
// doesn't affect links in notebook output
if (IPython) {
  IPython._target = '_self';

  require(["base/js/events"], function (events) {
      events.on("notebook_loaded.Notebook", function () {
          // disable warn-on-unsaved changes
          // these are ephemeral notebooks, nobody should have any work to lose
          window.onbeforeunload = null;
      });
  });
}
