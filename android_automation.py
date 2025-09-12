#!/usr/bin/env python3
"""
Главный скрипт для автоматизации Android разработки
Объединяет все три скрипта в единый интерфейс
"""

import os
import sys
import argparse
from pathlib import Path

def setup_environment():
    """Настройка окружения и проверка зависимостей"""
    try:
        import requests
        import github
        import git
        print("✓ Все зависимости установлены")
        return True
    except ImportError as e:
        print(f"❌ Отсутствует зависимость: {e}")
        print("Установите зависимости: pip install requests PyGithub gitpython")
        return False

def get_github_token():
    """Получает GitHub токен из переменных окружения или пользовательского ввода"""
    token = os.getenv('GITHUB_TOKEN')
    
    if not token:
        print("GitHub токен не найден в переменных окружения.")
        print("Получите токен по адресу: https://github.com/settings/tokens")
        token = input("Введите GitHub токен: ").strip()
    
    if not token:
        print("❌ GitHub токен обязателен для работы")
        return None
    
    # Маскируем токен в выводе
    masked_token = f"{token[:8]}...{token[-4:]}" if len(token) > 12 else "***"
    print(f"✓ Использован токен: {masked_token}")
    
    return token

def run_file_collector(source_path=None):
    """Запускает сборщик файлов Android проекта"""
    print("\n🔍 ЭТАП 1: Сбор файлов Android проекта")
    print("-" * 50)
    
    try:
        from android_file_collector import AndroidFileCollector
        
        collector = AndroidFileCollector(source_path)
        report = collector.collect_files()
        collector.print_summary(report)
        
        return True, "collected_android_files"
        
    except Exception as e:
        print(f"❌ Ошибка сбора файлов: {e}")
        return False, None

def run_github_uploader(token, source_dir):
    """Запускает загрузчик в GitHub"""
    print("\n📤 ЭТАП 2: Загрузка в GitHub")
    print("-" * 50)
    
    try:
        from github_uploader import GitHubUploader
        
        uploader = GitHubUploader(token)
        stats = uploader.sync_directory(Path(source_dir))
        
        print(f"\n✓ Синхронизация завершена:")
        print(f"  Загружено: {stats['uploaded']}")
        print(f"  Обновлено: {stats['updated']}")
        print(f"  Удалено: {stats['deleted']}")
        print(f"  Ошибок: {stats['errors']}")
        
        return stats['errors'] == 0
        
    except Exception as e:
        print(f"❌ Ошибка загрузки: {e}")
        return False

def run_monitor(token, interval=15):
    """Запускает мониторинг GitHub Actions"""
    print("\n👁️ ЭТАП 3: Мониторинг GitHub Actions")
    print("-" * 50)
    
    try:
        from github_actions_monitor import GitHubActionsMonitor
        
        monitor = GitHubActionsMonitor(token, check_interval=interval)
        monitor.run_monitor()
        
        return True
        
    except Exception as e:
        print(f"❌ Ошибка мониторинга: {e}")
        return False

def main():
    """Главная функция"""
    parser = argparse.ArgumentParser(
        description="Автоматизация Android разработки с GitHub"
    )
    
    parser.add_argument(
        '--mode', 
        choices=['collect', 'upload', 'monitor', 'full'],
        default='full',
        help="Режим работы (по умолчанию: full)"
    )
    
    parser.add_argument(
        '--source', 
        type=str,
        help="Путь к Android проекту (по умолчанию: текущая директория)"
    )
    
    parser.add_argument(
        '--token', 
        type=str,
        help="GitHub токен (или используйте переменную GITHUB_TOKEN)"
    )
    
    parser.add_argument(
        '--interval', 
        type=int, 
        default=15,
        help="Интервал мониторинга в секундах (по умолчанию: 15)"
    )
    
    args = parser.parse_args()
    
    # Баннер
    print("🤖 АВТОМАТИЗАЦИЯ ANDROID РАЗРАБОТКИ")
    print("=" * 50)
    print("1. Сборка файлов Android проекта")
    print("2. Синхронизация с GitHub")
    print("3. Мониторинг сборки")
    print("=" * 50)
    
    # Проверка зависимостей
    if not setup_environment():
        return False
    
    # Получение токена
    token = args.token or get_github_token()
    if not token:
        return False
    
    success = True
    
    # Выполнение в зависимости от режима
    if args.mode in ['collect', 'full']:
        success, collected_dir = run_file_collector(args.source)
        if not success:
            return False
    
    if args.mode in ['upload', 'full']:
        if args.mode == 'upload':
            collected_dir = args.source or "collected_android_files"
        
        if not Path(collected_dir).exists():
            print(f"❌ Директория не найдена: {collected_dir}")
            return False
        
        success = run_github_uploader(token, collected_dir)
        if not success:
            return False
    
    if args.mode in ['monitor', 'full']:
        if args.mode == 'full':
            print(f"\n⏱️ Мониторинг начнется через 10 секунд...")
            print("Нажмите Ctrl+C для пропуска мониторинга")
            
            try:
                import time
                time.sleep(10)
            except KeyboardInterrupt:
                print("\n⏩ Мониторинг пропущен")
                return True
        
        success = run_monitor(token, args.interval)
    
    if success:
        print("\n🎉 Все этапы завершены успешно!")
    else:
        print("\n❌ Обнаружены ошибки при выполнении")
    
    return success

if __name__ == "__main__":
    success = main()
    exit(0 if success else 1)