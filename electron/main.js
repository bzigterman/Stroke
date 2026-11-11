const { app, BrowserWindow, Menu, dialog, ipcMain } = require('electron');
const fs = require('node:fs/promises');
const path = require('node:path');

let mainWindow;

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 712,
    height: 820,
    minWidth: 300,
    minHeight: 300,
    title: 'Untitled',
    show: false,
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: true
    }
  });

  mainWindow.once('ready-to-show', () => mainWindow.show());
  mainWindow.on('closed', () => {
    mainWindow = null;
  });
  mainWindow.loadFile(path.join(app.getAppPath(), 'app', 'index.html'));
}

function sendCommand(command) {
  if (mainWindow && !mainWindow.isDestroyed()) {
    mainWindow.webContents.send('stroke:command', command);
  }
}

function buildMenu() {
  const template = [
    ...(process.platform === 'darwin' ? [{
      label: app.name,
      submenu: [
        { role: 'about' },
        { type: 'separator' },
        { role: 'services' },
        { type: 'separator' },
        { role: 'hide' },
        { role: 'hideOthers' },
        { role: 'unhide' },
        { type: 'separator' },
        { role: 'quit' }
      ]
    }] : []),
    {
      label: 'File',
      submenu: [
        { label: 'New Window', accelerator: 'CommandOrControl+N', click: createWindow },
        { label: 'Open…', accelerator: 'CommandOrControl+O', click: () => sendCommand('open') },
        { type: 'separator' },
        { label: 'Save', accelerator: 'CommandOrControl+S', click: () => sendCommand('save') },
        { label: 'Save As…', accelerator: 'CommandOrControl+Shift+S', click: () => sendCommand('save-as') },
        { type: 'separator' },
        ...(process.platform === 'darwin' ? [{ role: 'close' }] : [{ role: 'quit' }])
      ]
    },
    { label: 'Edit', submenu: [{ role: 'undo' }, { role: 'redo' }, { type: 'separator' }, { role: 'cut' }, { role: 'copy' }, { role: 'paste' }, { role: 'selectAll' }] },
    { label: 'Window', submenu: [{ role: 'minimize' }, { role: 'zoom' }, ...(process.platform === 'darwin' ? [{ role: 'front' }] : [])] }
  ];
  Menu.setApplicationMenu(Menu.buildFromTemplate(template));
}

ipcMain.handle('stroke:open', async () => {
  const result = await dialog.showOpenDialog(mainWindow, {
    properties: ['openFile'],
    filters: [{ name: 'Text documents', extensions: ['txt'] }, { name: 'All files', extensions: ['*'] }]
  });
  if (result.canceled || !result.filePaths[0]) return null;

  const filePath = result.filePaths[0];
  const text = await fs.readFile(filePath, 'utf8');
  mainWindow.setTitle(path.basename(filePath));
  return { filePath, text };
});

ipcMain.handle('stroke:save', async (_event, filePath, text) => {
  let destination = filePath;
  if (!destination) {
    const result = await dialog.showSaveDialog(mainWindow, {
      defaultPath: 'Untitled.txt',
      filters: [{ name: 'Text documents', extensions: ['txt'] }]
n    });
    if (result.canceled || !result.filePath) return null;
    destination = result.filePath;
  }

  await fs.writeFile(destination, text, 'utf8');
  mainWindow.setTitle(path.basename(destination));
  return destination;
});

app.whenReady().then(() => {
  buildMenu();
  createWindow();
  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});
