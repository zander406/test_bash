#!/bin/bash

LOG_FILE="/var/log/monitoring.log"
MONITORING_URL="https://test.com/monitoring/test/api"
PROCESS_NAME="test"

touch $LOG_FILE

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $LOG_FILE
}

current_pid=$(pgrep -x $PROCESS_NAME)

if [ ! -z "$current_pid" ]; then
    if [ -f "/tmp/last_pid_$PROCESS_NAME" ]; then
        last_pid=$(cat "/tmp/last_pid_$PROCESS_NAME")
        if [ "$current_pid" != "$last_pid" ]; then
            log_message "Процесс $PROCESS_NAME был перезапущен (старый PID: $last_pid, новый PID: $current_pid)"
        fi
    fi
    
    echo $current_pid > "/tmp/last_pid_$PROCESS_NAME"
    
    if ! curl -s -f -m 10 $MONITORING_URL &>/dev/null; then
        log_message "Ошибка: сервер мониторинга недоступен"
    fi
fi 