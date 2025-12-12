FROM ubuntu:22.04

# Установка необходимых пакетов
RUN apt-get update && apt-get install -y \
    openssh-server \
    openssh-client \
    python3 \
    python3-pip \
    sudo \
    curl \
    wget \
    git \
    nano \
    htop \
    && rm -rf /var/lib/apt/lists/*

# Создание пользователя ansible
RUN useradd -m -s /bin/bash ansible && \
    echo "ansible ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Настройка SSH
RUN mkdir -p /run/sshd && \
    sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

# Создание .ssh директории для пользователя ansible
RUN mkdir -p /home/ansible/.ssh && \
    chown -R ansible:ansible /home/ansible/.ssh && \
    chmod 700 /home/ansible/.ssh

# Запуск SSH сервера в foreground режиме
CMD ["/usr/sbin/sshd", "-D"]

