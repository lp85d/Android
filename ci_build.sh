#!/bin/bash
set -e

# Этот скрипт адаптирован для запуска в среде GitHub Actions.

# Подключаем скрипт с исходным кодом
source ./source.sh

# Устанавливаем директорию проекта
PROJECT_DIR="$GITHUB_WORKSPACE"
echo "Project directory: $PROJECT_DIR"

# Создаем файлы проекта
create_project_files "$PROJECT_DIR"

# Переходим в директорию проекта
cd "$PROJECT_DIR"

# Настраиваем Gradle Wrapper
echo "Setting up Gradle wrapper..."
gradle wrapper --gradle-version="8.6"
chmod +x gradlew

# Собираем APK
echo "Building APK..."
if ! ./gradlew assembleDebug --stacktrace; then
    echo "APK build failed! Check build.log for details."
    exit 1
fi

# Проверяем наличие собранного APK (в корне проекта)
if [ -f "$PROJECT_DIR/app-debug.apk" ]; then
    echo "APK built successfully!"
    echo "APK path: $PROJECT_DIR/app-debug.apk"
else
    echo "Error: app-debug.apk not found in $PROJECT_DIR!"
    exit 1
fi
