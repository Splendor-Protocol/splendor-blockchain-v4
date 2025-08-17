#!/usr/bin/env node

const express = require('express');
const path = require('path');
const fs = require('fs');
const BlockchainMonitor = require('./monitor');

const app = express();
const PORT = process.env.DASHBOARD_PORT || 3001;

// Middleware
app.use(express.static(path.join(__dirname, 'public')));
app.use(express.json());

// Initialize monitor instance
const monitor = new BlockchainMonitor();

// API Routes
app.get('/api/status', (req, res) => {
    try {
        const report = monitor.generateStatusReport();
        res.json(report);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.get('/api/alerts', (req, res) => {
    try {
        const alerts = monitor.status.alerts || [];
        const limit = parseInt(req.query.limit) || 50;
        res.json(alerts.slice(0, limit));
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.get('/api/logs', (req, res) => {
    try {
        const logFile = path.join(__dirname, 'monitoring.log');
        if (fs.existsSync(logFile)) {
            const logs = fs.readFileSync(logFile, 'utf8')
                .split('\n')
                .filter(line => line.trim())
                .slice(-100) // Last 100 lines
                .reverse();
            res.json(logs);
        } else {
            res.json([]);
        }
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Serve dashboard HTML
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Start server
app.listen(PORT, () => {
    console.log(`Monitoring Dashboard running on http://localhost:${PORT}`);
});

// Start monitoring in background
monitor.start().catch(error => {
    console.error('Failed to start monitor:', error);
});
