#!/usr/bin/env python3
"""
Script 3: GitHub Actions Monitor
Каждые 15 секунд проверяет статус компиляции GitHub Actions
и отправляет ошибки на исправление
"""

import time
import json
import requests
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any
from github import Github, GithubException

class GitHubActionsMonitor:
    def __init__(self, token: str, repo_name: str = "lp85d/Android", 
                 check_interval: int = 15):
        """
        Инициализация монитора GitHub Actions
        
        Args:
            token: GitHub токен для аутентификации
            repo_name: Имя репозитория в формате "owner/repo"
            check_interval: Интервал проверки в секундах
        """
        self.token = token
        self.repo_name = repo_name
        self.check_interval = check_interval
        from github import Auth
        auth = Auth.Token(token)
        self.github = Github(auth=auth)
        self.repo = None
        self.last_check = None
        self.processed_runs = set()
        
        try:
            self.repo = self.github.get_repo(repo_name)
            print(f"✓ Подключение к репозиторию {repo_name} для мониторинга")
        except GithubException as e:
            print(f"❌ Ошибка подключения к репозиторию: {e}")
            raise

    def get_workflow_runs(self, limit: int = 10) -> List[Dict[str, Any]]:
        """
        Получает последние запуски workflow
        
        Args:
            limit: Количество последних запусков для получения
            
        Returns:
            Список запусков workflow
        """
        try:
            runs = []
            workflow_runs = self.repo.get_workflow_runs()
            
            count = 0
            for run in workflow_runs:
                if count >= limit:
                    break
                run_info = {
                    'id': run.id,
                    'name': getattr(run, 'name', 'Workflow'),
                    'status': run.status,  # queued, in_progress, completed
                    'conclusion': run.conclusion,  # success, failure, cancelled, etc.
                    'created_at': run.created_at,
                    'updated_at': run.updated_at,
                    'head_branch': run.head_branch,
                    'head_sha': run.head_sha,
                    'html_url': run.html_url,
                    'run_number': run.run_number,
                    'event': run.event
                }
                count += 1
                runs.append(run_info)
            
            return runs
            
        except GithubException as e:
            print(f"❌ Ошибка получения workflow runs: {e}")
            return []

    def get_workflow_jobs(self, run_id: int) -> List[Dict[str, Any]]:
        """
        Получает задачи (jobs) для конкретного запуска workflow
        
        Args:
            run_id: ID запуска workflow
            
        Returns:
            Список задач
        """
        try:
            jobs = []
            workflow_run = self.repo.get_workflow_run(run_id)
            
            for job in workflow_run.jobs():
                job_info = {
                    'id': job.id,
                    'name': job.name,
                    'status': job.status,
                    'conclusion': job.conclusion,
                    'started_at': job.started_at,
                    'completed_at': job.completed_at,
                    'html_url': job.html_url,
                    'run_url': job.run_url,
                    'steps': []
                }
                
                # Получение шагов
                for step in job.steps:
                    step_info = {
                        'name': step.name if hasattr(step, 'name') else step.get('name', 'Unknown'),
                        'status': step.status if hasattr(step, 'status') else step.get('status', 'unknown'),
                        'conclusion': step.conclusion if hasattr(step, 'conclusion') else step.get('conclusion', None),
                        'number': step.number if hasattr(step, 'number') else step.get('number', 0),
                        'started_at': step.started_at if hasattr(step, 'started_at') else step.get('started_at', None),
                        'completed_at': step.completed_at if hasattr(step, 'completed_at') else step.get('completed_at', None)
                    }
                    job_info['steps'].append(step_info)
                
                jobs.append(job_info)
            
            return jobs
            
        except GithubException as e:
            print(f"❌ Ошибка получения jobs для run {run_id}: {e}")
            return []

    def get_job_logs(self, job_id: int) -> str:
        """
        Получает логи для конкретной задачи
        
        Args:
            job_id: ID задачи
            
        Returns:
            Логи задачи
        """
        try:
            # Используем прямой API вызов для получения логов
            headers = {
                'Authorization': f'token {self.token}',
                'Accept': 'application/vnd.github.v3+json'
            }
            
            url = f"https://api.github.com/repos/{self.repo_name}/actions/jobs/{job_id}/logs"
            response = requests.get(url, headers=headers)
            
            if response.status_code == 200:
                return response.text
            else:
                print(f"❌ Ошибка получения логов для job {job_id}: {response.status_code}")
                return ""
                
        except Exception as e:
            print(f"❌ Ошибка получения логов: {e}")
            return ""

    def analyze_build_errors(self, logs: str) -> List[Dict[str, str]]:
        """
        Анализирует логи сборки и извлекает ошибки
        
        Args:
            logs: Логи сборки
            
        Returns:
            Список найденных ошибок
        """
        errors = []
        
        # Паттерны ошибок для Android проектов
        error_patterns = {
            'gradle_error': ['FAILURE: Build failed', 'Task failed', 'Build FAILED'],
            'compilation_error': ['error:', 'Error:', 'ERROR:', 'compilation failed'],
            'lint_error': ['Lint found errors', 'lint errors'],
            'test_error': ['Test failed', 'FAILED', 'AssertionError'],
            'dependency_error': ['Could not resolve', 'dependency', 'repository'],
            'manifest_error': ['AndroidManifest.xml', 'manifest merger failed'],
            'resource_error': ['resource', 'R.', 'not found', 'duplicate resource']
        }
        
        lines = logs.split('\n')
        
        for i, line in enumerate(lines):
            line_lower = line.lower()
            
            for error_type, patterns in error_patterns.items():
                if any(pattern.lower() in line_lower for pattern in patterns):
                    # Собираем контекст ошибки (несколько строк до и после)
                    context_start = max(0, i - 3)
                    context_end = min(len(lines), i + 3)
                    context = '\n'.join(lines[context_start:context_end])
                    
                    error_info = {
                        'type': error_type,
                        'line': line.strip(),
                        'context': context,
                        'line_number': i + 1
                    }
                    
                    errors.append(error_info)
                    break  # Избегаем дублирования одной строки
        
        return errors

    def format_error_report(self, run_info: Dict[str, Any], 
                           jobs: List[Dict[str, Any]], 
                           all_errors: List[Dict[str, str]]) -> str:
        """
        Форматирует отчет об ошибках для отправки
        
        Returns:
            Форматированный отчет
        """
        report = []
        report.append("🔥 ОБНАРУЖЕНЫ ОШИБКИ КОМПИЛЯЦИИ В GITHUB ACTIONS")
        report.append("="*60)
        report.append(f"Репозиторий: {self.repo_name}")
        report.append(f"Workflow: {run_info['name']}")
        report.append(f"Run #: {run_info['run_number']}")
        report.append(f"Ветка: {run_info['head_branch']}")
        report.append(f"Коммит: {run_info['head_sha'][:8]}")
        report.append(f"Статус: {run_info['status']} / {run_info['conclusion']}")
        report.append(f"Время: {run_info['updated_at']}")
        report.append(f"URL: {run_info['html_url']}")
        report.append("")
        
        # Группировка ошибок по типам
        errors_by_type = {}
        for error in all_errors:
            error_type = error['type']
            if error_type not in errors_by_type:
                errors_by_type[error_type] = []
            errors_by_type[error_type].append(error)
        
        # Вывод ошибок по типам
        for error_type, errors in errors_by_type.items():
            report.append(f"📋 {error_type.upper().replace('_', ' ')}:")
            report.append("-" * 40)
            
            for error in errors[:3]:  # Ограничиваем количество ошибок каждого типа
                report.append(f"Строка {error['line_number']}: {error['line']}")
                report.append("Контекст:")
                for context_line in error['context'].split('\n'):
                    if context_line.strip():
                        report.append(f"  {context_line}")
                report.append("")
        
        # Рекомендации по исправлению
        report.append("🔧 РЕКОМЕНДАЦИИ ПО ИСПРАВЛЕНИЮ:")
        report.append("-" * 40)
        
        recommendations = {
            'gradle_error': "Проверьте build.gradle файлы и зависимости",
            'compilation_error': "Исправьте синтаксические ошибки в коде Java/Kotlin",
            'lint_error': "Запустите './gradlew lint' и исправьте предупреждения",
            'test_error': "Исправьте упавшие тесты или обновите их",
            'dependency_error': "Проверьте версии зависимостей и репозитории",
            'manifest_error': "Проверьте AndroidManifest.xml на корректность",
            'resource_error': "Проверьте ресурсы в папках res/"
        }
        
        for error_type in errors_by_type.keys():
            if error_type in recommendations:
                report.append(f"• {recommendations[error_type]}")
        
        return "\n".join(report)

    def send_error_notification(self, error_report: str):
        """
        Отправляет уведомление об ошибке
        В данной реализации выводит в консоль
        
        Args:
            error_report: Отчет об ошибке
        """
        print("\n" + error_report)
        
        # Сохранение отчета в файл
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"error_report_{timestamp}.txt"
        
        with open(filename, 'w', encoding='utf-8') as f:
            f.write(error_report)
        
        print(f"\n📄 Отчет сохранен в файл: {filename}")

    def check_workflows(self):
        """Проверяет статус всех workflow"""
        print(f"🔍 Проверка workflow в {datetime.now().strftime('%H:%M:%S')}")
        
        runs = self.get_workflow_runs(5)  # Проверяем последние 5 запусков
        
        for run in runs:
            run_id = run['id']
            
            # Пропускаем уже обработанные запуски
            if run_id in self.processed_runs:
                continue
            
            # Проверяем только завершенные запуски с ошибками
            if run['status'] == 'completed' and run['conclusion'] in ['failure', 'cancelled']:
                print(f"❌ Обнаружен неудачный запуск: {run['name']} #{run['run_number']}")
                
                # Получаем задачи и их логи
                jobs = self.get_workflow_jobs(run_id)
                all_errors = []
                
                for job in jobs:
                    if job['conclusion'] in ['failure', 'cancelled']:
                        print(f"  📋 Анализируем задачу: {job['name']}")
                        logs = self.get_job_logs(job['id'])
                        
                        if logs:
                            errors = self.analyze_build_errors(logs)
                            all_errors.extend(errors)
                
                # Если найдены ошибки, отправляем отчет
                if all_errors:
                    error_report = self.format_error_report(run, jobs, all_errors)
                    self.send_error_notification(error_report)
                
                # Помечаем запуск как обработанный
                self.processed_runs.add(run_id)
                
            elif run['status'] == 'completed' and run['conclusion'] == 'success':
                # Успешные запуски тоже помечаем как обработанные
                if run_id not in self.processed_runs:
                    print(f"✅ Успешный запуск: {run['name']} #{run['run_number']}")
                    self.processed_runs.add(run_id)

    def run_monitor(self, max_consecutive_errors=5, smart_stop=True):
        """
        Запускает умный мониторинг GitHub Actions
        
        Args:
            max_consecutive_errors: Максимум последовательных ошибок перед остановкой
            smart_stop: Умная остановка при отсутствии новых сборок
        """
        print(f"🚀 Запуск умного мониторинга GitHub Actions")
        print(f"📊 Репозиторий: {self.repo_name}")
        print(f"⏱️ Интервал проверки: {self.check_interval} секунд")
        print(f"🧠 Умная остановка: {'включена' if smart_stop else 'отключена'}")
        print(f"⚠️ Остановка после {max_consecutive_errors} последовательных ошибок")
        print("Нажмите Ctrl+C для остановки\n")
        
        consecutive_errors = 0
        consecutive_no_activity = 0
        
        try:
            while True:
                runs = self.get_workflow_runs(3)  # Проверяем только последние 3
                
                if not runs:
                    consecutive_no_activity += 1
                    print(f"⏸️ Нет активных workflow runs ({consecutive_no_activity}/10)")
                    
                    if smart_stop and consecutive_no_activity >= 10:
                        print("🛑 Автоматическая остановка: нет активности более 10 проверок")
                        break
                    
                    time.sleep(self.check_interval)
                    continue
                
                # Проверяем только новые runs
                new_runs_found = False
                failed_runs_in_batch = 0
                
                for run in runs:
                    run_id = run['id']
                    
                    # Пропускаем уже обработанные
                    if run_id in self.processed_runs:
                        continue
                    
                    new_runs_found = True
                    
                    if run['status'] == 'completed':
                        if run['conclusion'] in ['failure', 'cancelled']:
                            print(f"❌ Новая ошибка: {run['name']} #{run['run_number']}")
                            failed_runs_in_batch += 1
                            
                            # Анализируем только новые ошибки
                            jobs = self.get_workflow_jobs(run_id)
                            all_errors = []
                            
                            for job in jobs:
                                if job['conclusion'] in ['failure', 'cancelled']:
                                    logs = self.get_job_logs(job['id'])
                                    if logs:
                                        errors = self.analyze_build_errors(logs)
                                        all_errors.extend(errors)
                            
                            if all_errors:
                                error_report = self.format_error_report(run, jobs, all_errors)
                                self.send_error_notification(error_report)
                            
                        elif run['conclusion'] == 'success':
                            print(f"✅ Успешная сборка: {run['name']} #{run['run_number']}")
                            consecutive_errors = 0  # Сбрасываем счетчик ошибок
                        
                        # Помечаем как обработанный
                        self.processed_runs.add(run_id)
                    
                    elif run['status'] in ['queued', 'in_progress']:
                        print(f"⏳ Выполняется: {run['name']} #{run['run_number']} ({run['status']})")
                
                # Логика остановки при множественных ошибках
                if failed_runs_in_batch > 0:
                    consecutive_errors += failed_runs_in_batch
                    print(f"⚠️ Последовательные ошибки: {consecutive_errors}/{max_consecutive_errors}")
                    
                    if consecutive_errors >= max_consecutive_errors:
                        print(f"\n🛑 АВТОМАТИЧЕСКАЯ ОСТАНОВКА!")
                        print(f"Обнаружено {consecutive_errors} последовательных ошибок сборки.")
                        print("Рекомендуется исправить проблемы перед перезапуском мониторинга.")
                        break
                
                # Сброс счетчика неактивности если есть новые runs
                if new_runs_found:
                    consecutive_no_activity = 0
                    print(f"📊 Проверено runs: {len(runs)}, новых: {sum(1 for r in runs if r['id'] not in self.processed_runs)}")
                else:
                    consecutive_no_activity += 1
                    print(f"⏸️ Нет новой активности ({consecutive_no_activity}/10)")
                    
                    if smart_stop and consecutive_no_activity >= 10:
                        print("🛑 Автоматическая остановка: нет новой активности более 10 проверок")
                        break
                
                # Умная пауза - больше времени если нет активности
                if consecutive_no_activity > 5:
                    sleep_time = self.check_interval * 2  # Удваиваем интервал
                else:
                    sleep_time = self.check_interval
                
                # Очистка старых обработанных запусков
                if len(self.processed_runs) > 100:
                    self.processed_runs = set(list(self.processed_runs)[-50:])
                    print("🧹 Очистка старых записей")
                
                time.sleep(sleep_time)
                
        except KeyboardInterrupt:
            print("\n🛑 Мониторинг остановлен пользователем")
        except Exception as e:
            print(f"\n❌ Критическая ошибка мониторинга: {e}")
        
        print(f"\n📈 Сессия завершена. Обработано runs: {len(self.processed_runs)}")
        if consecutive_errors > 0:
            print(f"⚠️ Последние ошибки требуют внимания!")

def main():
    """Основная функция для запуска монитора"""
    import sys
    import os
    
    # Получение токена
    token = os.getenv('GITHUB_TOKEN')
    if not token and len(sys.argv) > 1:
        token = sys.argv[1]
    
    if not token:
        print("❌ GitHub токен не найден!")
        print("Используйте: python github_actions_monitor.py <TOKEN>")
        print("Или установите переменную окружения GITHUB_TOKEN")
        return False
    
    # Интервал проверки
    interval = 15
    if len(sys.argv) > 2:
        try:
            interval = int(sys.argv[2])
        except ValueError:
            print("⚠️ Некорректный интервал, используется 15 секунд")
    
    try:
        monitor = GitHubActionsMonitor(token, check_interval=interval)
        monitor.run_monitor()
        return True
        
    except Exception as e:
        print(f"❌ Ошибка запуска монитора: {e}")
        return False

if __name__ == "__main__":
    success = main()
    exit(0 if success else 1)