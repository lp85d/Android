#!/bin/bash
set -e

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
gradle wrapper --gradle-version="9.0.0"
chmod +x gradlew

# Собираем APK
echo "Building APK..."
if ! ./gradlew assembleDebug --stacktrace; then
    echo "APK build failed! Check build.log for details."
    exit 1
fi

# Копируем APK в корень проекта
echo "Copying APK to root directory..."
cp app/build/outputs/apk/debug/app-debug.apk "$PROJECT_DIR/app-debug.apk"

# Проверяем наличие собранного APK
if [ -f "$PROJECT_DIR/app-debug.apk" ]; then
    echo "APK built successfully!"
    echo "APK path: $PROJECT_DIR/app-debug.apk"
else
    echo "Error: app-debug.apk not found in $PROJECT_DIR!"
    exit 1
fi
