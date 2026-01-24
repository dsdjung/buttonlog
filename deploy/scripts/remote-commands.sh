#!/bin/bash
# =============================================================================
# ButtonLog Remote Commands Helper
# Quick access to common server operations
# =============================================================================

set -euo pipefail

# Configuration
SERVER_USER="buttonlog"
SERVER_HOST="${DEPLOY_HOST:-your-server.com}"
SERVER_PORT="${DEPLOY_PORT:-22}"

SSH_CMD="ssh -p ${SERVER_PORT} ${SERVER_USER}@${SERVER_HOST}"

case "${1:-help}" in
    logs)
        # View application logs
        ${SSH_CMD} "journalctl -u buttonlog -f"
        ;;

    logs-error)
        # View error logs only
        ${SSH_CMD} "tail -f /var/log/buttonlog/error.log"
        ;;

    status)
        # Check service status
        ${SSH_CMD} "systemctl status buttonlog"
        ;;

    restart)
        # Restart the application
        ${SSH_CMD} "sudo systemctl restart buttonlog"
        echo "Service restarted"
        ;;

    stop)
        # Stop the application
        ${SSH_CMD} "sudo systemctl stop buttonlog"
        echo "Service stopped"
        ;;

    start)
        # Start the application
        ${SSH_CMD} "sudo systemctl start buttonlog"
        echo "Service started"
        ;;

    console)
        # Open remote IEx console
        ${SSH_CMD} -t "/opt/buttonlog/current/bin/buttonlog remote"
        ;;

    migrate)
        # Run database migrations
        ${SSH_CMD} "source /opt/buttonlog/config/.env && /opt/buttonlog/current/bin/buttonlog eval 'ButtonLog.Release.migrate()'"
        ;;

    health)
        # Check health endpoint
        ${SSH_CMD} "curl -sf http://localhost:4000/health && echo ' OK' || echo ' FAILED'"
        ;;

    disk)
        # Check disk usage
        ${SSH_CMD} "df -h"
        ;;

    memory)
        # Check memory usage
        ${SSH_CMD} "free -h"
        ;;

    releases)
        # List deployed releases
        ${SSH_CMD} "ls -lt /opt/buttonlog/releases"
        ;;

    current)
        # Show current release
        ${SSH_CMD} "readlink /opt/buttonlog/current"
        ;;

    env)
        # Show environment (masked)
        ${SSH_CMD} "cat /opt/buttonlog/config/.env | sed 's/=.*/=***MASKED***/'"
        ;;

    nginx-test)
        # Test nginx configuration
        ${SSH_CMD} "sudo nginx -t"
        ;;

    nginx-reload)
        # Reload nginx configuration
        ${SSH_CMD} "sudo systemctl reload nginx"
        echo "Nginx reloaded"
        ;;

    ssl-renew)
        # Renew SSL certificates
        ${SSH_CMD} "sudo certbot renew"
        ;;

    db-backup)
        # Create database backup
        BACKUP_FILE="buttonlog_backup_$(date +%Y%m%d_%H%M%S).sql"
        ${SSH_CMD} "source /opt/buttonlog/config/.env && pg_dump \${DATABASE_URL} > /tmp/${BACKUP_FILE} && gzip /tmp/${BACKUP_FILE}"
        scp -P ${SERVER_PORT} ${SERVER_USER}@${SERVER_HOST}:/tmp/${BACKUP_FILE}.gz ./
        ${SSH_CMD} "rm /tmp/${BACKUP_FILE}.gz"
        echo "Backup saved to ./${BACKUP_FILE}.gz"
        ;;

    shell)
        # Open SSH shell
        ${SSH_CMD}
        ;;

    help|*)
        echo "ButtonLog Remote Commands"
        echo ""
        echo "Usage: $0 <command>"
        echo ""
        echo "Application:"
        echo "  logs         - View application logs (live)"
        echo "  logs-error   - View error logs only"
        echo "  status       - Check service status"
        echo "  restart      - Restart application"
        echo "  stop         - Stop application"
        echo "  start        - Start application"
        echo "  console      - Open remote IEx console"
        echo "  migrate      - Run database migrations"
        echo "  health       - Check health endpoint"
        echo ""
        echo "Releases:"
        echo "  releases     - List deployed releases"
        echo "  current      - Show current release"
        echo ""
        echo "Server:"
        echo "  disk         - Check disk usage"
        echo "  memory       - Check memory usage"
        echo "  shell        - Open SSH shell"
        echo "  env          - Show environment (masked)"
        echo ""
        echo "Nginx:"
        echo "  nginx-test   - Test nginx configuration"
        echo "  nginx-reload - Reload nginx"
        echo "  ssl-renew    - Renew SSL certificates"
        echo ""
        echo "Database:"
        echo "  db-backup    - Download database backup"
        ;;
esac
