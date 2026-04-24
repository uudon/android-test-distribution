const express = require('express');
const db = require('./database');

const app = express();
const PORT = 3000;

// Middleware
app.use(express.json());
app.use(require('cors')());

// Trust proxy to get real IP
app.set('trust proxy', true);

// Initialize database
db.initDatabase();

// Log download event
app.post('/api/downloads', async (req, res) => {
  try {
    const download = {
      app_id: req.body.app_id,
      version_code: req.body.version_code,
      version_name: req.body.version_name,
      file_name: req.body.file_name,
      ip_address: req.ip,
      user_agent: req.get('User-Agent')
    };

    await db.insertDownload(download);
    res.json({ success: true });
  } catch (error) {
    console.error('Download record failed:', error);
    res.status(500).json({ success: false, error: 'Record failed' });
  }
});

// Get download statistics
app.get('/api/stats/:appId', async (req, res) => {
  try {
    const stats = await db.getDownloadStats(req.params.appId);
    res.json({ success: true, data: stats });
  } catch (error) {
    console.error('Get stats failed:', error);
    res.status(500).json({ success: false, error: 'Get stats failed' });
  }
});

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

app.listen(PORT, () => {
  console.log(`Statistics service running on port ${PORT}`);
});
