#!/bin/bash

# 1. Проверка и установка пакетов
PACKAGES=(tmux htop mc)
echo "--- Проверка системы ---"
for pkg in "${PACKAGES[@]}"; do
    if ! command -v "$pkg" &> /dev/null; then
        echo "Устанавливаю $pkg..."
        sudo apt update && sudo apt install -y "$pkg"
    fi
done

# 2. Обновление конфига Tmux (перезаписываем начисто)
cat <<EOF > ~/.tmux.conf
set -g mouse on
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R
EOF

# 3. Жесткий перезапуск сессии
if tmux has-session -t devops 2>/dev/null; then
    echo "Сбрасываю старую сессию..."
    tmux kill-session -t devops
fi

echo "Разворачиваю окружение..."
# Создаем сессию и сразу запускаем mc в 0-й панели
tmux new-session -d -s devops -n "WorkSpace" 'mc'

# Делим экран (mc сверху слева)
tmux split-window -h -t devops           # Создает правую половину (панель 1)
tmux split-window -v -t devops:0.0       # Делит левую (теперь mc в 0, под ним 1)
tmux split-window -v -t devops:0.2       # Делит правую (теперь bash в 2, под ним 3)

# Рассылаем команды по панелям
tmux send-keys -t devops:0.1 'htop' C-m
tmux send-keys -t devops:0.3 'watch -n 1 df -h' C-m

# 4. Входим в сессию
echo "Всё готово!"
tmux attach -t devops
