1. Создаем скрипт: nano test_monitoring_process.sh

2. Пишем скрипт: 


	#!/bin/bash

LOG_FILE="/var/log/monitoring.log"
MONITORING_URL="https://test.com/monitoring/test/api"
PROCESS_NAME="test"

# Создаем лог файл (если он не существует).
touch $LOG_FILE

# Функция для логирования
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $LOG_FILE
}

# Получаем текущий PID процесса
current_pid=$(pgrep -x $PROCESS_NAME)

# Проверяем, запущен ли процесс
if [ ! -z "$current_pid" ]; then
    # Проверяем, был ли процесс перезапущен
    if [ -f "/tmp/last_pid_$PROCESS_NAME" ]; then
        last_pid=$(cat "/tmp/last_pid_$PROCESS_NAME")
        if [ "$current_pid" != "$last_pid" ]; then
            log_message "Процесс $PROCESS_NAME был перезапущен (старый PID: $last_pid, новый PID: $current_pid)"
        fi
    fi
    
    # Сохраняем текущий PID
    echo $current_pid > "/tmp/last_pid_$PROCESS_NAME"
    
    # Отправляем запрос на сервер мониторинга
    if ! curl -s -f -m 10 $MONITORING_URL &>/dev/null; then
        log_message "Ошибка: сервер мониторинга недоступен"
    fi
fi



3. Создаем systemd unit (мониторинг процесса тест):
 
sudo nano /etc/systemd/system/test_process_monitoring.service


[Unit]

Description=Process Monitor Service

After=network.target



[Service]

Type=simple

ExecStart=/usr/local/bin/test_monitoring_process.sh

Restart=always



[Install]

WantedBy=multi-user.target


	
4. Создаем systemd unit (таймер проверки, работы сервиса мониторинга)

 nano  /etc/systemd/system/test_monitoring.timer

[Unit]

Description=Process Monitor Timer



[Timer]

OnBootSec=1min

OnUnitActiveSec=1min

Unit=test_process_monitoring.service



[Install]

WantedBy=timers.target



5. Делаем скрипт исполняемым:

+x /usr/local/bin/test_monitoring_process.sh

6. Перезагружаем systemd: systemctl daemon-reload	

7. Включаем и запускаем таймер:

systemctl enable test_monitoring.timer
 
systemctl start test_monitoring.timer


8. Мониторинг:

проверить статус - sudo systemctl status test_process_monitoring.service

смотреть логи - journalctl -u test_process_monitoring.service

смотреть в рельном времени - journalctl -u test_process_monitoring.service -f 