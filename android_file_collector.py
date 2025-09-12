#!/usr/bin/env python3
"""
Script 1: Android File Collector
Собирает директории и файлы тестового Android приложения
"""

import os
import shutil
import json
from pathlib import Path
from typing import List, Dict, Set

class AndroidFileCollector:
    def __init__(self, source_path: str | None = None, output_path: str = "collected_android_files"):
        """
        Инициализация коллектора файлов Android проекта
        
        Args:
            source_path: Путь к исходному Android проекту
            output_path: Путь для сохранения собранных файлов
        """
        self.source_path = Path(source_path) if source_path else Path.cwd()
        self.output_path = Path(output_path)
        
        # Расширения файлов Android проекта
        self.android_extensions = {
            '.java', '.kt', '.xml', '.gradle', '.properties', 
            '.pro', '.json', '.md', '.txt', '.yml', '.yaml',
            '.png', '.jpg', '.jpeg', '.svg', '.webp', '.9.png'
        }
        
        # Важные файлы и директории Android проекта
        self.important_files = {
            'build.gradle', 'settings.gradle', 'gradle.properties',
            'local.properties', 'proguard-rules.pro', 'AndroidManifest.xml',
            'strings.xml', 'colors.xml', 'styles.xml', 'dimens.xml'
        }
        
        # Директории Android проекта
        self.android_dirs = {
            'app', 'src', 'main', 'java', 'kotlin', 'res', 'assets',
            'layout', 'values', 'drawable', 'mipmap', 'raw', 'menu',
            'color', 'anim', 'animator', 'interpolator', 'transition'
        }
        
        # Исключаемые директории
        self.exclude_dirs = {
            'build', '.gradle', '.idea', '.git', 'node_modules',
            'target', 'out', 'bin', 'gen', 'libs'
        }
        
        # Чувствительные файлы (НЕ загружать в публичный репозиторий!)
        self.sensitive_files = {
            'local.properties', 'keystore.properties', 'signing.properties',
            'google-services.json', 'firebase_options.dart', 'GoogleService-Info.plist',
            'key.jks', 'keystore.jks', 'release.keystore', 'debug.keystore',
            'api_keys.xml', 'secrets.xml', 'config.properties'
        }
        
        # Чувствительные расширения
        self.sensitive_extensions = {
            '.jks', '.keystore', '.p12', '.pem', '.key', '.crt', '.cer'
        }

    def is_android_project(self, path: Path) -> bool:
        """Проверяет, является ли директория Android проектом"""
        android_indicators = [
            path / 'build.gradle',
            path / 'settings.gradle',
            path / 'app' / 'build.gradle',
            path / 'app' / 'src' / 'main' / 'AndroidManifest.xml'
        ]
        return any(indicator.exists() for indicator in android_indicators)

    def should_include_file(self, file_path: Path) -> bool:
        """Определяет, должен ли файл быть включен в коллекцию"""
        # БЕЗОПАСНОСТЬ: Исключаем чувствительные файлы
        if file_path.name.lower() in self.sensitive_files:
            print(f"⚠️ ПРОПУЩЕН чувствительный файл: {file_path}")
            return False
        
        # БЕЗОПАСНОСТЬ: Исключаем чувствительные расширения
        if file_path.suffix.lower() in self.sensitive_extensions:
            print(f"⚠️ ПРОПУЩЕН файл с чувствительным расширением: {file_path}")
            return False
        
        # Проверка расширения
        if file_path.suffix.lower() in self.android_extensions:
            return True
        
        # Проверка важных файлов без расширения (но не чувствительных!)
        if file_path.name in self.important_files:
            return True
        
        # Исключение скрытых файлов (кроме важных)
        if file_path.name.startswith('.') and file_path.name not in {'.gitignore', '.gitattributes'}:
            return False
        
        return False

    def should_include_dir(self, dir_path: Path) -> bool:
        """Определяет, должна ли директория быть включена"""
        dir_name = dir_path.name.lower()
        
        # Исключение определенных директорий
        if dir_name in self.exclude_dirs:
            return False
        
        # Исключение скрытых директорий
        if dir_name.startswith('.') and dir_name not in {'.github'}:
            return False
        
        return True

    def collect_files(self) -> Dict[str, any]:
        """Собирает все файлы Android проекта"""
        print(f"Сканирование Android проекта: {self.source_path}")
        
        if not self.is_android_project(self.source_path):
            print("ВНИМАНИЕ: Указанная директория не похожа на Android проект")
        
        collected_files = []
        collected_dirs = []
        file_stats = {
            'total_files': 0,
            'total_size': 0,
            'file_types': {},
            'important_files_found': []
        }
        
        # Создание выходной директории
        self.output_path.mkdir(exist_ok=True)
        
        for root, dirs, files in os.walk(self.source_path):
            root_path = Path(root)
            
            # Фильтрация директорий
            dirs[:] = [d for d in dirs if self.should_include_dir(root_path / d)]
            
            # Добавление информации о директории
            relative_dir = root_path.relative_to(self.source_path)
            if str(relative_dir) != '.':
                collected_dirs.append({
                    'path': str(relative_dir),
                    'full_path': str(root_path),
                    'files_count': len([f for f in files if self.should_include_file(root_path / f)])
                })
            
            # Обработка файлов
            for file in files:
                file_path = root_path / file
                
                if self.should_include_file(file_path):
                    try:
                        file_size = file_path.stat().st_size
                        relative_path = file_path.relative_to(self.source_path)
                        
                        file_info = {
                            'name': file,
                            'relative_path': str(relative_path),
                            'full_path': str(file_path),
                            'size': file_size,
                            'extension': file_path.suffix.lower()
                        }
                        
                        collected_files.append(file_info)
                        
                        # Статистика
                        file_stats['total_files'] += 1
                        file_stats['total_size'] += file_size
                        
                        ext = file_path.suffix.lower() or 'no_extension'
                        file_stats['file_types'][ext] = file_stats['file_types'].get(ext, 0) + 1
                        
                        if file in self.important_files:
                            file_stats['important_files_found'].append(str(relative_path))
                        
                        # Копирование файла в выходную директорию
                        output_file_path = self.output_path / relative_path
                        output_file_path.parent.mkdir(parents=True, exist_ok=True)
                        shutil.copy2(file_path, output_file_path)
                        
                    except (OSError, PermissionError) as e:
                        print(f"Ошибка обработки файла {file_path}: {e}")
        
        # Создание отчета
        report = {
            'source_path': str(self.source_path),
            'collection_time': str(Path.cwd()),
            'statistics': file_stats,
            'directories': collected_dirs,
            'files': collected_files
        }
        
        # Сохранение отчета
        report_path = self.output_path / 'collection_report.json'
        with open(report_path, 'w', encoding='utf-8') as f:
            json.dump(report, f, ensure_ascii=False, indent=2)
        
        return report

    def print_summary(self, report: Dict[str, any]):
        """Выводит сводку по собранным файлам"""
        stats = report['statistics']
        
        print("\n" + "="*50)
        print("СВОДКА ПО СОБРАННЫМ ФАЙЛАМ")
        print("="*50)
        print(f"Источник: {report['source_path']}")
        print(f"Всего файлов: {stats['total_files']}")
        print(f"Общий размер: {stats['total_size'] / 1024:.2f} KB")
        print(f"Директорий: {len(report['directories'])}")
        
        print("\nТипы файлов:")
        for ext, count in sorted(stats['file_types'].items()):
            print(f"  {ext}: {count}")
        
        if stats['important_files_found']:
            print("\nНайдены важные файлы:")
            for file in stats['important_files_found']:
                print(f"  ✓ {file}")
        
        print(f"\nФайлы скопированы в: {self.output_path}")
        print(f"Отчет сохранен в: {self.output_path / 'collection_report.json'}")

def main():
    """Основная функция для запуска коллектора"""
    import sys
    
    source_path: str | None = sys.argv[1] if len(sys.argv) > 1 else None
    
    collector = AndroidFileCollector(source_path)
    
    try:
        report = collector.collect_files()
        collector.print_summary(report)
        
        print("\n✓ Сбор файлов Android проекта завершен успешно!")
        return True
        
    except Exception as e:
        print(f"❌ Ошибка при сборе файлов: {e}")
        return False

if __name__ == "__main__":
    success = main()
    exit(0 if success else 1)