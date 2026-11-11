window.desktopApp = (function () {
  var filePath = null;
  var desktop = window.strokeDesktop;

  function textToHTML(text) {
    return '<p>' + text
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/\r?\n/g, '</p><p>');
  }

  function htmlToText(html) {
    var temporary = document.createElement('div');
    temporary.innerHTML = html;
    temporary.querySelectorAll('.strike').forEach(function (node) { node.remove(); });
    return temporary.innerText
      .replace(/\uFEFF/g, '')
      .replace(/\u200B/g, '')
      .replace(/\u00A0/g, ' ');
  }

  async function openFile() {
    try {
      var documentData = await desktop.openDocument();
      if (!documentData) return;
      filePath = documentData.filePath;
      typewriter.setContents(textToHTML(documentData.text));
    } catch (error) {
      window.alert('The document could not be opened.\n' + error.message);
    }
  }

  async function saveFile(saveAs) {
    try {
      var destination = await desktop.saveDocument(saveAs ? null : filePath, htmlToText(typewriter.getHTMLof('output')));
      if (destination) filePath = destination;
    } catch (error) {
      window.alert('The document could not be saved.\n' + error.message);
    }
  }

  function init() {
    desktop.onCommand(function (command) {
      if (command === 'open') openFile();
      if (command === 'save') saveFile(false);
      if (command === 'save-as') saveFile(true);
    });

    document.addEventListener('keydown', function (event) {
      if (!(event.metaKey || event.ctrlKey)) return;
      var key = event.key.toLowerCase();
      if (key === 'o') {
        event.preventDefault();
        openFile();
      } else if (key === 's') {
        event.preventDefault();
        saveFile(event.shiftKey);
      }
    }, true);
  }

  return { init: init };
}());
