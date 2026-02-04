# Второй экземпляр OpenClaw (Claud Server)

Отдельный инстанс OpenClaw: только шлюз и каналы (Telegram), без macOS-ноды. Готов к деплою на Railway 24/7.

Первый бот у вас локально на Mac (~/.openclaw, порт 18789) — этот репозиторий с ним не смешивается.

---

## 1. Структура проекта

```
.
├── package.json       # Node 22+, зависимость openclaw, скрипт start
├── railway.toml       # Railway: build, startCommand, healthcheck
├── Dockerfile         # Опционально: деплой через Docker
├── start.sh           # Скрипт старта шлюза (port из PORT)
├── .env.example       # Перечень переменных окружения
├── .gitignore
└── README.md
```

- **Сборка**: Nixpacks (по умолчанию) или Docker по `Dockerfile`.
- **Старт**: `openclaw gateway --port $PORT --bind lan --allow-unconfigured`.

---

## 2. Переменные окружения для Railway

Задайте в **Railway → Service → Variables** (или в `.env` локально):

| Переменная | Обязательность | Описание |
|------------|----------------|----------|
| `PORT` | задаётся Railway | Порт HTTP/WS. При деплое через Docker добавь вручную `PORT=8080`, если в логах «Invalid port». |
| `OPENCLAW_STATE_DIR` | рекомендуется | Каталог состояния (конфиг, сессии). На Railway: `/data/.openclaw`. |
| `OPENCLAW_WORKSPACE_DIR` | рекомендуется | Workspace агента. На Railway: `/data/workspace`. |
| `OPENCLAW_GATEWAY_TOKEN` | рекомендуется | Секрет для доступа к Control UI / WebChat. |
| `SETUP_PASSWORD` | для первого запуска | Пароль для веб-мастера настройки `/setup`. |
| `OPENAI_API_KEY` | для моделей OpenAI | Ключ OpenAI (или настройте в `/setup`). |
| `TELEGRAM_BOT_TOKEN` | для Telegram | Токен второго бота от @BotFather (формат `123456:AA...`). |

Опционально: `OPENCLAW_CONFIG_PATH`, `DISCORD_BOT_TOKEN`, `SLACK_BOT_TOKEN`, `SLACK_APP_TOKEN` — по необходимости.

---

## 3. Инициализация (один раз)

Два варианта.

### Вариант A: Инициализация на Railway (рекомендуется)

1. Задеплойте проект на Railway (см. раздел 5).
2. Подключите **Volume** с путём монтирования `/data`.
3. Задайте переменные (минимум `SETUP_PASSWORD`, при желании `OPENCLAW_GATEWAY_TOKEN`, `TELEGRAM_BOT_TOKEN`, `OPENAI_API_KEY`).
4. Откройте в браузере: `https://<ваш-домен-railway>/setup`.
5. Введите `SETUP_PASSWORD`, пройдите мастер: модель/провайдер, при необходимости Telegram/Discord и т.д. Конфиг сохранится в `/data/.openclaw`.

Дальше шлюз будет подниматься уже с готовой конфигурацией.

### Вариант B: Локально в этой папке

Чтобы один раз сгенерировать конфиг и потом перенести его на сервер:

```bash
# В корне этого репозитория
export OPENCLAW_STATE_DIR="$PWD/data/.openclaw"
export OPENCLAW_WORKSPACE_DIR="$PWD/data/workspace"
npm install
npx openclaw onboard
```

После онбординга в `data/.openclaw` появятся конфиг и данные. Для Railway этот каталог нужно либо положить на volume `/data`, либо повторить настройку через `/setup` на сервере (вариант A проще).

---

## 4. Команда запуска шлюза в продакшене

На Railway используется одна из форм:

```bash
openclaw gateway --port ${PORT:-8080} --bind lan --allow-unconfigured
```

- `PORT` задаётся Railway автоматически.
- `--bind lan` — слушать на всех интерфейсах (для контейнера/сервера).
- `--allow-unconfigured` — разрешает старт до завершения онбординга (настройка через `/setup`).

В этом репозитории то же самое задаётся в `package.json` (скрипт `start`) и в `railway.toml` (`startCommand`). При использовании Docker — в `Dockerfile` (CMD).

---

## 5. Деплой на Railway

1. **Репозиторий**: залейте этот проект в GitHub (или подключите текущую папку к Railway).

2. **Новый сервис**: Railway → New Project → Deploy from GitHub repo → выберите репозиторий.

3. **Volume (обязательно для персистентности)**  
   - Service → Volumes → Add Volume.  
   - Mount path: `/data`.

4. **Переменные**  
   В Service → Variables добавьте (значения подставьте свои):
   - `PORT=8080` (часто уже есть)
   - `OPENCLAW_STATE_DIR=/data/.openclaw`
   - `OPENCLAW_WORKSPACE_DIR=/data/workspace`
   - `OPENCLAW_GATEWAY_TOKEN=<случайный-секрет>`
   - `SETUP_PASSWORD=<пароль-для-/setup>`
   - `OPENAI_API_KEY=<ваш-openai-ключ>`
   - `TELEGRAM_BOT_TOKEN=<токен-второго-бота-от-BotFather>`

5. **Сеть**: Settings → Networking → Enable HTTP Proxy, порт **8080** (или тот, что в `PORT`).

6. **Деплой**: после пуша Railway соберёт проект (Nixpacks) и запустит `start` из `package.json`. Если хотите использовать образ Docker — в настройках сервиса укажите сборку через Dockerfile.

7. **Первый запуск**: откройте `https://<ваш-домен>/setup`, введите `SETUP_PASSWORD` и завершите настройку (модель, Telegram и т.д.).

Дальше шлюз и Telegram-бот работают 24/7; конфиг и состояние хранятся в volume `/data`.

---

## Локальный запуск (тест)

```bash
cp .env.example .env
# Отредактируйте .env (минимум OPENCLAW_STATE_DIR на локальный путь, при желании TELEGRAM_BOT_TOKEN и т.д.)

export OPENCLAW_STATE_DIR="${OPENCLAW_STATE_DIR:-$PWD/data/.openclaw}"
export OPENCLAW_WORKSPACE_DIR="${OPENCLAW_WORKSPACE_DIR:-$PWD/data/workspace}"
npm install
npm start
```

Шлюз будет на `http://127.0.0.1:8080` (или на порту из `PORT`). Control UI: `http://127.0.0.1:8080/`, настройка: `http://127.0.0.1:8080/setup`.

---

## Устранение неполадок

### Control UI: «disconnected (1008): pairing required» / «Proxy headers from untrusted address»

За Railway трафик идёт через прокси; шлюз по умолчанию не доверяет таким заголовкам и требует pairing. В образе при старте в конфиг автоматически добавляется **gateway.trustedProxies** (если его ещё нет), после чего подключение по токену должно проходить без pairing.

Сделай **Redeploy** и снова открой UI, введя токен. Если ошибка останется — проверь в логах, что конфиг не перезаписывается; при необходимости добавь в `openclaw.json` (в volume `/data/.openclaw/`) вручную: `"gateway": { "trustedProxies": ["0.0.0.0/0"] }`.
