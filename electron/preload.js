const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('strokeDesktop', {
  openDocument: () => ipcRenderer.invoke('stroke:open'),
  saveDocument: (filePath, text) => ipcRenderer.invoke('stroke:save', filePath, text),
  onCommand(callback) {
    const listener = (_event, command) => callback(command);
    ipcRenderer.on('stroke:command', listener);
    return () => ipcRenderer.removeListener('stroke:command', listener);
  }
});
