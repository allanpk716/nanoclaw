module.exports = {
  apps: [{
    name: 'nanoclaw',
    script: 'dist/index.js',
    cwd: 'C:\\WorkSpace\\agent\\nanoclaw',
    interpreter: 'node',
    instances: 1,
    exec_mode: 'fork',  // Use fork mode instead of cluster for proper logging
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    env_file: '.env',  // Load environment variables from .env file
    error_file: 'C:\\WorkSpace\\agent\\nanoclaw\\logs\\pm2-error.log',
    out_file: 'C:\\WorkSpace\\agent\\nanoclaw\\logs\\pm2-out.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss',
    merge_logs: true,
    max_restarts: 10,
    min_uptime: '10s',
    restart_delay: 5000,
    kill_timeout: 10000  // Wait 10 seconds for graceful shutdown
  }]
};
