#!/bin/bash
# Скрипт для установки Ansible

set -e

echo "=== Установка Ansible ==="

# Проверка Python
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 не установлен. Установите Python 3.9+"
    exit 1
fi

echo "✅ Python найден: $(python3 --version)"

# Проверка pip
if ! command -v pip3 &> /dev/null; then
    echo "❌ pip3 не установлен. Установите pip3"
    exit 1
fi

echo "✅ pip3 найден: $(pip3 --version)"

# Установка Ansible
echo ""
echo "=== Установка Ansible через pip3 ==="
pip3 install --user ansible

# Определение пути установки
PYTHON_VERSION=$(python3 --version | awk '{print $2}' | cut -d. -f1,2)
ANSIBLE_PATH="$HOME/Library/Python/$PYTHON_VERSION/bin"

# Если путь не найден, пробуем стандартный
if [ ! -d "$ANSIBLE_PATH" ]; then
    ANSIBLE_PATH="$HOME/.local/bin"
fi

echo ""
echo "=== Добавление Ansible в PATH ==="

# Проверка наличия в .zshrc
if grep -q "Library/Python.*bin" ~/.zshrc 2>/dev/null || grep -q ".local/bin" ~/.zshrc 2>/dev/null; then
    echo "✅ PATH уже настроен в ~/.zshrc"
else
    echo "export PATH=\$PATH:$ANSIBLE_PATH" >> ~/.zshrc
    echo "✅ PATH добавлен в ~/.zshrc"
fi

# Добавление в текущую сессию
export PATH=$PATH:"$ANSIBLE_PATH"

# Проверка установки
echo ""
echo "=== Проверка установки ==="
if command -v ansible &> /dev/null; then
    echo "✅ Ansible успешно установлен!"
    ansible --version
    echo ""
    echo "⚠️  ВАЖНО: Для использования в новых терминалах выполните:"
    echo "   source ~/.zshrc"
    echo "   или откройте новый терминал"
else
    echo "⚠️  Ansible установлен, но не найден в PATH"
    echo "Выполните вручную:"
    echo "   export PATH=\$PATH:$ANSIBLE_PATH"
    echo "   source ~/.zshrc"
fi

