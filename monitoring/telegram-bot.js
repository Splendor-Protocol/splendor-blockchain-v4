#!/usr/bin/env node

const TelegramBot = require('node-telegram-bot-api');
const BlockchainMonitor = require('./monitor');

class TelegramMonitorBot {
    constructor() {
        this.botToken = process.env.TELEGRAM_BOT_TOKEN;
        this.chatId = process.env.TELEGRAM_CHAT_ID;
        
        if (!this.botToken) {
            console.error('TELEGRAM_BOT_TOKEN is required in .env file');
            process.exit(1);
        }
        
        if (!this.chatId) {
            console.error('TELEGRAM_CHAT_ID is required in .env file');
            process.exit(1);
        }
        
        this.bot = new TelegramBot(this.botToken, { polling: true });
        this.monitor = new BlockchainMonitor();
        this.setupCommands();
        this.setupMonitoring();
    }

    setupCommands() {
        // Start command
        this.bot.onText(/\/start/, (msg) => {
            const chatId = msg.chat.id;
            this.bot.sendMessage(chatId, `
🔗 *Splendor Blockchain Monitor Bot*

Welcome! I'll help you monitor your blockchain infrastructure.

*Available Commands:*
/status - Get current system status
/alerts - View recent alerts
/nodes - List all nodes
/services - Check PM2 services
/help - Show this help message

*Monitoring Features:*
✅ Validator nodes monitoring
✅ RPC endpoint health checks
✅ PM2 service monitoring
✅ Real-time alerts

Your Chat ID: \`${chatId}\`
`, { parse_mode: 'Markdown' });
        });

        // Status command
        this.bot.onText(/\/status/, async (msg) => {
            const chatId = msg.chat.id;
            try {
                const report = this.monitor.generateStatusReport();
                const { summary } = report;
                
                let statusMessage = `📊 *System Status Report*\n\n`;
                statusMessage += `🔸 *Validators:* ${summary.healthyValidators}/${summary.totalValidators} healthy\n`;
                statusMessage += `🔸 *RPC Nodes:* ${summary.healthyRPCNodes}/${summary.totalRPCNodes} healthy\n`;
                statusMessage += `🔸 *Services:* ${summary.onlineServices}/${summary.totalServices} online\n\n`;
                
                // Overall health indicator
                const allHealthy = summary.healthyValidators === summary.totalValidators &&
                                 summary.healthyRPCNodes === summary.totalRPCNodes &&
                                 summary.onlineServices === summary.totalServices;
                
                statusMessage += allHealthy ? '✅ *All systems operational*' : '⚠️ *Issues detected*';
                statusMessage += `\n\n_Last updated: ${new Date(report.timestamp).toLocaleString()}_`;
                
                this.bot.sendMessage(chatId, statusMessage, { parse_mode: 'Markdown' });
            } catch (error) {
                this.bot.sendMessage(chatId, `❌ Error getting status: ${error.message}`);
            }
        });

        // Alerts command
        this.bot.onText(/\/alerts/, async (msg) => {
            const chatId = msg.chat.id;
            try {
                const alerts = this.monitor.status.alerts || [];
                
                if (alerts.length === 0) {
                    this.bot.sendMessage(chatId, '✅ No recent alerts');
                    return;
                }
                
                let alertMessage = `🚨 *Recent Alerts (Last 5)*\n\n`;
                
                alerts.slice(0, 5).forEach((alert, index) => {
                    const icon = alert.severity === 'critical' ? '🔴' : 
                               alert.severity === 'warning' ? '🟡' : '🟢';
                    
                    alertMessage += `${icon} *${alert.title}*\n`;
                    alertMessage += `${alert.message.substring(0, 100)}${alert.message.length > 100 ? '...' : ''}\n`;
                    alertMessage += `_${new Date(alert.timestamp).toLocaleString()}_\n\n`;
                });
                
                this.bot.sendMessage(chatId, alertMessage, { parse_mode: 'Markdown' });
            } catch (error) {
                this.bot.sendMessage(chatId, `❌ Error getting alerts: ${error.message}`);
            }
        });

        // Nodes command
        this.bot.onText(/\/nodes/, async (msg) => {
            const chatId = msg.chat.id;
            try {
                const report = this.monitor.generateStatusReport();
                const { validators, rpcNodes } = report.details;
                
                let nodesMessage = `⚡ *Validator Nodes*\n\n`;
                
                if (Object.keys(validators).length === 0) {
                    nodesMessage += 'No validators found\n\n';
                } else {
                    Object.entries(validators).forEach(([name, status]) => {
                        const icon = status.healthy ? '✅' : '❌';
                        nodesMessage += `${icon} ${name}: ${status.healthy ? 'Online' : 'Offline'}\n`;
                    });
                    nodesMessage += '\n';
                }
                
                nodesMessage += `🌐 *RPC Nodes*\n\n`;
                
                if (Object.keys(rpcNodes).length === 0) {
                    nodesMessage += 'No RPC nodes found';
                } else {
                    Object.entries(rpcNodes).forEach(([name, status]) => {
                        const icon = status.healthy ? '✅' : '❌';
                        const responseTime = status.responseTime ? ` (${status.responseTime}ms)` : '';
                        nodesMessage += `${icon} ${name}: ${status.healthy ? 'Online' : 'Offline'}${responseTime}\n`;
                    });
                }
                
                this.bot.sendMessage(chatId, nodesMessage, { parse_mode: 'Markdown' });
            } catch (error) {
                this.bot.sendMessage(chatId, `❌ Error getting nodes: ${error.message}`);
            }
        });

        // Services command
        this.bot.onText(/\/services/, async (msg) => {
            const chatId = msg.chat.id;
            try {
                const report = this.monitor.generateStatusReport();
                const { services } = report.details;
                
                let servicesMessage = `🔧 *PM2 Services*\n\n`;
                
                if (Object.keys(services).length === 0) {
                    servicesMessage += 'No PM2 services found';
                } else {
                    Object.entries(services).forEach(([name, service]) => {
                        const icon = service.status === 'online' ? '✅' : '❌';
                        const memory = service.memory ? ` (${Math.round(service.memory / 1024 / 1024)}MB)` : '';
                        servicesMessage += `${icon} ${name}: ${service.status}${memory}\n`;
                        if (service.restarts > 0) {
                            servicesMessage += `   ↻ Restarts: ${service.restarts}\n`;
                        }
                    });
                }
                
                this.bot.sendMessage(chatId, servicesMessage, { parse_mode: 'Markdown' });
            } catch (error) {
                this.bot.sendMessage(chatId, `❌ Error getting services: ${error.message}`);
            }
        });

        // Help command
        this.bot.onText(/\/help/, (msg) => {
            const chatId = msg.chat.id;
            this.bot.sendMessage(chatId, `
🔗 *Splendor Blockchain Monitor Help*

*Commands:*
/status - Overall system health
/alerts - Recent alerts and issues
/nodes - Validator and RPC node status
/services - PM2 service status
/help - This help message

*Alert Types:*
🔴 Critical - Node offline, service crashed
🟡 Warning - High response times, restarts
🟢 Good - Recovery notifications

*Monitoring Frequency:*
System checks every 30 seconds

*Dashboard:*
Access web dashboard at: http://your-server:3001

*Support:*
Check logs with: \`pm2 logs splendor-monitor\`
`, { parse_mode: 'Markdown' });
        });

        // Handle unknown commands
        this.bot.on('message', (msg) => {
            if (msg.text && msg.text.startsWith('/') && 
                !msg.text.match(/\/(start|status|alerts|nodes|services|help)/)) {
                this.bot.sendMessage(msg.chat.id, 
                    'Unknown command. Type /help for available commands.');
            }
        });
    }

    setupMonitoring() {
        // Override the monitor's sendNotification method to include Telegram
        const originalSendNotification = this.monitor.sendNotification.bind(this.monitor);
        
        this.monitor.sendNotification = async (title, message, severity = 'warning') => {
            // Send original notifications (email, slack, webhook)
            await originalSendNotification(title, message, severity);
            
            // Send Telegram notification
            await this.sendTelegramAlert(title, message, severity);
        };
    }

    async sendTelegramAlert(title, message, severity) {
        try {
            const icon = severity === 'critical' ? '🔴' : 
                        severity === 'warning' ? '🟡' : '🟢';
            
            let telegramMessage = `${icon} *${title}*\n\n`;
            telegramMessage += `${message}\n\n`;
            telegramMessage += `_${new Date().toLocaleString()}_`;
            
            // Truncate if too long (Telegram limit is 4096 characters)
            if (telegramMessage.length > 4000) {
                telegramMessage = telegramMessage.substring(0, 3900) + '...\n\n_Message truncated_';
            }
            
            await this.bot.sendMessage(this.chatId, telegramMessage, { 
                parse_mode: 'Markdown',
                disable_notification: severity === 'good' // Don't ping for recovery messages
            });
            
            console.log(`Telegram notification sent: ${title}`);
        } catch (error) {
            console.error(`Failed to send Telegram notification: ${error.message}`);
        }
    }

    async start() {
        console.log('Starting Telegram Monitor Bot...');
        
        // Test bot connection
        try {
            const me = await this.bot.getMe();
            console.log(`Bot connected: @${me.username}`);
        } catch (error) {
            console.error('Failed to connect to Telegram:', error.message);
            process.exit(1);
        }
        
        // Start the blockchain monitor
        await this.monitor.start();
        
        console.log('Telegram Monitor Bot is running!');
        console.log(`Send /start to @${(await this.bot.getMe()).username} to begin`);
    }
}

// Handle graceful shutdown
process.on('SIGINT', () => {
    console.log('\nShutting down Telegram bot...');
    process.exit(0);
});

process.on('SIGTERM', () => {
    console.log('\nShutting down Telegram bot...');
    process.exit(0);
});

// Start the bot
if (require.main === module) {
    const bot = new TelegramMonitorBot();
    bot.start().catch(error => {
        console.error('Failed to start Telegram bot:', error);
        process.exit(1);
    });
}

module.exports = TelegramMonitorBot;
