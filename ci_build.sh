#!/bin/bash
set -e

# Этот скрипт адаптирован для запуска в среде GitHub Actions.

# Подключаем скрипт с исходным кодом
source ./source.sh

# Устанавливаем директорию проекта
PROJECT_DIR="$GITHUB_WORKSPACE/ParsPost"
echo "Project directory: $PROJECT_DIR"

# Создаем файлы проекта
create_project_files "$PROJECT_DIR"

# Переходим в директорию проекта
cd "$PROJECT_DIR"

# Настраиваем Gradle Wrapper
echo "Setting up Gradle wrapper..."
gradle wrapper --gradle-version="8.5"
chmod +x gradlew

# Собираем APK
echo "Building APK..."
./gradlew assembleDebug --stacktrace

# Выводим путь к собранному APK
echo "APK built successfully!"
echo "APK path: $PROJECT_DIR/app/build/outputs/apk/debug/app-debug.apk"
