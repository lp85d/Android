#!/usr/bin/env python3
"""
Script 2: GitHub Repository Updater
Отправляет и заменяет файлы на GitHub https://github.com/lp85d/Android
"""

import os
import json
import base64
from pathlib import Path
from typing import Dict, List, Optional
from github import Github, GithubException
import requests

class GitHubUploader:
    def __init__(self, token: str, repo_name: str = "lp85d/Android"):
        """
        Инициализация загрузчика GitHub
        
        Args:
            token: GitHub токен для аутентификации
            repo_name: Имя репозитория в формате "owner/repo"
        """
        self.token = token
        self.repo_name = repo_name
        self.github = Github(token)
        self.repo = None
        
        try:
            self.repo = self.github.get_repo(repo_name)
            print(f"✓ Подключение к репозиторию {repo_name} успешно")
        except GithubException as e:
            print(f"❌ Ошибка подключения к репозиторию: {e}")
            raise

    def get_repository_info(self) -> Dict[str, any]:
        """Получает информацию о репозитории"""
        try:
            return {
                'name': self.repo.name,
                'full_name': self.repo.full_name,
                'description': self.repo.description,
                'default_branch': self.repo.default_branch,
                'size': self.repo.size,
                'language': self.repo.language,
                'private': self.repo.private,
                'updated_at': self.repo.updated_at.isoformat(),
                'clone_url': self.repo.clone_url
            }
        except GithubException as e:
            print(f"❌ Ошибка получения информации о репозитории: {e}")
            return {}

    def get_existing_files(self, branch: str = None) -> Dict[str, str]:
        """
        Получает список существующих файлов в репозитории
        
        Returns:
            Dict с путями файлов и их SHA
        """
        if not branch:
            branch = self.repo.default_branch
        
        existing_files = {}
        
        try:
            contents = self.repo.get_contents("", ref=branch)
            
            def process_contents(contents_list):
                for content in contents_list:
                    if content.type == "file":
                        existing_files[content.path] = content.sha
                    elif content.type == "dir":
                        # Рекурсивно обработать содержимое директории
                        dir_contents = self.repo.get_contents(content.path, ref=branch)
                        process_contents(dir_contents)
            
            process_contents(contents)
            
        except GithubException as e:
            print(f"⚠️ Ошибка получения файлов репозитория: {e}")
        
        return existing_files

    def upload_file(self, local_path: Path, repo_path: str, 
                   commit_message: str = None, branch: str = None) -> bool:
        """
        Загружает или обновляет файл в репозитории
        
        Args:
            local_path: Локальный путь к файлу
            repo_path: Путь в репозитории
            commit_message: Сообщение коммита
            branch: Ветка для загрузки
            
        Returns:
            True если загрузка успешна
        """
        if not branch:
            branch = self.repo.default_branch
        
        if not commit_message:
            commit_message = f"Update {repo_path}"
        
        try:
            # Определяем тип файла и читаем содержимое
            is_binary = self._is_binary_file(local_path)
            
            if is_binary:
                # Для бинарных файлов используем base64
                with open(local_path, 'rb') as f:
                    content_bytes = f.read()
                content = base64.b64encode(content_bytes).decode('utf-8')
            else:
                # Для текстовых файлов читаем как UTF-8
                try:
                    with open(local_path, 'r', encoding='utf-8') as f:
                        content = f.read()
                except UnicodeDecodeError:
                    # Если не UTF-8, попробуем как бинарный
                    with open(local_path, 'rb') as f:
                        content_bytes = f.read()
                    content = base64.b64encode(content_bytes).decode('utf-8')
                    is_binary = True
            
            # Проверка существования файла
            try:
                existing_file = self.repo.get_contents(repo_path, ref=branch)
                # Файл существует - обновляем
                if is_binary:
                    self.repo.update_file(
                        repo_path,
                        commit_message,
                        content,
                        existing_file.sha,
                        branch=branch
                    )
                else:
                    self.repo.update_file(
                        repo_path,
                        commit_message,
                        content,
                        existing_file.sha,
                        branch=branch
                    )
                print(f"📝 Обновлен: {repo_path}")
                
            except GithubException as e:
                if e.status == 404:
                    # Файл не существует - создаем новый
                    self.repo.create_file(
                        repo_path,
                        commit_message,
                        content,
                        branch=branch
                    )
                    print(f"➕ Создан: {repo_path}")
                else:
                    raise e
            
            return True
            
        except Exception as e:
            print(f"❌ Ошибка загрузки {repo_path}: {e}")
            return False

    def _is_binary_file(self, file_path: Path) -> bool:
        """
        Определяет, является ли файл бинарным
        
        Args:
            file_path: Путь к файлу
            
        Returns:
            True если файл бинарный
        """
        # Бинарные расширения
        binary_extensions = {
            '.png', '.jpg', '.jpeg', '.gif', '.bmp', '.ico', '.svg',
            '.mp3', '.mp4', '.avi', '.mov', '.wav', '.ogg',
            '.zip', '.rar', '.7z', '.tar', '.gz',
            '.pdf', '.doc', '.docx', '.xls', '.xlsx',
            '.apk', '.aar', '.jar', '.class',
            '.so', '.dll', '.exe', '.bin',
            '.jks', '.keystore', '.p12'
        }
        
        if file_path.suffix.lower() in binary_extensions:
            return True
        
        # Проверяем первые байты файла
        try:
            with open(file_path, 'rb') as f:
                chunk = f.read(1024)
            
            # Если есть нулевые байты, скорее всего бинарный
            if b'\x00' in chunk:
                return True
            
            # Пытаемся декодировать как UTF-8
            try:
                chunk.decode('utf-8')
                return False
            except UnicodeDecodeError:
                return True
                
        except Exception:
            return True  # По умолчанию считаем бинарным при ошибке

    def delete_file(self, repo_path: str, commit_message: str = None, 
                   branch: str = None) -> bool:
        """
        Удаляет файл из репозитория
        
        Args:
            repo_path: Путь к файлу в репозитории
            commit_message: Сообщение коммита
            branch: Ветка
            
        Returns:
            True если удаление успешно
        """
        if not branch:
            branch = self.repo.default_branch
        
        if not commit_message:
            commit_message = f"Delete {repo_path}"
        
        try:
            file = self.repo.get_contents(repo_path, ref=branch)
            self.repo.delete_file(repo_path, commit_message, file.sha, branch=branch)
            print(f"🗑️ Удален: {repo_path}")
            return True
            
        except GithubException as e:
            print(f"❌ Ошибка удаления {repo_path}: {e}")
            return False

    def sync_directory(self, local_dir: Path, exclude_patterns: List[str] = None) -> Dict[str, any]:
        """
        Синхронизирует локальную директорию с репозиторием
        
        Args:
            local_dir: Локальная директория для синхронизации
            exclude_patterns: Паттерны файлов для исключения
            
        Returns:
            Отчет о синхронизации
        """
        if exclude_patterns is None:
            exclude_patterns = ['.git', '__pycache__', '*.pyc', '.DS_Store']
        
        print(f"🔄 Начало синхронизации: {local_dir}")
        
        # Получаем существующие файлы
        existing_files = self.get_existing_files()
        
        # Статистика
        stats = {
            'uploaded': 0,
            'updated': 0,
            'deleted': 0,
            'errors': 0,
            'total_files': 0
        }
        
        uploaded_files = set()
        
        # Загрузка локальных файлов
        for root, dirs, files in os.walk(local_dir):
            # Исключаем определенные директории
            dirs[:] = [d for d in dirs if not any(d.startswith(pattern.rstrip('*')) 
                                                  for pattern in exclude_patterns)]
            
            for file in files:
                local_file_path = Path(root) / file
                relative_path = local_file_path.relative_to(local_dir)
                repo_path = str(relative_path).replace('\\', '/')
                
                # Проверка паттернов исключения
                if any(relative_path.match(pattern) for pattern in exclude_patterns):
                    continue
                
                stats['total_files'] += 1
                uploaded_files.add(repo_path)
                
                commit_msg = f"Sync: {repo_path}"
                
                if self.upload_file(local_file_path, repo_path, commit_msg):
                    if repo_path in existing_files:
                        stats['updated'] += 1
                    else:
                        stats['uploaded'] += 1
                else:
                    stats['errors'] += 1
        
        # Удаление файлов, которых нет локально
        files_to_delete = set(existing_files.keys()) - uploaded_files
        
        for repo_path in files_to_delete:
            # Не удаляем специальные файлы GitHub
            if repo_path in ['.gitignore', 'README.md', 'LICENSE']:
                continue
                
            if self.delete_file(repo_path, f"Remove obsolete file: {repo_path}"):
                stats['deleted'] += 1
            else:
                stats['errors'] += 1
        
        return stats

    def create_release(self, tag_name: str, name: str = None, 
                      body: str = None, draft: bool = False) -> bool:
        """
        Создает релиз в репозитории
        
        Args:
            tag_name: Имя тега
            name: Название релиза
            body: Описание релиза
            draft: Черновик релиза
            
        Returns:
            True если релиз создан успешно
        """
        try:
            release = self.repo.create_git_release(
                tag=tag_name,
                name=name or tag_name,
                message=body or f"Release {tag_name}",
                draft=draft
            )
            print(f"🎉 Создан релиз: {release.title}")
            return True
            
        except GithubException as e:
            print(f"❌ Ошибка создания релиза: {e}")
            return False

def main():
    """Основная функция для запуска загрузчика"""
    import sys
    
    # Получение токена из переменных окружения или аргументов
    token = os.getenv('GITHUB_TOKEN')
    if not token and len(sys.argv) > 1:
        token = sys.argv[1]
    
    if not token:
        print("❌ GitHub токен не найден!")
        print("Используйте: python github_uploader.py <TOKEN>")
        print("Или установите переменную окружения GITHUB_TOKEN")
        return False
    
    # Путь к директории для загрузки
    source_dir = Path(sys.argv[2]) if len(sys.argv) > 2 else Path("collected_android_files")
    
    if not source_dir.exists():
        print(f"❌ Директория не найдена: {source_dir}")
        return False
    
    try:
        # Создание загрузчика
        uploader = GitHubUploader(token)
        
        # Информация о репозитории
        repo_info = uploader.get_repository_info()
        print(f"📊 Репозиторий: {repo_info.get('full_name', 'Неизвестно')}")
        print(f"📊 Язык: {repo_info.get('language', 'Неизвестно')}")
        print(f"📊 Размер: {repo_info.get('size', 0)} KB")
        
        # Синхронизация
        stats = uploader.sync_directory(source_dir)
        
        # Вывод статистики
        print("\n" + "="*50)
        print("РЕЗУЛЬТАТ СИНХРОНИЗАЦИИ")
        print("="*50)
        print(f"Всего файлов обработано: {stats['total_files']}")
        print(f"Загружено новых: {stats['uploaded']}")
        print(f"Обновлено: {stats['updated']}")
        print(f"Удалено: {stats['deleted']}")
        print(f"Ошибок: {stats['errors']}")
        
        if stats['errors'] == 0:
            print("\n✓ Синхронизация завершена успешно!")
        else:
            print(f"\n⚠️ Синхронизация завершена с {stats['errors']} ошибками")
        
        return stats['errors'] == 0
        
    except Exception as e:
        print(f"❌ Критическая ошибка: {e}")
        return False

if __name__ == "__main__":
    success = main()
    exit(0 if success else 1)