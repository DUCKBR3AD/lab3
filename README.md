# Лабораторная работа: Основы Ansible в DevOps

## 📋 Содержание

1. [Подготовка окружения](#подготовка-окружения)
2. [Задание 1: Базовое подключение](#задание-1-базовое-подключение)
3. [Задание 2: Базовые ad-hoc команды](#задание-2-базовые-ad-hoc-команды)
4. [Задание 3: Работа с файлами](#задание-3-работа-с-файлами)
5. [Полезные команды](#полезные-команды)
6. [Решение проблем](#решение-проблем)

---

## 🚀 Подготовка окружения

### Шаг 1: Установка Ansible

#### Вариант A: Автоматическая установка (рекомендуется)

```bash
cd /Users/duckbread/Desktop/DEVOPS/lab3
./install_ansible.sh
```

#### Вариант B: Ручная установка

```bash
# Установка через pip
pip3 install --user ansible

# Добавление в PATH (для macOS)
export PATH=$PATH:~/Library/Python/3.13/bin

# Или для Linux
export PATH=$PATH:~/.local/bin

# Сохранение PATH в профиль
echo 'export PATH=$PATH:~/Library/Python/3.13/bin' >> ~/.zshrc
source ~/.zshrc
```

**Проверка установки:**
```bash
ansible --version
```

**Ожидаемый результат:**
```
ansible [core 2.20.1]
  ...
```

### Шаг 2: Генерация SSH ключевой пары

```bash
# Генерация SSH ключа
ssh-keygen -t rsa -b 4096 -f ~/.ssh/ansible_key -N ""

# Установка правильных прав доступа
chmod 600 ~/.ssh/ansible_key
chmod 644 ~/.ssh/ansible_key.pub

# Проверка создания ключей
ls -la ~/.ssh/ansible_key*
```

**Ожидаемый результат:**
```
-rw------- 1 user user 3381 ... ansible_key
-rw-r--r-- 1 user user  738 ... ansible_key.pub
```

### Шаг 3: Запуск управляемого контейнера

#### Вариант A: Автоматическая настройка (рекомендуется)

```bash
# Убедитесь, что Docker Desktop запущен
./setup.sh
```

#### Вариант B: Ручная настройка

```bash
# Сборка Docker образа
docker-compose build

# Запуск контейнера
docker-compose up -d

# Проверка статуса
docker-compose ps
```

**Ожидаемый результат:**
```
NAME                    COMMAND               STATUS      PORTS
ansible-managed-host    "/usr/sbin/sshd -D"   Up          0.0.0.0:2222->22/tcp
```

### Шаг 4: Копирование SSH ключа в контейнер

```bash
# Создание директории .ssh в контейнере
docker exec ansible-managed-host mkdir -p /home/ansible/.ssh

# Копирование публичного ключа
docker cp ~/.ssh/ansible_key.pub ansible-managed-host:/home/ansible/.ssh/authorized_keys

# Установка правильных прав доступа
docker exec ansible-managed-host chown -R ansible:ansible /home/ansible/.ssh
docker exec ansible-managed-host chmod 700 /home/ansible/.ssh
docker exec ansible-managed-host chmod 600 /home/ansible/.ssh/authorized_keys
```

### Шаг 5: Проверка SSH подключения

```bash
ssh -i ~/.ssh/ansible_key -p 2222 ansible@localhost
```

**Ожидаемый результат:** Вы должны попасть в контейнер без ввода пароля.

**Выход из контейнера:**
```bash
exit
```

---

## 📝 Задание 1: Базовое подключение

### Цель задания
Настроить базовое подключение Ansible к управляемому хосту и проверить его работоспособность.

### Шаг 1.1: Проверка инвентарного файла

Инвентарный файл `inventory.ini` уже создан. Проверьте его содержимое:

```bash
cat inventory.ini
```

**Содержимое файла:**
```ini
[managed_hosts]
managed1 ansible_host=localhost ansible_port=2222 ansible_user=ansible ansible_ssh_private_key_file=~/.ssh/ansible_key ansible_python_interpreter=/usr/bin/python3

[all:vars]
ansible_ssh_common_args=-o StrictHostKeyChecking=no
ansible_connection_timeout=10
```

### Шаг 1.2: Проверка подключения командой `ansible-inventory --list`

```bash
# Убедитесь, что PATH настроен
export PATH=$PATH:~/Library/Python/3.13/bin

# Проверка инвентаря
ansible-inventory -i inventory.ini --list
```

**Ожидаемый результат:**
```json
{
    "_meta": {
        "hostvars": {
            "managed1": {
                "ansible_host": "localhost",
                "ansible_port": "2222",
                "ansible_user": "ansible",
                ...
            }
        }
    },
    "all": {...},
    "managed_hosts": {
        "hosts": ["managed1"]
    },
    "ungrouped": {}
}
```

### Шаг 1.3: Выполнение ping к управляемому хосту

```bash
ansible -i inventory.ini managed_hosts -m ping
```

**Ожидаемый результат:**
```
managed1 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

✅ **Задание 1 выполнено!** Вы успешно подключились к управляемому хосту через Ansible.

---

## 📝 Задание 2: Базовые ad-hoc команды

### Цель задания
Научиться выполнять базовые команды на удалённых хостах с помощью Ansible ad-hoc команд.

### Шаг 2.1: Получение информации о ядрах CPU

```bash
ansible -i inventory.ini managed1 -m setup -a "filter=ansible_processor_cores"
```

**Ожидаемый результат:**
```json
managed1 | SUCCESS => {
    "ansible_facts": {
        "ansible_processor_cores": 4
    },
    "changed": false
}
```

**Объяснение:**
- `-m setup` — использует модуль setup для сбора информации о системе
- `-a "filter=ansible_processor_cores"` — фильтрует вывод, показывая только информацию о ядрах CPU

### Шаг 2.2: Проверка свободного места на диске

```bash
ansible -i inventory.ini managed1 -m command -a "df -h"
```

**Ожидаемый результат:**
```
managed1 | CHANGED | rc=0 >>
Filesystem      Size  Used Avail Use% Mounted on
overlay         20G   5.2G   14G  28% /
tmpfs            64M     0   64M   0% /dev
...
```

**Объяснение:**
- `-m command` — использует модуль command для выполнения произвольной команды
- `-a "df -h"` — аргумент команды (вывод информации о дисках в человекочитаемом формате)

### Шаг 2.3: Получение списка всех пользователей

```bash
ansible -i inventory.ini managed1 -m command -a "cat /etc/passwd"
```

**Ожидаемый результат:**
```
managed1 | CHANGED | rc=0 >>
root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
ansible:x:1000:1000::/home/ansible:/bin/bash
...
```

**Объяснение:**
- Команда выводит содержимое файла `/etc/passwd`, который содержит информацию о всех пользователях системы

### Шаг 2.4: Изменение временной зоны хоста на UTC

```bash
ansible -i inventory.ini managed1 -m command -a "timedatectl set-timezone UTC" -b
```

**Ожидаемый результат:**
```
managed1 | CHANGED | rc=0 >>
```

**Объяснение:**
- `-b` (или `--become`) — выполнение команды с правами суперпользователя (sudo)
- Команда изменяет временную зону системы на UTC

**Проверка изменения временной зоны:**
```bash
ansible -i inventory.ini managed1 -m command -a "timedatectl"
```

**Ожидаемый результат:**
```
managed1 | CHANGED | rc=0 >>
               Local time: Thu 2025-12-12 17:50:00 UTC
           Universal time: Thu 2025-12-12 17:50:00 UTC
                 RTC time: Thu 2025-12-12 17:50:00 UTC
                Time zone: UTC (UTC, +0000)
...
```

✅ **Задание 2 выполнено!** Вы успешно выполнили все ad-hoc команды без ошибок.

---

## 📝 Задание 3: Работа с файлами

### Цель задания
Создать playbook для автоматизации работы с файлами и директориями на управляемом хосте.

### Шаг 3.1: Проверка playbook `task3_files.yml`

Файл `task3_files.yml` уже создан. Проверьте его содержимое:

```bash
cat task3_files.yml
```

**Содержимое файла:**
```yaml
---
- name: Work with files
  hosts: managed_hosts
  tasks:
    - name: Create multiple directories
      file:
        path: /tmp/{{ item }}
        state: directory
        mode: '0755'
      loop:
        - test_dir1
        - test_dir2
        - test_dir3

    - name: Create files in directories
      copy:
        content: "This is {{ item }} file\n"
        dest: /tmp/{{ item }}/content.txt
      loop:
        - test_dir1
        - test_dir2
        - test_dir3

    - name: Display files
      command: cat /tmp/{{ item }}/content.txt
      loop:
        - test_dir1
        - test_dir2
        - test_dir3
      register: file_content

    - name: Show file contents
      debug:
        msg: "{{ item.stdout }}"
      loop: "{{ file_content.results }}"
```

**Объяснение структуры playbook:**
- `name` — название playbook
- `hosts: managed_hosts` — группа хостов из инвентаря
- `tasks` — список задач для выполнения
- `loop` — цикл для выполнения задачи с несколькими значениями
- `register` — сохранение результата выполнения команды в переменную
- `debug` — вывод информации в консоль

### Шаг 3.2: Проверка синтаксиса playbook

```bash
ansible-playbook -i inventory.ini task3_files.yml --syntax-check
```

**Ожидаемый результат:**
```
playbook: task3_files.yml
```

Если синтаксис корректен, ошибок не будет.

### Шаг 3.3: Запуск playbook

```bash
ansible-playbook -i inventory.ini task3_files.yml
```

**Ожидаемый результат:**
```
PLAY [managed_hosts] ************************************************************

TASK [Gathering Facts] **********************************************************
ok: [managed1]

TASK [Create multiple directories] **********************************************
changed: [managed1] => (item=test_dir1)
changed: [managed1] => (item=test_dir2)
changed: [managed1] => (item=test_dir3)

TASK [Create files in directories] **********************************************
changed: [managed1] => (item=test_dir1)
changed: [managed1] => (item=test_dir2)
changed: [managed1] => (item=test_dir3)

TASK [Display files] ************************************************************
changed: [managed1] => (item=test_dir1)
changed: [managed1] => (item=test_dir2)
changed: [managed1] => (item=test_dir3)

TASK [Show file contents] *******************************************************
ok: [managed1] => (item={'item': 'test_dir1', 'stdout': 'This is test_dir1 file', ...}) => {
    "msg": "This is test_dir1 file"
}
ok: [managed1] => (item={'item': 'test_dir2', 'stdout': 'This is test_dir2 file', ...}) => {
    "msg": "This is test_dir2 file"
}
ok: [managed1] => (item={'item': 'test_dir3', 'stdout': 'This is test_dir3 file', ...}) => {
    "msg": "This is test_dir3 file"
}

PLAY RECAP **********************************************************************
managed1                   : ok=5    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

### Шаг 3.4: Проверка созданных файлов на управляемом хосте

```bash
# Проверка через SSH
ssh -i ~/.ssh/ansible_key -p 2222 ansible@localhost "ls -la /tmp/test_dir*"

# Или через Ansible
ansible -i inventory.ini managed1 -m command -a "ls -la /tmp/test_dir*"
```

**Ожидаемый результат:**
```
drwxr-xr-x 2 ansible ansible 4096 ... test_dir1
drwxr-xr-x 2 ansible ansible 4096 ... test_dir2
drwxr-xr-x 2 ansible ansible 4096 ... test_dir3
```

**Проверка содержимого файлов:**
```bash
ansible -i inventory.ini managed1 -m command -a "cat /tmp/test_dir1/content.txt"
ansible -i inventory.ini managed1 -m command -a "cat /tmp/test_dir2/content.txt"
ansible -i inventory.ini managed1 -m command -a "cat /tmp/test_dir3/content.txt"
```

**Ожидаемый результат:**
```
managed1 | CHANGED | rc=0 >>
This is test_dir1 file

managed1 | CHANGED | rc=0 >>
This is test_dir2 file

managed1 | CHANGED | rc=0 >>
This is test_dir3 file
```

✅ **Задание 3 выполнено!** Три директории с файлами успешно созданы на управляемом хосте.

---

## 🛠️ Полезные команды

### Отладка и проверка

```bash
# Проверка синтаксиса playbook
ansible-playbook -i inventory.ini playbook.yml --syntax-check

# Запуск с подробным выводом (уровень детализации)
ansible-playbook -i inventory.ini playbook.yml -v    # базовый
ansible-playbook -i inventory.ini playbook.yml -vv   # подробный
ansible-playbook -i inventory.ini playbook.yml -vvv  # очень подробный

# Проверка подключения с дебагом SSH
ssh -v -i ~/.ssh/ansible_key -p 2222 ansible@localhost

# Сбор всей информации о системе (facts)
ansible -i inventory.ini managed1 -m setup

# Сбор информации о конкретном параметре
ansible -i inventory.ini managed1 -m setup -a "filter=ansible_*_mb"
```

### Управление контейнером

```bash
# Просмотр статуса контейнеров
docker-compose ps

# Просмотр логов контейнера
docker logs ansible-managed-host

# Просмотр логов в реальном времени
docker logs -f ansible-managed-host

# Перезапуск контейнера
docker-compose restart

# Остановка контейнера
docker-compose stop

# Запуск контейнера
docker-compose start

# Остановка и удаление контейнера
docker-compose down

# Остановка, удаление контейнера и образов
docker-compose down --rmi all
```

### Автоматическое выполнение всех заданий

```bash
# Выполнение всех заданий одной командой
./commands.sh
```

---

## 🔧 Решение проблем

### Проблема 1: "Permission denied (publickey)"

**Симптомы:**
```
managed1 | UNREACHABLE! => {
    "msg": "Failed to connect to the host via ssh: Permission denied (publickey)"
}
```

**Решение:**
```bash
# Проверка прав на приватный ключ
chmod 600 ~/.ssh/ansible_key

# Проверка публичного ключа в контейнере
docker exec ansible-managed-host cat /home/ansible/.ssh/authorized_keys

# Переустановка ключа
docker exec ansible-managed-host rm -f /home/ansible/.ssh/authorized_keys
docker cp ~/.ssh/ansible_key.pub ansible-managed-host:/home/ansible/.ssh/authorized_keys
docker exec ansible-managed-host chmod 600 /home/ansible/.ssh/authorized_keys
docker exec ansible-managed-host chown ansible:ansible /home/ansible/.ssh/authorized_keys
```

### Проблема 2: "Connection refused" на порту 2222

**Симптомы:**
```
managed1 | UNREACHABLE! => {
    "msg": "Failed to connect to the host via ssh: Connection refused"
}
```

**Решение:**
```bash
# Проверка запущен ли контейнер
docker ps

# Проверка статуса через docker-compose
docker-compose ps

# Пересоздание контейнера
docker-compose down
docker-compose up -d

# Проверка логов
docker logs ansible-managed-host
```

### Проблема 3: "ansible: command not found"

**Симптомы:**
```
zsh: command not found: ansible
```

**Решение:**
```bash
# Добавление Ansible в PATH
export PATH=$PATH:~/Library/Python/3.13/bin

# Или для Linux
export PATH=$PATH:~/.local/bin

# Проверка установки
which ansible

# Если не найден, переустановите
pip3 install --user ansible
```

### Проблема 4: "UNREACHABLE! => {msg: 'Failed to connect to the host via ssh'}"

**Решение:**
1. Проверьте SSH подключение вручную:
   ```bash
   ssh -i ~/.ssh/ansible_key -p 2222 ansible@localhost
   ```

2. Убедитесь, что SSH сервис запущен в контейнере:
   ```bash
   docker exec ansible-managed-host service ssh status
   ```

3. Проверьте права на файлы в `.ssh`:
   ```bash
   docker exec ansible-managed-host ls -la /home/ansible/.ssh
   ```

4. Перезапустите контейнер:
   ```bash
   docker-compose restart
   ```

### Проблема 5: "No module named 'jinja2'"

**Симптомы:**
```
ModuleNotFoundError: No module named 'jinja2'
```

**Решение:**
```bash
pip3 install jinja2
# Или переустановите Ansible
pip3 install --user --upgrade ansible
```

### Проблема 6: "The task includes an option with an undefined variable"

**Симптомы:**
```
The task includes an option with an undefined variable
```

**Решение:**
- Проверьте синтаксис YAML файла
- Убедитесь, что все переменные определены
- Проверьте отступы (используйте пробелы, а не табы)

---

## 📚 Дополнительные ресурсы

- [Официальная документация Ansible](https://docs.ansible.com/)
- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/tips_tricks/index.html)
- [Ansible Modules Index](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/index.html)
- [Docker Documentation](https://docs.docker.com/)

---

## ✅ Чек-лист выполнения лабораторной работы

- [ ] Ansible установлен и работает
- [ ] SSH ключи созданы и настроены
- [ ] Docker контейнер запущен
- [ ] SSH подключение работает
- [ ] Задание 1: Базовое подключение выполнено
- [ ] Задание 2: Базовые ad-hoc команды выполнены
- [ ] Задание 3: Работа с файлами выполнена
- [ ] Все команды выполняются без ошибок

---

**Успешного выполнения лабораторной работы! 🎉**
