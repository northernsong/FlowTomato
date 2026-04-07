import { app, shell, BrowserWindow, ipcMain, Notification, Tray, Menu, nativeImage } from 'electron'
import { join } from 'path'
import { is } from '@electron-toolkit/utils'
import Store from 'electron-store'
import { FeishuService } from './feishu'
import type { FeishuConfig, FeishuSyncPayload } from './feishu/types'

// ─── Persisted Settings ──────────────────────────────────────────────────────

interface AppSettings {
  feishu: FeishuConfig
  workDuration: number      // minutes
  shortBreakDuration: number
  longBreakDuration: number
  longBreakInterval: number // pomodoros before a long break
  autoStartBreaks: boolean
  autoStartWork: boolean
  notificationsEnabled: boolean
  alwaysOnTop: boolean
}

const DEFAULT_SETTINGS: AppSettings = {
  feishu: { enabled: false },
  workDuration: 25,
  shortBreakDuration: 5,
  longBreakDuration: 15,
  longBreakInterval: 4,
  autoStartBreaks: false,
  autoStartWork: false,
  notificationsEnabled: true,
  alwaysOnTop: false
}

const store = new Store<AppSettings>({ defaults: DEFAULT_SETTINGS })

// ─── Feishu Service ──────────────────────────────────────────────────────────

let feishuService = new FeishuService(store.get('feishu') as FeishuConfig)

// ─── Window & Tray ───────────────────────────────────────────────────────────

let mainWindow: BrowserWindow | null = null
let tray: Tray | null = null

function createWindow(): void {
  mainWindow = new BrowserWindow({
    width: 420,
    height: 600,
    minWidth: 360,
    minHeight: 500,
    show: false,
    frame: true,
    titleBarStyle: process.platform === 'darwin' ? 'hiddenInset' : 'default',
    autoHideMenuBar: true,
    alwaysOnTop: store.get('alwaysOnTop') as boolean,
    webPreferences: {
      preload: join(__dirname, '../preload/index.js'),
      sandbox: false,
      contextIsolation: true,
      nodeIntegration: false
    }
  })

  mainWindow.on('ready-to-show', () => {
    mainWindow!.show()
  })

  mainWindow.webContents.setWindowOpenHandler((details) => {
    shell.openExternal(details.url)
    return { action: 'deny' }
  })

  // Load the renderer
  if (is.dev && process.env['ELECTRON_RENDERER_URL']) {
    mainWindow.loadURL(process.env['ELECTRON_RENDERER_URL'])
  } else {
    mainWindow.loadFile(join(__dirname, '../renderer/index.html'))
  }
}

function createTray(): void {
  // Use a simple 16x16 blank icon placeholder; replace build/icon.png for production
  const icon = nativeImage.createEmpty()
  tray = new Tray(icon)

  const contextMenu = Menu.buildFromTemplate([
    { label: '显示 FlowTomato', click: () => mainWindow?.show() },
    { type: 'separator' },
    { label: '退出', click: () => app.quit() }
  ])

  tray.setToolTip('FlowTomato 番茄钟')
  tray.setContextMenu(contextMenu)
  tray.on('click', () => {
    if (mainWindow?.isVisible()) {
      mainWindow.focus()
    } else {
      mainWindow?.show()
    }
  })
}

// ─── App Lifecycle ───────────────────────────────────────────────────────────

app.whenReady().then(() => {
  createWindow()
  createTray()

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      createWindow()
    } else {
      mainWindow?.show()
    }
  })
})

app.on('window-all-closed', () => {
  // On macOS keep app running in tray; on other platforms quit
  if (process.platform !== 'darwin') {
    app.quit()
  }
})

// ─── IPC Handlers ────────────────────────────────────────────────────────────

/** Get all app settings */
ipcMain.handle('settings:get', () => {
  return store.store
})

/** Update settings (partial) */
ipcMain.handle('settings:set', (_event, partial: Partial<AppSettings>) => {
  for (const [key, value] of Object.entries(partial) as [keyof AppSettings, unknown][]) {
    store.set(key, value)
  }

  // Apply immediate effects
  if (partial.feishu) {
    feishuService.updateConfig(partial.feishu as FeishuConfig)
  }
  if (partial.alwaysOnTop !== undefined) {
    mainWindow?.setAlwaysOnTop(partial.alwaysOnTop as boolean)
  }

  return store.store
})

/** Send system notification */
ipcMain.handle('notification:send', (_event, title: string, body: string) => {
  const notificationsEnabled = store.get('notificationsEnabled') as boolean
  if (notificationsEnabled && Notification.isSupported()) {
    new Notification({ title, body }).show()
  }
})

/** Sync a completed session to Feishu */
ipcMain.handle('feishu:sync', async (_event, payload: FeishuSyncPayload) => {
  return feishuService.syncSession(payload)
})

/** Test Feishu connection */
ipcMain.handle('feishu:test', async () => {
  const testPayload: FeishuSyncPayload = {
    phase: 'work',
    completedPomodoros: 1,
    durationSeconds: 1500,
    timestamp: Date.now()
  }
  return feishuService.syncSession(testPayload)
})
