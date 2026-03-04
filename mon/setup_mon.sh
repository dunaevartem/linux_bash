#!/bin/bash

# 1. Проверка и установка пакетов
PACKAGES=(tmux htop mc)
for pkg in "${PACKAGES[@]}"; do
    if ! command -v "$pkg" &> /dev/null; then
        sudo apt update && sudo apt install -y "$pkg"
    fi
done

# 2. Обновление конфига Tmux
cat <<EOF > ~/.tmux.conf
set -g mouse on
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R
EOF

# 3. Логика переключателя (Toggle)
if tmux has-session -t mon 2>/dev/null; then
    tmux kill-session -t mon
    # После kill-session скрипт просто закончится, в фоне ничего не останется
else
    
    # Создаем сессию в фоне
    tmux new-session -d -s mon -n "WorkSpace" 'mc'

    # Делим экран
    tmux split-window -h -t mon
    tmux split-window -v -t mon:0.0
    tmux split-window -v -t mon:0.2

    # Запускаем команды
    tmux send-keys -t mon:0.1 'htop' C-m
    tmux send-keys -t mon:0.3 'watch -n 1 df -h' C-m

    # Входим в сессию
    tmux attach -t mon
fi
