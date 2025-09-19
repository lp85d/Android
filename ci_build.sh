#!/bin/bash
set -e

# Этот скрипт адаптирован для запуска в среде GitHub Actions.

# Очищаем кэш Gradle
echo "Cleaning Gradle cache..."
rm -rf ~/.gradle/caches

# Устанавливаем директорию проекта
PROJECT_DIR="$GITHUB_WORKSPACE/ParsPost"
echo "Project directory: $PROJECT_DIR"

# Создаем файлы проекта, передавая имя проекта
echo "Creating project files..."
./source.sh ParsPost | tee build.log

# Переходим в директорию проекта
cd "$PROJECT_DIR"

# Настраиваем Gradle Wrapper
echo "Setting up Gradle wrapper..."
gradle wrapper --gradle-version="8.13"
chmod +x gradlew

# Собираем APK с подробным логом
echo "Building APK..."
./gradlew assembleDebug --stacktrace --debug | tee -a build.log

# Выводим путь к собранному APK
echo "APK built successfully!"
echo "APK path: $PROJECT_DIR/app/build/outputs/apk/debug/app-debug.apk"
