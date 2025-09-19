#!/bin/bash
set -e

# Этот скрипт адаптирован для запуска в среде GitHub Actions.

# Очищаем кэш Gradle
echo "Cleaning Gradle cache..."
rm -rf ~/.gradle/caches

# Устанавливаем директорию проекта
PROJECT_DIR="$GITHUB_WORKSPACE/ParsPost"
echo "Project directory: $PROJECT_DIR"

# Проверяем существование скрипта source.sh
if [ ! -f "./source.sh" ]; then
    echo "Error: source.sh not found in current directory"
    exit 1
fi

# Создаем файлы проекта, передавая имя проекта
echo "Creating project files..."
bash ./source.sh ParsPost 2>&1 | tee build.log

# Проверяем, что директория проекта была создана
if [ ! -d "$PROJECT_DIR" ]; then
    echo "Error: Project directory $PROJECT_DIR was not created"
    exit 1
fi

# Переходим в директорию проекта
cd "$PROJECT_DIR"

# Проверяем наличие build.gradle или build.gradle.kts
if [ ! -f "build.gradle" ] && [ ! -f "build.gradle.kts" ] && [ ! -f "app/build.gradle" ] && [ ! -f "app/build.gradle.kts" ]; then
    echo "Error: No Gradle build files found"
    exit 1
fi

# Настраиваем Gradle Wrapper (используем уже настроенный в workflow)
echo "Setting up Gradle wrapper..."
if command -v gradle >/dev/null 2>&1; then
    gradle wrapper --gradle-version="8.13"
else
    echo "Warning: gradle command not found, skipping wrapper setup"
fi

# Делаем gradlew исполняемым, если он существует
if [ -f "gradlew" ]; then
    chmod +x gradlew
    GRADLE_CMD="./gradlew"
else
    echo "Warning: gradlew not found, using system gradle"
    GRADLE_CMD="gradle"
fi

# Собираем APK с подробным логом
echo "Building APK..."
echo "Current directory: $(pwd)"
echo "Gradle command: $GRADLE_CMD"
echo "Available build files:"
find . -name "build.gradle*" -o -name "settings.gradle*"

# Проверяем структуру проекта
echo "Project structure:"
ls -la
if [ -d "app" ]; then
    echo "App directory contents:"
    ls -la app/
fi

$GRADLE_CMD clean assembleDebug --stacktrace --info 2>&1 | tee -a "$GITHUB_WORKSPACE/build.log"

# Проверяем, что APK был создан
APK_PATH="$PROJECT_DIR/app/build/outputs/apk/debug/app-debug.apk"
if [ -f "$APK_PATH" ]; then
    echo "APK built successfully!"
    echo "APK path: $APK_PATH"
    ls -la "$APK_PATH"
else
    echo "Error: APK not found at expected path: $APK_PATH"
    echo "Searching for APK files..."
    find "$PROJECT_DIR" -name "*.apk" -type f 2>/dev/null || echo "No APK files found"
    echo "Build outputs directory structure:"
    find "$PROJECT_DIR" -path "*/build/outputs*" -type d 2>/dev/null | head -10
    echo "Gradle build directory contents:"
    if [ -d "$PROJECT_DIR/app/build" ]; then
        ls -la "$PROJECT_DIR/app/build/"
    fi
    exit 1
fi
