#!/bin/bash
# Команды для выполнения заданий лабораторной работы

# Добавление Ansible в PATH если не найден
if ! command -v ansible &> /dev/null; then
    ANSIBLE_PATHS=(
        "$HOME/.local/bin"
        "$HOME/Library/Python/3.13/bin"
        "$HOME/Library/Python/3.12/bin"
        "$HOME/Library/Python/3.11/bin"
    )
    
    for path in "${ANSIBLE_PATHS[@]}"; do
        if [ -f "$path/ansible" ]; then
            export PATH=$PATH:"$path"
            break
        fi
    done
fi

# Проверка наличия Ansible
if ! command -v ansible &> /dev/null; then
    echo "❌ Ansible не найден. Установите: pip3 install --user ansible"
    exit 1
fi

# ============================================
# Задание 1: Базовое подключение
# ============================================
echo "=== Задание 1: Базовое подключение ==="

# 1. Проверка инвентаря
echo "1. Проверка инвентаря:"
ansible-inventory -i inventory.ini --list

# 2. Ping к управляемому хосту
echo ""
echo "2. Ping к управляемому хосту:"
ansible -i inventory.ini managed_hosts -m ping

# ============================================
# Задание 2: Базовые ad-hoc команды
# ============================================
echo ""
echo "=== Задание 2: Базовые ad-hoc команды ==="

# 1. Информация о ядрах CPU
echo "1. Информация о ядрах CPU:"
ansible -i inventory.ini managed1 -m setup -a "filter=ansible_processor_cores"

# 2. Свободное место на диске
echo ""
echo "2. Свободное место на диске:"
ansible -i inventory.ini managed1 -m command -a "df -h"

# 3. Список пользователей
echo ""
echo "3. Список пользователей (первые 5):"
ansible -i inventory.ini managed1 -m command -a "cat /etc/passwd | head -5"

# 4. Изменение временной зоны
echo ""
echo "4. Изменение временной зоны на UTC:"
ansible -i inventory.ini managed1 -m command -a "timedatectl set-timezone UTC" -b

# Проверка временной зоны
echo ""
echo "Проверка временной зоны:"
ansible -i inventory.ini managed1 -m command -a "timedatectl"

# ============================================
# Задание 3: Работа с файлами
# ============================================
echo ""
echo "=== Задание 3: Работа с файлами ==="
ansible-playbook -i inventory.ini task3_files.yml

