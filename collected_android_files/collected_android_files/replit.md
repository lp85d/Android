# Android GitHub Automation Project

## Overview
Этот проект содержит три Python скрипта для автоматизации Android разработки с GitHub:

1. **android_file_collector.py** - Собирает файлы Android проекта
2. **github_uploader.py** - Загружает файлы в GitHub репозиторий  
3. **github_actions_monitor.py** - Мониторит статус компиляции GitHub Actions

## Recent Changes (2025-09-12)
- ✅ Созданы три основных скрипта автоматизации
- ✅ Настроен GitHub токен через Replit Secrets (GITHUB_TOKEN)
- ✅ Создан главный скрипт android_automation.py для управления всеми компонентами
- ✅ Настроен workflow для непрерывного мониторинга GitHub Actions
- ✅ Система успешно обнаруживает ошибки компиляции и создает детальные отчеты

## User Preferences
- Язык интерфейса: Русский
- Целевой репозиторий: https://github.com/lp85d/Android
- Интервал мониторинга: 15 секунд (настраивается)
- Автоматическое сохранение отчетов об ошибках в файлы

## Project Architecture

### Файловая структура:
```
/
├── android_file_collector.py    # Сборщик файлов Android проекта
├── github_uploader.py           # Загрузчик в GitHub  
├── github_actions_monitor.py    # Монитор GitHub Actions
├── android_automation.py        # Главный управляющий скрипт
├── collected_android_files/     # Папка для собранных файлов
└── error_report_*.txt           # Отчеты об ошибках сборки
```

### Используемые зависимости:
- **requests** - HTTP запросы к GitHub API
- **PyGithub** - Python библиотека для работы с GitHub API
- **gitpython** - Работа с Git репозиториями

### Workflow Configuration:
- **Android GitHub Monitor** - Непрерывно работающий мониторинг GitHub Actions
- Статус: RUNNING
- Команда: `python github_actions_monitor.py`
- Интервал проверки: 15 секунд

## Ключевые особенности

### Скрипт 1: android_file_collector.py
- Автоматически определяет Android проекты по структуре файлов
- Собирает файлы: .java, .kt, .xml, .gradle, .properties и другие
- Исключает build директории и временные файлы
- Создает подробный JSON отчет о собранных файлах
- Копирует файлы в структурированную папку collected_android_files

### Скрипт 2: github_uploader.py  
- Синхронизирует локальные файлы с GitHub репозиторием lp85d/Android
- Создает новые файлы и обновляет существующие
- Удаляет файлы, которых нет локально (кроме системных)
- Использует GitHub API для безопасной загрузки
- Выводит подробную статистику загрузки

### Скрипт 3: github_actions_monitor.py
- Проверяет статус GitHub Actions каждые 15 секунд
- Анализирует логи сборки и выявляет типы ошибок:
  - gradle_error - ошибки Gradle сборки
  - compilation_error - ошибки компиляции Java/Kotlin 
  - dependency_error - проблемы с зависимостями
  - manifest_error - ошибки AndroidManifest.xml
  - resource_error - проблемы с ресурсами
- Создает детальные отчеты с контекстом и рекомендациями
- Сохраняет отчеты в файлы error_report_YYYYMMDD_HHMMSS.txt

## Использование

### Запуск отдельных скриптов:
```bash
# Сбор файлов Android проекта
python android_file_collector.py [путь_к_проекту]

# Загрузка в GitHub (требует GITHUB_TOKEN)
python github_uploader.py [путь_к_файлам]

# Мониторинг GitHub Actions (работает непрерывно)
python github_actions_monitor.py
```

### Запуск через главный скрипт:
```bash
# Полный цикл: сбор + загрузка + мониторинг
python android_automation.py --mode full

# Только сбор файлов
python android_automation.py --mode collect --source /path/to/android/project

# Только загрузка
python android_automation.py --mode upload --source collected_android_files

# Только мониторинг
python android_automation.py --mode monitor --interval 30
```

## Статус системы
- ✅ Все скрипты созданы и протестированы
- ✅ GitHub токен настроен через Replit Secrets
- ✅ **ПРОАКТИВНЫЙ МОНИТОРИНГ АКТИВЕН** - автоматически реагирует на краши
- ✅ Система успешно обнаруживает ошибки сборки GitHub Actions
- ✅ **АВТОМАТИЧЕСКИЙ RETRY** - перезапускает упавшие сборки
- ✅ **УМНАЯ ОСТАНОВКА** - предотвращает зависание и спам запросов

## Текущие возможности мониторинга
Система обнаруживает и анализирует следующие типы ошибок:
- Ошибки синтаксиса в градле файлах (например: "./gradlew: 1: Syntax error: "|" unexpected")
- Проблемы с кэшированием Gradle 
- Ошибки загрузки зависимостей
- Проблемы с GitHub Actions кэшем

## Примечания
- GitHub интеграция через Replit была отклонена пользователем, используется прямая работа с API через токен
- Система работает с репозиторием lp85d/Android
- Логи и отчеты автоматически сохраняются для анализа