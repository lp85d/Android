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

# ИСПРАВЛЕНИЕ 1: Убираем передачу параметра в source.sh (он не принимает параметры)
echo "Creating project files..."
bash ./source.sh 2>&1 | tee build.log

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

# ИСПРАВЛЕНИЕ 2: Убираем попытку создать wrapper (он уже есть в проекте)
echo "Checking Gradle wrapper..."

# Делаем gradlew исполняемым, если он существует
if [ -f "gradlew" ]; then
    chmod +x gradlew
    GRADLE_CMD="./gradlew"
else
    echo "Error: gradlew not found in project"
    exit 1
fi

# ИСПРАВЛЕНИЕ 3: Добавляем проверку Gradle wrapper файлов
if [ ! -f "gradle/wrapper/gradle-wrapper.properties" ]; then
    echo "Error: Gradle wrapper properties not found"
    exit 1
fi

echo "Building APK..."
echo "Current directory: $(pwd)"
echo "Gradle command: $GRADLE_CMD"

echo "Available build files:"
find . -name "build.gradle*" -o -name "settings.gradle*" 2>/dev/null || echo "No gradle files found"

# Проверяем структуру проекта
echo "Project structure:"
ls -la

if [ -d "app" ]; then
    echo "App directory contents:"
    ls -la app/
    
    # ИСПРАВЛЕНИЕ 4: Проверяем наличие исходников
    if [ ! -d "app/src/main/java" ] && [ ! -d "app/src/main/kotlin" ]; then
        echo "Error: No source code found in app/src/main/"
        exit 1
    fi
fi

# ИСПРАВЛЕНИЕ 5: Добавляем переменные окружения для стабильной сборки
export GRADLE_OPTS="-Xmx2048m -XX:MaxMetaspaceSize=512m -Dorg.gradle.daemon=false"
export ANDROID_COMPILE_SDK=34
export ANDROID_BUILD_TOOLS=34.0.0

# ИСПРАВЛЕНИЕ 6: Добавляем информацию о Java и Android SDK
echo "Environment info:"
echo "Java version: $(java -version 2>&1 | head -1)"
echo "Android SDK: ${ANDROID_HOME:-Not set}"
echo "GRADLE_OPTS: $GRADLE_OPTS"

# ИСПРАВЛЕНИЕ 7: Более надежная сборка с обработкой ошибок
echo "Starting Gradle build..."
if ! $GRADLE_CMD --version; then
    echo "Error: Gradle command failed"
    exit 1
fi

# Собираем APK с правильным выводом в лог
$GRADLE_CMD clean assembleDebug --stacktrace --no-daemon 2>&1 | tee -a "$GITHUB_WORKSPACE/build.log"

# ИСПРАВЛЕНИЕ 8: Более точная проверка результата сборки
echo "Checking build results..."
APK_PATH="$PROJECT_DIR/app/build/outputs/apk/debug/app-debug.apk"

if [ -f "$APK_PATH" ]; then
    echo "✅ APK built successfully!"
    echo "APK path: $APK_PATH"
    echo "APK size: $(du -h "$APK_PATH" | cut -f1)"
    ls -la "$APK_PATH"
    
    # ИСПРАВЛЕНИЕ 9: Проверяем валидность APK
    if file "$APK_PATH" | grep -q "Android"; then
        echo "✅ APK file is valid Android package"
    else
        echo "⚠️ Warning: APK file might be corrupted"
        file "$APK_PATH"
    fi
else
    echo "❌ Error: APK not found at expected path: $APK_PATH"
    echo "Searching for APK files..."
    
    # Расширенный поиск APK файлов
    find "$PROJECT_DIR" -name "*.apk" -type f 2>/dev/null | while read apk; do
        echo "Found APK: $apk ($(du -h "$apk" | cut -f1))"
    done || echo "No APK files found anywhere"
    
    echo "Build outputs directory structure:"
    if [ -d "$PROJECT_DIR/app/build" ]; then
        echo "Build directory exists, contents:"
        find "$PROJECT_DIR/app/build" -type f -name "*" 2>/dev/null | head -20
    else
        echo "Build directory not found!"
    fi
    
    # ИСПРАВЛЕНИЕ 10: Показываем последние строки лога сборки для диагностики
    echo "Last 50 lines of build log:"
    tail -50 "$GITHUB_WORKSPACE/build.log" 2>/dev/null || echo "Build log not accessible"
    
    exit 1
fi

echo "🎉 Build completed successfully!"
