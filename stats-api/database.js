const sqlite3 = require('sqlite3').verbose();
const path = require('path');

const dbPath = path.join(__dirname, 'data', 'downloads.db');

// Ensure data directory exists
const fs = require('fs');
const dataDir = path.join(__dirname, 'data');
if (!fs.existsSync(dataDir)) {
  fs.mkdirSync(dataDir, { recursive: true });
}

const db = new sqlite3.Database(dbPath);

// Initialize database
function initDatabase() {
  db.serialize(() => {
    db.run(`CREATE TABLE IF NOT EXISTS downloads (
      id TEXT PRIMARY KEY,
      app_id TEXT NOT NULL,
      version_code TEXT NOT NULL,
      version_name TEXT,
      file_name TEXT NOT NULL,
      download_time DATETIME NOT NULL,
      ip_address TEXT,
      user_agent TEXT
    )`);

    db.run(`CREATE INDEX IF NOT EXISTS idx_app_version
            ON downloads(app_id, version_code)`);

    db.run(`CREATE INDEX IF NOT EXISTS idx_download_time
            ON downloads(download_time)`);
  });
}

// Insert download record
function insertDownload(download) {
  return new Promise((resolve, reject) => {
    const id = `dl_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    const download_time = new Date().toISOString();

    db.run(
      `INSERT INTO downloads (id, app_id, version_code, version_name, file_name, download_time, ip_address, user_agent)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [id, download.app_id, download.version_code, download.version_name,
       download.file_name, download_time, download.ip_address, download.user_agent],
      function(err) {
        if (err) reject(err);
        else resolve({ id, download_time });
      }
    );
  });
}

// Get download statistics
function getDownloadStats(appId) {
  return new Promise((resolve, reject) => {
    db.get(
      'SELECT COUNT(*) as total FROM downloads WHERE app_id = ?',
      [appId],
      (err, row) => {
        if (err) reject(err);
        else resolve({ total_downloads: row.total });
      }
    );
  });
}

module.exports = { initDatabase, insertDownload, getDownloadStats };
