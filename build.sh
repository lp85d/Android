#!/bin/bash

# ЧАСТЬ 2: СИСТЕМА СБОРКИ
# Этот скрипт настраивает окружение для Android-разработки в Termux,
# создает структуру проекта и собирает APK, используя исходный код из source.sh.

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Функции логирования
log() { echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"; }
warn() { echo -e "${YELLOW}[WARNING] $1${NC}"; }
error() { echo -e "${RED}[ERROR] $1${NC}"; }
info() { echo -e "${BLUE}[INFO] $1${NC}"; }
debug() { echo -e "${PURPLE}[DEBUG] $1${NC}"; }

# Функция для поиска Java
find_java_home() {
    log "Поиск установки Java..." >&2
    local java_candidates=("$PREFIX/lib/jvm/java-17-openjdk" "$PREFIX/lib/jvm/java-21-openjdk" "$PREFIX/opt/openjdk")
    for candidate in "${java_candidates[@]}"; do
        if [ -d "$candidate" ] && [ -x "$candidate/bin/java" ]; then
            info "Найден рабочий Java: $candidate" >&2
            echo "$candidate"
            return 0
        fi
    done
    local java_bin=$(which java 2>/dev/null || echo "")
    if [ -n "$java_bin" ]; then
        local potential_java_home=$(dirname "$(dirname "$java_bin")")
        if [ -d "$potential_java_home" ] && [ -x "$potential_java_home/bin/java" ]; then
            info "Найден рабочий Java через which: $potential_java_home" >&2
            echo "$potential_java_home"
            return 0
        fi
    fi
    error "Java не найдена! Убедитесь что openjdk-17 установлен." >&2
    return 1
}

# Установка пакетов
install_packages() {
    log "Проверка и установка необходимых пакетов..."
    local packages="openjdk-17 gradle wget curl unzip git ffmpeg proot"
    pkg update -y >/dev/null 2>&1
    for package in $packages; do
        if ! dpkg -l 2>/dev/null | grep -q "^ii.*$package "; then
            log "Установка $package..."
            pkg install -y "$package"
        else
            info "$package уже установлен"
        fi
    done
}

# Настройка переменных среды
setup_environment() {
    log "Настройка переменных среды..."
    local java_home_path=$(find_java_home)
    [ $? -ne 0 ] && { error "Не удалось найти Java!"; exit 1; }
    
    export JAVA_HOME="$java_home_path"
    export ANDROID_SDK_ROOT="$HOME/AndroidBuild/android-sdk"
    export PATH="$PATH:$ANDROID_SDK_ROOT/platform-tools:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin"
    
    local bashrc_file="$HOME/.bashrc"
    touch "$bashrc_file"
    sed -i '/export JAVA_HOME=/d' "$bashrc_file"
    sed -i '/export ANDROID_SDK_ROOT=/d' "$bashrc_file"
    
    {
        echo ""
        echo "# Android Development Environment"
        echo "export JAVA_HOME=\"$java_home_path\""
        echo "export ANDROID_SDK_ROOT=\"$ANDROID_SDK_ROOT\""
        echo "export PATH=\"\$PATH:\$ANDROID_SDK_ROOT/platform-tools:\$ANDROID_SDK_ROOT/cmdline-tools/latest/bin\""
    } >> "$bashrc_file"
    
    log "Переменные среды настроены."
}

# Настройка Android SDK
setup_android_sdk() {
    log "Настройка Android SDK..."
    mkdir -p "$ANDROID_SDK_ROOT"
    cd "$ANDROID_SDK_ROOT"
    
    if [ ! -d "cmdline-tools/latest/bin" ]; then
        log "Скачивание Android Command Line Tools..."
        local sdk_url="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
        wget -O cmdline-tools.zip "$sdk_url"
        unzip -q cmdline-tools.zip
        mkdir -p cmdline-tools/latest
        mv cmdline-tools/* cmdline-tools/latest/ 2>/dev/null || true
        rm -f cmdline-tools.zip
    fi
    
    export PATH="$PATH:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin"
    log "Принятие лицензий Android SDK..."
    yes | sdkmanager --licenses >/dev/null 2>&1 || true
    
    local components=("platform-tools" "build-tools;34.0.0" "platforms;android-34")
    for component in "${components[@]}"; do
        log "Установка $component..."
        sdkmanager "$component"
    done
    log "✅ Android SDK настроен"
}

# Создание структуры каталогов проекта
create_android_project_structure() {
    log "Создание структуры каталогов проекта MySoundApp..."
    local project_dir="$HOME/MySoundApp"
    rm -rf "$project_dir"
    mkdir -p "$project_dir"
    
    local dirs=(
        "app/src/main/java/com/example/mysoundapp"
        "app/src/main/res/layout"
        "app/src/main/res/raw"
        "app/src/main/res/values"
        "app/src/main/res/xml"
        "app/src/main/res/mipmap-hdpi"
        "app/src/main/res/mipmap-mdpi"
    )
    for dir in "${dirs[@]}"; do
        mkdir -p "$project_dir/$dir"
    done

    # Подключаем скрипт с исходным кодом и создаем файлы
    source "$HOME/source.sh"
    create_project_files "$project_dir"

    log "Создание файла gradle.properties..."
    cat > "$project_dir/gradle.properties" << 'EOF'
android.useAndroidX=true
android.enableJetifier=true
android.suppressUnsupportedCompileSdk=34
EOF
}

# Настройка Gradle wrapper
setup_gradle_wrapper() {
    log "Настройка Gradle wrapper..."
    cd "$HOME/MySoundApp"
    if [ ! -f "gradlew" ]; then
        # Save original files
        mv build.gradle build.gradle.bak
        mv settings.gradle settings.gradle.bak
        
        # Create temporary empty files
        echo "" > build.gradle
        echo "" > settings.gradle
        
        gradle wrapper --gradle-version="8.2"
        
        # Restore original files
        mv build.gradle.bak build.gradle
        mv settings.gradle.bak settings.gradle
        
        chmod +x gradlew
    fi
}

# Сборка APK
build_apk() {
    log "Сборка APK..."
    cd "$HOME/MySoundApp"
    ./gradlew clean
    if ./gradlew assembleDebug --stacktrace; then
        local apk_path="$HOME/MySoundApp/app/build/outputs/apk/debug/app-debug.apk"
        echo "========================================="
        echo "🎉 УСПЕХ! APK успешно собран!"
        echo "📱 Путь к APK: $apk_path"
        echo "========================================="
        return 0
    else
        error "Не удалось собрать APK"
        return 1
    fi
}

# Главная функция
main() {
    echo "🚀 УМНЫЙ АВТОМАТИЧЕСКИЙ НАСТРОЙЩИК (СИСТЕМА СБОРКИ)"
    
    install_packages
    setup_environment
    setup_android_sdk
    create_android_project_structure
    setup_gradle_wrapper
    
    if build_apk; then
        log "🎊 ВСЕ ЗАДАЧИ ВЫПОЛНЕНЫ УСПЕШНО!"
    else
        error "❌ Сборка APK не удалась"
        exit 1
    fi
}

trap 'echo ""; error "Скрипт прерван"; exit 1' INT TERM
main "$@"
