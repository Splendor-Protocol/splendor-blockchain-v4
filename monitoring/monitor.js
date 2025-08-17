#!/usr/bin/env node

const { exec } = require('child_process');
const fs = require('fs');
const path = require('path');
const axios = require('axios');
const nodemailer = require('nodemailer');

// Configuration
const CONFIG = {
    // Monitoring intervals (in milliseconds)
    CHECK_INTERVAL: 30000, // 30 seconds
    RPC_TIMEOUT: 10000, // 10 seconds
    
    // Notification settings
    NOTIFICATIONS: {
        EMAIL: {
            enabled: process.env.EMAIL_NOTIFICATIONS === 'true',
            smtp: {
                host: process.env.SMTP_HOST || 'smtp.gmail.com',
                port: process.env.SMTP_PORT || 587,
                secure: false,
                auth: {
                    user: process.env.SMTP_USER,
                    pass: process.env.SMTP_PASS
                }
            },
            from: process.env.EMAIL_FROM,
            to: process.env.EMAIL_TO
        },
        WEBHOOK: {
            enabled: process.env.WEBHOOK_NOTIFICATIONS === 'true',
            url: process.env.WEBHOOK_URL,
            headers: {
                'Content-Type': 'application/json'
            }
        },
        SLACK: {
            enabled: process.env.SLACK_NOTIFICATIONS === 'true',
            webhook: process.env.SLACK_WEBHOOK_URL
        }
    },
    
    // RPC endpoints to monitor
    RPC_ENDPOINTS: [
        {
            name: 'Local RPC',
            url: `http://${process.env.IP || 'localhost'}:80`,
            type: 'http'
        },
        {
            name: 'Local WebSocket',
            url: `ws://${process.env.IP || 'localhost'}:8545`,
            type: 'websocket'
        }
    ],
    
    // Log file paths
    LOG_FILE: path.join(__dirname, 'monitoring.log'),
    STATUS_FILE: path.join(__dirname, 'status.json')
};

class BlockchainMonitor {
    constructor() {
        this.status = {
            validators: {},
            rpcNodes: {},
            services: {},
            lastCheck: null,
            alerts: []
        };
        
        this.emailTransporter = null;
        this.initializeEmailTransporter();
        this.loadStatus();
    }

    initializeEmailTransporter() {
        if (CONFIG.NOTIFICATIONS.EMAIL.enabled) {
            this.emailTransporter = nodemailer.createTransporter(CONFIG.NOTIFICATIONS.EMAIL.smtp);
        }
    }

    log(message, level = 'INFO') {
        const timestamp = new Date().toISOString();
        const logMessage = `[${timestamp}] [${level}] ${message}`;
        
        console.log(logMessage);
        
        // Write to log file
        fs.appendFileSync(CONFIG.LOG_FILE, logMessage + '\n');
    }

    loadStatus() {
        try {
            if (fs.existsSync(CONFIG.STATUS_FILE)) {
                this.status = JSON.parse(fs.readFileSync(CONFIG.STATUS_FILE, 'utf8'));
            }
        } catch (error) {
            this.log(`Error loading status: ${error.message}`, 'ERROR');
        }
    }

    saveStatus() {
        try {
            fs.writeFileSync(CONFIG.STATUS_FILE, JSON.stringify(this.status, null, 2));
        } catch (error) {
            this.log(`Error saving status: ${error.message}`, 'ERROR');
        }
    }

    async checkTmuxSessions() {
        return new Promise((resolve) => {
            exec('tmux list-sessions -F "#{session_name}"', (error, stdout, stderr) => {
                if (error) {
                    this.log(`Error checking tmux sessions: ${error.message}`, 'ERROR');
                    resolve([]);
                    return;
                }
                
                const sessions = stdout.trim().split('\n').filter(s => s.startsWith('node'));
                resolve(sessions);
            });
        });
    }

    async checkNodeHealth(nodeName) {
        return new Promise((resolve) => {
            exec(`tmux capture-pane -t ${nodeName} -p | tail -10`, (error, stdout, stderr) => {
                if (error) {
                    resolve({ healthy: false, error: error.message });
                    return;
                }
                
                const output = stdout.toLowerCase();
                const isHealthy = !output.includes('error') && 
                                !output.includes('fatal') && 
                                !output.includes('panic') &&
                                !output.includes('connection refused');
                
                resolve({ 
                    healthy: isHealthy, 
                    lastOutput: stdout.trim(),
                    timestamp: new Date().toISOString()
                });
            });
        });
    }

    async checkRPCEndpoint(endpoint) {
        try {
            const startTime = Date.now();
            
            if (endpoint.type === 'http') {
                const response = await axios.post(endpoint.url, {
                    jsonrpc: '2.0',
                    method: 'eth_blockNumber',
                    params: [],
                    id: 1
                }, {
                    timeout: CONFIG.RPC_TIMEOUT,
                    headers: { 'Content-Type': 'application/json' }
                });
                
                const responseTime = Date.now() - startTime;
                
                return {
                    healthy: response.status === 200 && response.data.result,
                    responseTime,
                    blockNumber: response.data.result,
                    error: null
                };
            } else if (endpoint.type === 'websocket') {
                // For WebSocket, we'll do a simple connection test
                return new Promise((resolve) => {
                    const WebSocket = require('ws');
                    const ws = new WebSocket(endpoint.url);
                    
                    const timeout = setTimeout(() => {
                        ws.terminate();
                        resolve({
                            healthy: false,
                            responseTime: CONFIG.RPC_TIMEOUT,
                            error: 'Connection timeout'
                        });
                    }, CONFIG.RPC_TIMEOUT);
                    
                    ws.on('open', () => {
                        clearTimeout(timeout);
                        const responseTime = Date.now() - startTime;
                        ws.close();
                        resolve({
                            healthy: true,
                            responseTime,
                            error: null
                        });
                    });
                    
                    ws.on('error', (error) => {
                        clearTimeout(timeout);
                        const responseTime = Date.now() - startTime;
                        resolve({
                            healthy: false,
                            responseTime,
                            error: error.message
                        });
                    });
                });
            }
        } catch (error) {
            const responseTime = Date.now() - startTime;
            return {
                healthy: false,
                responseTime,
                error: error.message
            };
        }
    }

    async checkPM2Services() {
        return new Promise((resolve) => {
            exec('pm2 jlist', (error, stdout, stderr) => {
                if (error) {
                    this.log(`Error checking PM2 services: ${error.message}`, 'ERROR');
                    resolve({});
                    return;
                }
                
                try {
                    const services = JSON.parse(stdout);
                    const serviceStatus = {};
                    
                    services.forEach(service => {
                        serviceStatus[service.name] = {
                            status: service.pm2_env.status,
                            pid: service.pid,
                            uptime: service.pm2_env.pm_uptime,
                            restarts: service.pm2_env.restart_time,
                            memory: service.monit.memory,
                            cpu: service.monit.cpu
                        };
                    });
                    
                    resolve(serviceStatus);
                } catch (parseError) {
                    this.log(`Error parsing PM2 output: ${parseError.message}`, 'ERROR');
                    resolve({});
                }
            });
        });
    }

    async sendNotification(title, message, severity = 'warning') {
        const notification = {
            title,
            message,
            severity,
            timestamp: new Date().toISOString()
        };

        // Email notification
        if (CONFIG.NOTIFICATIONS.EMAIL.enabled && this.emailTransporter) {
            try {
                await this.emailTransporter.sendMail({
                    from: CONFIG.NOTIFICATIONS.EMAIL.from,
                    to: CONFIG.NOTIFICATIONS.EMAIL.to,
                    subject: `[Splendor Monitor] ${title}`,
                    html: `
                        <h2>${title}</h2>
                        <p><strong>Severity:</strong> ${severity.toUpperCase()}</p>
                        <p><strong>Time:</strong> ${notification.timestamp}</p>
                        <p><strong>Message:</strong></p>
                        <pre>${message}</pre>
                    `
                });
                this.log(`Email notification sent: ${title}`, 'INFO');
            } catch (error) {
                this.log(`Failed to send email notification: ${error.message}`, 'ERROR');
            }
        }

        // Webhook notification
        if (CONFIG.NOTIFICATIONS.WEBHOOK.enabled) {
            try {
                await axios.post(CONFIG.NOTIFICATIONS.WEBHOOK.url, notification, {
                    headers: CONFIG.NOTIFICATIONS.WEBHOOK.headers,
                    timeout: 5000
                });
                this.log(`Webhook notification sent: ${title}`, 'INFO');
            } catch (error) {
                this.log(`Failed to send webhook notification: ${error.message}`, 'ERROR');
            }
        }

        // Slack notification
        if (CONFIG.NOTIFICATIONS.SLACK.enabled) {
            try {
                const color = severity === 'critical' ? 'danger' : 
                             severity === 'warning' ? 'warning' : 'good';
                
                await axios.post(CONFIG.NOTIFICATIONS.SLACK.webhook, {
                    attachments: [{
                        color,
                        title,
                        text: message,
                        ts: Math.floor(Date.now() / 1000)
                    }]
                });
                this.log(`Slack notification sent: ${title}`, 'INFO');
            } catch (error) {
                this.log(`Failed to send Slack notification: ${error.message}`, 'ERROR');
            }
        }

        // Store alert
        this.status.alerts.unshift(notification);
        if (this.status.alerts.length > 100) {
            this.status.alerts = this.status.alerts.slice(0, 100);
        }
    }

    async performHealthCheck() {
        this.log('Starting health check...', 'INFO');
        
        const previousStatus = JSON.parse(JSON.stringify(this.status));
        
        // Check tmux sessions (validators and RPC nodes)
        const sessions = await this.checkTmuxSessions();
        
        for (const session of sessions) {
            const health = await this.checkNodeHealth(session);
            const nodeType = session.includes('node') && parseInt(session.replace('node', '')) <= 10 ? 'validator' : 'rpc';
            
            if (nodeType === 'validator') {
                this.status.validators[session] = health;
            } else {
                this.status.rpcNodes[session] = health;
            }
            
            // Check for status changes
            const previousHealth = nodeType === 'validator' ? 
                previousStatus.validators[session] : 
                previousStatus.rpcNodes[session];
            
            if (previousHealth && previousHealth.healthy && !health.healthy) {
                await this.sendNotification(
                    `${nodeType.toUpperCase()} Node Down`,
                    `${session} has gone offline.\nError: ${health.error || 'Unknown error'}\nLast output:\n${health.lastOutput}`,
                    'critical'
                );
            } else if (previousHealth && !previousHealth.healthy && health.healthy) {
                await this.sendNotification(
                    `${nodeType.toUpperCase()} Node Recovered`,
                    `${session} is back online.`,
                    'good'
                );
            }
        }

        // Check RPC endpoints
        for (const endpoint of CONFIG.RPC_ENDPOINTS) {
            const health = await this.checkRPCEndpoint(endpoint);
            this.status.rpcNodes[endpoint.name] = health;
            
            const previousHealth = previousStatus.rpcNodes[endpoint.name];
            
            if (previousHealth && previousHealth.healthy && !health.healthy) {
                await this.sendNotification(
                    'RPC Endpoint Down',
                    `${endpoint.name} (${endpoint.url}) is not responding.\nError: ${health.error}\nResponse time: ${health.responseTime}ms`,
                    'critical'
                );
            } else if (previousHealth && !previousHealth.healthy && health.healthy) {
                await this.sendNotification(
                    'RPC Endpoint Recovered',
                    `${endpoint.name} (${endpoint.url}) is responding again.\nResponse time: ${health.responseTime}ms`,
                    'good'
                );
            }
        }

        // Check PM2 services
        const services = await this.checkPM2Services();
        this.status.services = services;
        
        for (const [serviceName, serviceInfo] of Object.entries(services)) {
            const previousService = previousStatus.services[serviceName];
            
            if (previousService && previousService.status === 'online' && serviceInfo.status !== 'online') {
                await this.sendNotification(
                    'Service Down',
                    `PM2 service "${serviceName}" is ${serviceInfo.status}.\nPID: ${serviceInfo.pid}\nRestarts: ${serviceInfo.restarts}`,
                    'critical'
                );
            } else if (previousService && previousService.status !== 'online' && serviceInfo.status === 'online') {
                await this.sendNotification(
                    'Service Recovered',
                    `PM2 service "${serviceName}" is back online.\nPID: ${serviceInfo.pid}`,
                    'good'
                );
            }
        }

        this.status.lastCheck = new Date().toISOString();
        this.saveStatus();
        
        this.log('Health check completed', 'INFO');
    }

    generateStatusReport() {
        const report = {
            timestamp: new Date().toISOString(),
            summary: {
                totalValidators: Object.keys(this.status.validators).length,
                healthyValidators: Object.values(this.status.validators).filter(v => v.healthy).length,
                totalRPCNodes: Object.keys(this.status.rpcNodes).length,
                healthyRPCNodes: Object.values(this.status.rpcNodes).filter(r => r.healthy).length,
                totalServices: Object.keys(this.status.services).length,
                onlineServices: Object.values(this.status.services).filter(s => s.status === 'online').length
            },
            details: this.status
        };
        
        return report;
    }

    async start() {
        this.log('Starting Splendor Blockchain Monitor...', 'INFO');
        
        // Initial health check
        await this.performHealthCheck();
        
        // Set up periodic monitoring
        setInterval(async () => {
            try {
                await this.performHealthCheck();
            } catch (error) {
                this.log(`Error during health check: ${error.message}`, 'ERROR');
            }
        }, CONFIG.CHECK_INTERVAL);
        
        this.log(`Monitor started. Checking every ${CONFIG.CHECK_INTERVAL / 1000} seconds.`, 'INFO');
    }
}

// Handle graceful shutdown
process.on('SIGINT', () => {
    console.log('\nShutting down monitor...');
    process.exit(0);
});

process.on('SIGTERM', () => {
    console.log('\nShutting down monitor...');
    process.exit(0);
});

// Start the monitor
if (require.main === module) {
    const monitor = new BlockchainMonitor();
    monitor.start().catch(error => {
        console.error('Failed to start monitor:', error);
        process.exit(1);
    });
}

module.exports = BlockchainMonitor;
