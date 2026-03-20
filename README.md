# Full-Stack Dev Box

Изолированная среда разработки в браузере: **VS Code + Claude Code + Java 21 + Node.js + Python + PostgreSQL + Redis**.

Один контейнер — полный стек для создания и тестирования сложных проектов: от Spring Boot приложений с миграциями БД до Python-скриптов подготовки данных.

---

## Что внутри

| Компонент | Версия | Описание |
|---|---|---|
| **VS Code** (code-server) | 4.x | IDE в браузере |
| **Claude Code** | latest | AI агент в терминале |
| **Java** (Eclipse Temurin) | 21 LTS | Spring Boot, Maven проекты |
| **Maven** | 3.x | Сборка, тесты, зависимости |
| **Node.js** | 22 LTS | JS/TS проекты, скрипты |
| **Python** | 3.10 | Данные, скрипты, тесты |
| **PostgreSQL** | 16 | Основная БД |
| **Redis** | 7 | Кэш, очереди задач |
| **Docker CLI** | latest | Управление контейнерами изнутри |
| **pgAdmin 4** | latest | Web UI для PostgreSQL (опционально) |
| **Redis Commander** | latest | Web UI для Redis (опционально) |

### Python-библиотеки

- **Данные:** pandas, numpy, matplotlib, seaborn
- **БД:** sqlalchemy, psycopg2-binary, redis, alembic
- **PDF/Office:** pypdf, pdfplumber, python-docx, python-pptx, openpyxl, reportlab
- **AI/MCP:** anthropic, mcp
- **Web:** requests, httpx, lxml
- **Тесты:** pytest, pytest-asyncio
- **Прочее:** pillow, playwright, pytesseract, cairosvg

### VS Code расширения

- Java Extension Pack (Language Support, Debugger, Maven, Test Runner)
- Spring Boot Tools
- GitLens + Git Graph
- Database Client (GUI для PostgreSQL прямо в IDE)
- REST Client (`.http` файлы)
- Python
- XML, YAML
- PDF Viewer, Excel Viewer, draw.io

### MCP серверы (для Claude Code)

| Сервер | Описание |
|---|---|
| `filesystem` | Прямой доступ к файлам workspace |
| `postgres` | SQL запросы к БД, автоматический контекст схемы |
| `sequential-thinking` | Декомпозиция сложных задач |
| `github` | PR, issues, код репозитория |

---

## Быстрый старт

### 1. Настроить окружение

```bash
cp .env.example .env
```

Открыть `.env` и заполнить:

```env
# Обязательно — выбрать один из вариантов:
ANTHROPIC_API_KEY=sk-ant-...   # API ключ (pay-per-use)
# или оставить пустым и войти через подписку (см. шаг 4)

PASSWORD=your-password         # пароль для входа в IDE
```

### 2. Запустить

```bash
# Основной стек (IDE + PostgreSQL + Redis)
docker compose up -d

# С pgAdmin и Redis Commander
docker compose --profile tools up -d
```

### 3. Открыть IDE

```
http://localhost:8080
```

Ввести пароль из `PASSWORD` в `.env` (по умолчанию: `devbox`).

### 4. Запустить Claude Code в терминале IDE

```bash
# Если задан ANTHROPIC_API_KEY — просто:
claude

# Если используешь подписку Claude Pro/Max/Team:
claude login
# Следовать инструкциям в браузере, затем:
claude
```

---

## Порты

| Сервис | Порт | URL |
|---|---|---|
| VS Code + Gateway | 8080 | http://localhost:8080 |
| File Browser | — | http://localhost:8080/files/ |
| Приложение (dev) | 8090 | http://localhost:8090 |
| Java Debug (JDWP) | 5005 | remote debug |
| PostgreSQL | 5432 | `postgresql://devuser:devpass@localhost:5432/devdb` |
| Redis | 6379 | `redis://:redispass@localhost:6379` |
| pgAdmin | 5050 | http://localhost:5050 (--profile tools) |
| Redis Commander | 8081 | http://localhost:8081 (--profile tools) |

Порты настраиваются в `.env` (переменные `PORT`, `APP_PORT`, `POSTGRES_PORT` и т.д.).

---

## Подключение к БД

**Из кода внутри контейнера:**
```
postgresql://devuser:devpass@postgres:5432/devdb
redis://:redispass@redis:6379
```

**Из Database Client в VS Code** или внешних инструментов:
```
host: localhost  port: 5432  user: devuser  pass: devpass  db: devdb
```

**Через psql в терминале IDE:**
```bash
psql $DATABASE_URL
```

---

## Миграции

### Flyway (Java/Spring Boot)
```bash
# Создать миграцию
touch src/main/resources/db/migration/V2__add_users_table.sql

# Применить при запуске Spring Boot или вручную через Maven плагин
mvn flyway:migrate
```

### Alembic (Python)
```bash
# Инициализация (один раз)
alembic init alembic

# Создать миграцию
alembic revision --autogenerate -m "add users table"

# Применить
alembic upgrade head

# Откатить
alembic downgrade -1
```

---

## Тесты

### Java (Maven)
```bash
# Все тесты
mvn test

# Конкретный класс
mvn test -Dtest=UserServiceTest

# С профилем (Testcontainers запустит PostgreSQL сам)
mvn test -Pintegration
```

### Python (pytest)
```bash
pytest
pytest tests/test_models.py -v
pytest --cov=src
```

---

## Управление данными

Все данные хранятся в Docker volumes и **переживают перезапуск** контейнеров:

| Volume | Содержимое |
|---|---|
| `workspace` | Файлы проекта |
| `maven-cache` | Скачанные Maven зависимости |
| `claude-config` | История и настройки Claude Code |
| `postgres-data` | Данные PostgreSQL |
| `redis-data` | Данные Redis |

```bash
# Остановить (данные сохранятся)
docker compose down

# Полная очистка (удалит все данные!)
docker compose down -v
```

---

## Пересборка образа

```bash
# После изменения Dockerfile или конфигов
docker compose build --no-cache
docker compose up -d
```

---

## Структура проекта

```
fullstack_dev/
├── Dockerfile                  # Образ: Ubuntu 22.04 + все инструменты
├── docker-compose.yml          # Сервисы: devbox, postgres, redis, pgadmin
├── entrypoint.sh               # Скрипт запуска контейнера
├── auth-gateway.py             # Портал авторизации (порт 8080)
├── login.html                  # Страница входа
├── claude-settings.json        # Разрешения Claude Code
├── mcp-settings.json           # MCP серверы
├── code-server-settings.json   # Настройки VS Code
├── init-db.sql                 # Начальная инициализация PostgreSQL
├── .env.example                # Шаблон переменных окружения
└── README.md
```
