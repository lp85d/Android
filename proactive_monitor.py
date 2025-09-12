#!/usr/bin/env python3
"""
Проактивный мониторинг GitHub Actions с автоматической реакцией на краши
"""

import os
import time
import json
from datetime import datetime, timedelta
from typing import Dict, List, Set, Any, Optional
import requests
from github import Github, GithubException

class ProactiveGitHubActionsMonitor:
    def __init__(self, token: str, repo_name: str, check_interval: int = 15):
        """Проактивный мониторинг с автоматической реакцией на краши"""
        self.token = token
        self.repo_name = repo_name
        self.check_interval = check_interval
        self.github = Github(token)
        self.repo = self.github.get_repo(repo_name)
        
        # Состояние для проактивных действий
        self.processed_runs: Set[int] = set()
        self.retried_runs: Set[int] = set()
        self.failure_streak: Dict[str, int] = {}  # sha -> count
        self.last_action_time = time.time()
        self.consecutive_failures = 0
        
        # Настройки автоматических действий
        self.MAX_RETRIES = 1
        self.MAX_FAILURE_STREAK = 3
        self.MAX_IDLE_MINUTES = 10
        self.CANCEL_THRESHOLD = 2
        
        print(f"🚀 Проактивный мониторинг {repo_name} запущен")

    def auto_retry_failed_run(self, run_id: int) -> bool:
        """Автоматически перезапускает упавшую сборку"""
        if run_id in self.retried_runs:
            return False
            
        try:
            url = f"https://api.github.com/repos/{self.repo_name}/actions/runs/{run_id}/rerun"
            headers = {"Authorization": f"token {self.token}", "Accept": "application/vnd.github.v3+json"}
            response = requests.post(url, headers=headers)
            
            if response.status_code == 201:
                self.retried_runs.add(run_id)
                print(f"🔄 АВТОМАТИЧЕСКИЙ RETRY: Run #{run_id} перезапущен")
                self.last_action_time = time.time()
                return True
            else:
                print(f"❌ Ошибка retry run #{run_id}: {response.status_code}")
                return False
        except Exception as e:
            print(f"❌ Ошибка при retry: {e}")
            return False

    def cancel_redundant_runs(self, head_sha: str) -> int:
        """Отменяет избыточные запуски для того же коммита"""
        canceled_count = 0
        try:
            runs = self.get_workflow_runs(limit=10)
            for run in runs:
                if (run['head_sha'] == head_sha and 
                    run['status'] in ['queued', 'in_progress'] and
                    run['id'] not in self.processed_runs):
                    
                    if self.cancel_run(run['id']):
                        canceled_count += 1
                        
        except Exception as e:
            print(f"❌ Ошибка отмены запусков: {e}")
            
        return canceled_count

    def cancel_run(self, run_id: int) -> bool:
        """Отменяет конкретный запуск"""
        try:
            url = f"https://api.github.com/repos/{self.repo_name}/actions/runs/{run_id}/cancel"
            headers = {"Authorization": f"token {self.token}", "Accept": "application/vnd.github.v3+json"}
            response = requests.post(url, headers=headers)
            
            if response.status_code == 202:
                print(f"🛑 АВТОМАТИЧЕСКАЯ ОТМЕНА: Run #{run_id} отменен")
                self.last_action_time = time.time()
                return True
            return False
        except Exception as e:
            print(f"❌ Ошибка отмены: {e}")
            return False

    def create_failure_issue(self, run: Dict, errors: List[Dict]) -> bool:
        """Создает GitHub issue для повторяющихся ошибок"""
        try:
            title = f"🚨 Критический краш сборки в {run['head_sha'][:8]}"
            
            error_summary = []
            for error in errors[:3]:  # Первые 3 ошибки
                error_summary.append(f"• **{error['type'].upper()}**: {error['message'][:100]}...")
            
            body = f"""
## 🔥 Автоматически обнаружен краш компиляции

**Коммит:** `{run['head_sha']}`  
**Ветка:** `{run['head_branch']}`  
**Run #:** {run['run_number']}  
**URL:** {run['html_url']}  

### Основные ошибки:
{chr(10).join(error_summary)}

### Рекомендуемые действия:
- [ ] Исправить ошибки компиляции Gradle
- [ ] Проверить зависимости в build.gradle
- [ ] Убедиться что все файлы проекта в репозитории

*Этот issue создан автоматически системой мониторинга.*
"""
            
            issue = self.repo.create_issue(
                title=title,
                body=body,
                labels=["ci", "compilation-failure", "automated"]
            )
            
            print(f"📋 АВТОМАТИЧЕСКИ СОЗДАН ISSUE: #{issue.number}")
            self.last_action_time = time.time()
            return True
            
        except Exception as e:
            print(f"❌ Ошибка создания issue: {e}")
            return False

    def get_workflow_runs(self, limit: int = 10) -> List[Dict[str, Any]]:
        """Получает workflow runs"""
        try:
            runs = []
            workflow_runs = self.repo.get_workflow_runs()
            
            count = 0
            for run in workflow_runs:
                if count >= limit:
                    break
                runs.append({
                    'id': run.id,
                    'name': getattr(run, 'name', 'Workflow'),
                    'status': run.status,
                    'conclusion': run.conclusion,
                    'head_branch': run.head_branch,
                    'head_sha': run.head_sha,
                    'html_url': run.html_url,
                    'run_number': run.run_number,
                    'created_at': run.created_at,
                    'event': run.event
                })
                count += 1
            
            return runs
            
        except Exception as e:
            print(f"❌ Ошибка получения runs: {e}")
            return []

    def analyze_failure(self, run_id: int) -> List[Dict]:
        """Быстрый анализ ошибки"""
        errors = []
        try:
            # Простой анализ - проверяем основные типы ошибок
            workflow_run = self.repo.get_workflow_run(run_id)
            
            for job in workflow_run.jobs():
                if job.conclusion == 'failure':
                    if 'gradle' in job.name.lower():
                        errors.append({
                            'type': 'compilation_error',
                            'message': 'Gradle build failure detected',
                            'job': job.name
                        })
                    else:
                        errors.append({
                            'type': 'general_error', 
                            'message': f'Job {job.name} failed',
                            'job': job.name
                        })
        except Exception as e:
            print(f"❌ Ошибка анализа: {e}")
            
        return errors

    def handle_failed_run(self, run: Dict) -> None:
        """Проактивно обрабатывает упавший запуск"""
        run_id = run['id']
        head_sha = run['head_sha']
        
        print(f"🔥 ОБНАРУЖЕН КРАШ: Run #{run['run_number']} ({head_sha[:8]})")
        
        # 1. Увеличиваем счетчик ошибок для этого коммита
        self.failure_streak[head_sha] = self.failure_streak.get(head_sha, 0) + 1
        self.consecutive_failures += 1
        
        # 2. Автоматический retry на первую ошибку
        if run_id not in self.retried_runs and self.failure_streak[head_sha] == 1:
            if self.auto_retry_failed_run(run_id):
                return  # Retry успешен, ждем результата
        
        # 3. При повторных ошибках - отменяем избыточные запуски
        if self.failure_streak[head_sha] >= self.CANCEL_THRESHOLD:
            canceled = self.cancel_redundant_runs(head_sha)
            if canceled > 0:
                print(f"🛑 Отменено {canceled} избыточных запусков")
        
        # 4. При критическом количестве ошибок - создаем issue
        if self.failure_streak[head_sha] >= self.MAX_FAILURE_STREAK:
            errors = self.analyze_failure(run_id)
            if errors:
                self.create_failure_issue(run, errors)
                print(f"⚠️ Критическая ситуация: {self.failure_streak[head_sha]} неудач для {head_sha[:8]}")

    def run_proactive_monitor(self) -> None:
        """Запускает проактивный мониторинг"""
        print(f"🧠 Проактивный режим: автоматический retry, отмена лишних запусков, создание issues")
        print(f"⏱️ Интервал: {self.check_interval}с, автостоп: {self.MAX_IDLE_MINUTES}мин")
        print("Ctrl+C для остановки\n")
        
        consecutive_no_activity = 0
        
        try:
            while True:
                start_time = time.time()
                runs = self.get_workflow_runs(limit=5)
                
                if not runs:
                    consecutive_no_activity += 1
                    print(f"⏸️ Нет workflow runs ({consecutive_no_activity}/20)")
                    if consecutive_no_activity >= 20:
                        print("🛑 Автостоп: нет активности 20 проверок")
                        break
                    time.sleep(self.check_interval)
                    continue
                
                new_activity = False
                
                for run in runs:
                    run_id = run['id']
                    
                    if run_id in self.processed_runs:
                        continue
                    
                    new_activity = True
                    self.processed_runs.add(run_id)
                    
                    if run['status'] == 'completed':
                        if run['conclusion'] in ['failure', 'cancelled']:
                            self.handle_failed_run(run)
                        elif run['conclusion'] == 'success':
                            # Сброс счетчиков при успехе
                            head_sha = run['head_sha']
                            if head_sha in self.failure_streak:
                                del self.failure_streak[head_sha]
                            self.consecutive_failures = 0
                            print(f"✅ Успешная сборка: Run #{run['run_number']} ({head_sha[:8]})")
                    
                    elif run['status'] in ['queued', 'in_progress']:
                        print(f"⏳ Выполняется: Run #{run['run_number']} ({run['status']})")
                
                # Сброс счетчика неактивности
                if new_activity:
                    consecutive_no_activity = 0
                else:
                    consecutive_no_activity += 1
                
                # Проверка на критическое количество ошибок
                if self.consecutive_failures >= 5:
                    print(f"🛑 КРИТИЧЕСКАЯ СИТУАЦИЯ: {self.consecutive_failures} последовательных ошибок")
                    print("Остановка мониторинга для предотвращения спама")
                    break
                
                # Watchdog - проверка зависания
                idle_time = time.time() - self.last_action_time
                if idle_time > self.MAX_IDLE_MINUTES * 60:
                    print(f"🛑 Watchdog: нет действий {idle_time//60:.0f} минут")
                    break
                
                # Очистка старых записей
                if len(self.processed_runs) > 100:
                    self.processed_runs = set(list(self.processed_runs)[-50:])
                
                time.sleep(self.check_interval)
                
        except KeyboardInterrupt:
            print("\n🛑 Остановлено пользователем")
        except Exception as e:
            print(f"\n❌ Критическая ошибка: {e}")
        
        print(f"\n📊 Сессия завершена:")
        print(f"• Обработано runs: {len(self.processed_runs)}")
        print(f"• Retry выполнено: {len(self.retried_runs)}")
        print(f"• Активные ошибки: {len(self.failure_streak)}")

def main():
    """Запуск проактивного мониторинга"""
    token = os.getenv('GITHUB_TOKEN')
    if not token:
        print("❌ Нет GITHUB_TOKEN в переменных окружения")
        return
    
    repo = "lp85d/Android"
    
    try:
        monitor = ProactiveGitHubActionsMonitor(token, repo)
        monitor.run_proactive_monitor()
    except Exception as e:
        print(f"❌ Ошибка запуска: {e}")

if __name__ == "__main__":
    main()