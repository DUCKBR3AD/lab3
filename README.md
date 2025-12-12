# Лабораторная работа: Основы Ansible в DevOps

## 📋 Содержание

1. [Подготовка окружения](#подготовка-окружения)
2. [Задание 1: Базовое подключение](#задание-1-базовое-подключение)
3. [Задание 2: Базовые ad-hoc команды](#задание-2-базовые-ad-hoc-команды)
4. [Задание 3: Работа с файлами](#задание-3-работа-с-файлами)

---

##  Подготовка окружения

### Шаг 1: Установка Ansible

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

## Задание 1: Базовое подключение

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

**Результат:**
![telegram-cloud-photo-size-2-5323654939294767054-y](https://github.com/user-attachments/assets/836b8b2a-5a56-4e75-afbe-d12e05d9a17f)


### Шаг 1.3: Выполнение ping к управляемому хосту

```bash
ansible -i inventory.ini managed_hosts -m ping
```

**Результат:**
![telegram-cloud-photo-size-2-5323654939294767076-y](https://github.com/user-attachments/assets/6859d348-2ec9-4b0b-ba8e-a3df0016b666)


---

## Задание 2: Базовые ad-hoc команды

### Цель задания
Научиться выполнять базовые команды на удалённых хостах с помощью Ansible ad-hoc команд.

### Шаг 2.1: Получение информации о ядрах CPU

```bash
ansible -i inventory.ini managed1 -m setup -a "filter=ansible_processor_cores"
```

**Результат:**
![telegram-cloud-photo-size-2-5323654939294767076-y](https://github.com/user-attachments/assets/3473931a-e523-4d62-b6dd-f4d018d5723c)


**Объяснение:**
- `-m setup` — использует модуль setup для сбора информации о системе
- `-a "filter=ansible_processor_cores"` — фильтрует вывод, показывая только информацию о ядрах CPU

### Шаг 2.2: Проверка свободного места на диске

```bash
ansible -i inventory.ini managed1 -m command -a "df -h"
```

**Результат:**
![telegram-cloud-photo-size-2-5323654939294767094-y](https://github.com/user-attachments/assets/0f8ef269-b6ad-4126-beb7-d65689e2e95d)

**Объяснение:**
- `-m command` — использует модуль command для выполнения произвольной команды
- `-a "df -h"` — аргумент команды (вывод информации о дисках в человекочитаемом формате)

### Шаг 2.3: Получение списка всех пользователей

```bash
ansible -i inventory.ini managed1 -m command -a "cat /etc/passwd"
```

**Результат:**
![telegram-cloud-photo-size-2-5323654939294767097-y](https://github.com/user-attachments/assets/c38f78b5-9b11-45eb-8fc1-7b4052aa0832)


**Объяснение:**
- Команда выводит содержимое файла `/etc/passwd`, который содержит информацию о всех пользователях системы

### Шаг 2.4: Изменение временной зоны хоста на UTC

```bash
ansible -i inventory.ini managed1 -m command -a "timedatectl set-timezone UTC" -b
```

**Результат:**
<img width="686" height="67" alt="telegram-cloud-document-2-5323654938834800251" src="https://github.com/user-attachments/assets/ed8fb9be-11e6-454d-9ae9-731fa2d0506d" />


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



---

## Задание 3: Работа с файлами

### Цель задания
Создать playbook для автоматизации работы с файлами и директориями на управляемом хосте.

### Шаг 3.1: Проверка playbook `task3_files.yml`

Файл `task3_files.yml` уже создан. 

```bash
cat task3_files.yml
```

**Содержимое файла:**
![telegram-cloud-photo-size-2-5323654939294767112-y](https://github.com/user-attachments/assets/16e16ce4-046f-476e-a234-9cdad960265b)


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

**Результат:**
![telegram-cloud-photo-size-2-5323654939294767113-y](https://github.com/user-attachments/assets/fa093e54-81f8-4034-a4fa-da610b6f6ebf)



### Шаг 3.3: Запуск playbook

```bash
ansible-playbook -i inventory.ini task3_files.yml
```

**Результат:**
![telegram-cloud-photo-size-2-5323654939294767118-y](https://github.com/user-attachments/assets/92f714b4-9202-4633-bb5d-5656966e55f4)

### Шаг 3.4: Проверка созданных файлов на управляемом хосте

```bash
# Проверка через SSH
ssh -i ~/.ssh/ansible_key -p 2222 ansible@localhost "ls -la /tmp/test_dir*"

# Или через Ansible
ansible -i inventory.ini managed1 -m command -a "ls -la /tmp/test_dir*"
```


**Проверка содержимого файлов:**
```bash
ansible -i inventory.ini managed1 -m command -a "cat /tmp/test_dir1/content.txt"
ansible -i inventory.ini managed1 -m command -a "cat /tmp/test_dir2/content.txt"
ansible -i inventory.ini managed1 -m command -a "cat /tmp/test_dir3/content.txt"
```

**Результат:**
![telegram-cloud-photo-size-2-5323654939294767119-y](https://github.com/user-attachments/assets/ab61be80-32b9-4d93-9abe-f25f21c92ebe)





## Дополнительные ресурсы

- [Официальная документация Ansible](https://docs.ansible.com/)
- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/tips_tricks/index.html)
- [Ansible Modules Index](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/index.html)
- [Docker Documentation](https://docs.docker.com/)


