window.desktopApp = (function () {
  var filePath = null;
  var desktop = window.strokeDesktop || null;

  function textToHTML(text) {
    if (!text) return '<p>&#xfeff;</p>';
    return '<p>' + String(text)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/\r?\n/g, '</p><p>')
      .replace(/<p><\/p>/g, '<p>&nbsp;</p>');
  }

  function htmlToText(html) {
    var temporary = document.createElement('div');
    temporary.innerHTML = html;
    temporary.querySelectorAll('.strike').forEach(function (node) {
      node.remove();
    });
    return temporary.innerText
      .replace(/\uFEFF/g, '')
      .replace(/\u200B/g, '')
      .replace(/\u00A0/g, ' ')
      .replace(/\r/g, '');
  }

  async function openFile() {
    if (!desktop) return;
    try {
      var documentData = await desktop.openDocument();
      if (!documentData) return;
      filePath = documentData.filePath;
      typewriter.setContents(textToHTML(documentData.text));
    } catch (error) {
      window.alert('The document could not be opened.\n' + (error && error.message ? error.message : error));
    }
  }

  async function saveFile(saveAs) {
    if (!desktop) return;
    try {
      var destination = await desktop.saveDocument(saveAs ? null : filePath, htmlToText(typewriter.getHTMLof('output')));
      if (destination) filePath = destination;
    } catch (error) {
      window.alert('The document could not be saved.\n' + (error && error.message ? error.message : error));
    }
  }

  function init() {
    if (!desktop) return;

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

  return { init: init, openFile: openFile, saveFile: saveFile };
}());
