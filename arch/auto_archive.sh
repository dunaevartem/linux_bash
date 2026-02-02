#!/usr/bin/env bash
# ------------------------------------------------------------
# auto_archive.sh
# ------------------------------------------------------------
# Конфиг файл, куда будем сохранять путь по умолчанию
CONFIG_FILE="./backup_src"

# ------------------------------------------------------------
# Читаем путь, либо запрашиваем у пользователя
if [[ -f "$CONFIG_FILE" ]]; then
    # Путь уже сохранён – читаем его
    read -r SRC < "$CONFIG_FILE"

    echo "Текущий путь: $SRC"
    echo "Введите новую директорию или нажмите \"ENTER\", чтобы оставить текущую."
    read -r NEW_SRC

    # Если пользователь ничего не ввёл – оставляем старый путь
    if [[ -n "$NEW_SRC" ]]; then
        SRC="$NEW_SRC"

        # Проверяем, что введённый путь существует
        if [[ ! -d "$SRC" ]]; then
            echo "❌ Каталог \"$SRC\" не найден. Завершение работы."
            exit 1
        fi

        # Сохраняем новый путь
        printf "%s\n" "$SRC" > "$CONFIG_FILE"
        echo "Путь обновлён в $CONFIG_FILE."
    fi
else
    # Путь ещё не задан – спрашиваем
    echo "Первый запуск! Пожалуйста, введите путь к каталогу, который нужно резервировать/восстанавливать."
    echo "Пример: /home/user/projects/myapp"
    read -r SRC

    # Проверяем, что введённый путь существует
    if [[ ! -d "$SRC" ]]; then
        echo " Каталог \"$SRC\" не найден. Завершение работы."
        exit 1
    fi

    # Сохраняем путь в конфиг‑файл
    printf "%s\n" "$SRC" > "$CONFIG_FILE"
    echo "Путь сохранён в $CONFIG_FILE."
fi

# ------------------------------------------------------------
# Настройка остальных переменных
DEST="./backup"                           # каталог для архивов
mkdir -p "$DEST"                          # создаём, если не существует

# ------------------------------------------------------------
# Функция для создания архива
create_backup() {
    ARCHIVE="backup_$(date +%Y%m%d_%H%M%S).tar.gz"
    echo "Архивируем $SRC → $DEST/$ARCHIVE ..."
    tar -czf "$DEST/$ARCHIVE" -C "$SRC" .
    if [[ $? -eq 0 ]]; then
        echo " Резервная копия успешно создана: $DEST/$ARCHIVE"
    else
        echo " Ошибка при создании резервной копии!"
    fi
}

# ------------------------------------------------------------
# Основной цикл меню
while true; do
    echo
    echo "Выберите операцию:"
    echo "1. Архивирование"
    echo "2. Восстановление"
    echo "3. Выход"
    read -p "Введите номер операции: " choice

    case "$choice" in
        1) create_backup ;;
        2)
            # Список архивов
            echo "Список доступных архивов:"
            mapfile -t files < <(ls -1t "$DEST" | grep -E '\.tar\.gz$')
            if [[ ${#files[@]} -eq 0 ]]; then
                echo "Нет доступных архивов."
                continue
            fi
            for i in "${!files[@]}"; do
                printf "%d. %s\n" $((i+1)) "${files[i]}"
            done

            read -p "Введите номер архива для восстановления (x – выйти): " restore_choice
            if [[ "$restore_choice" == "x" ]]; then
                continue
            fi
            if ! [[ "$restore_choice" =~ ^[0-9]+$ ]]; then
                echo " Некорректный ввод."
                continue
            fi
            if (( restore_choice < 1 || restore_choice > ${#files[@]} )); then
                echo " Номер вне диапазона."
                continue
            fi

            ARCHIVE_TO_RESTORE="$DEST/${files[$((restore_choice-1))]}"
            echo "Восстанавливаем $ARCHIVE_TO_RESTORE в $SRC ..."
            if tar -xzf "$ARCHIVE_TO_RESTORE" -C "$SRC"; then
                echo " Восстановление завершено."
            else
                echo " Ошибка при восстановлении."
            fi
            ;;
        3) echo "Выход."; exit 0 ;;
        *) echo " Некорректный выбор. Попробуйте снова." ;;
    esac
done
