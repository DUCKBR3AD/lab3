#!/bin/bash
# Скрипт для автоматизации настройки лабораторной работы Ansible

set -e

echo "=== Настройка лабораторной работы Ansible ==="

# Проверка Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker не установлен. Установите Docker Desktop."
    exit 1
fi

if ! docker info &> /dev/null; then
    echo "❌ Docker daemon не запущен. Запустите Docker Desktop."
    exit 1
fi

# Проверка Ansible и добавление в PATH
ANSIBLE_PATHS=(
    "$HOME/.local/bin"
    "$HOME/Library/Python/3.13/bin"
    "$HOME/Library/Python/3.12/bin"
    "$HOME/Library/Python/3.11/bin"
)

if ! command -v ansible &> /dev/null; then
    echo "⚠️  Ansible не найден в PATH."
    echo "Поиск Ansible в стандартных путях..."
    
    FOUND=false
    for path in "${ANSIBLE_PATHS[@]}"; do
        if [ -f "$path/ansible" ]; then
            export PATH=$PATH:"$path"
            echo "✅ Ansible найден в $path"
            FOUND=true
            break
        fi
    done
    
    if [ "$FOUND" = false ]; then
        echo "❌ Ansible не установлен. Установите: pip3 install --user ansible"
        exit 1
    fi
fi

echo "✅ Docker и Ansible готовы"

# Сборка и запуск контейнера
echo ""
echo "=== Сборка Docker образа ==="
docker-compose build

echo ""
echo "=== Запуск контейнера ==="
docker-compose up -d

# Ожидание запуска SSH сервера
echo ""
echo "=== Ожидание запуска SSH сервера ==="
sleep 5

# Копирование SSH ключа
echo ""
echo "=== Настройка SSH ключей ==="
docker exec ansible-managed-host mkdir -p /home/ansible/.ssh
docker cp ~/.ssh/ansible_key.pub ansible-managed-host:/home/ansible/.ssh/authorized_keys
docker exec ansible-managed-host chown -R ansible:ansible /home/ansible/.ssh
docker exec ansible-managed-host chmod 700 /home/ansible/.ssh
docker exec ansible-managed-host chmod 600 /home/ansible/.ssh/authorized_keys

echo "✅ SSH ключи настроены"

# Проверка подключения
echo ""
echo "=== Проверка SSH подключения ==="
if ssh -i ~/.ssh/ansible_key -p 2222 -o ConnectTimeout=5 -o StrictHostKeyChecking=no ansible@localhost exit 2>/dev/null; then
    echo "✅ SSH подключение работает"
else
    echo "⚠️  SSH подключение не работает. Проверьте контейнер: docker-compose ps"
fi

# Проверка Ansible инвентаря
echo ""
echo "=== Проверка Ansible инвентаря ==="
if command -v ansible-inventory &> /dev/null; then
    ansible-inventory -i inventory.ini --list
    echo "✅ Инвентарь настроен"
else
    echo "⚠️  ansible-inventory не найден"
fi

# Проверка ping
echo ""
echo "=== Проверка Ansible ping ==="
if command -v ansible &> /dev/null; then
    ansible -i inventory.ini managed_hosts -m ping
    echo "✅ Ansible ping работает"
else
    echo "⚠️  ansible не найден"
fi

echo ""
echo "=== Настройка завершена! ==="
echo ""
echo "Полезные команды:"
echo "  - Проверить статус: docker-compose ps"
echo "  - Просмотр логов: docker logs ansible-managed-host"
echo "  - Запуск playbook: ansible-playbook -i inventory.ini playbook.yml"
echo "  - Остановка: docker-compose down"

