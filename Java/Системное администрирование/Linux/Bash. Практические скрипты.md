# Bash. Практические скрипты

Шесть скриптов, которые чаще всего просят написать на собеседовании и которые реально нужны в работе. Для каждого — назначение, код, разбор ключевых строк и запуск по cron.

## 1. Бэкап каталога с ротацией

Архивирует каталог в `tar.gz` с датой в имени и удаляет копии старше `KEEP` дней.

```bash
#!/usr/bin/env bash
set -euo pipefail
SRC=/srv/data; DST=/backup; KEEP=7
mkdir -p "$DST"
NAME="$(basename "$SRC")-$(date +%F_%H-%M).tar.gz"
tar -czf "$DST/$NAME" -C "$(dirname "$SRC")" "$(basename "$SRC")"
find "$DST" -maxdepth 1 -name '*.tar.gz' -mtime +"$KEEP" -delete
echo "$(date '+%F %T') backup ok: $NAME" >> /var/log/backup.log
```

`-C` меняет каталог перед упаковкой, поэтому в архиве относительные пути; `-mtime +7` — «старше 7 суток»; при `set -e` упавший `tar` не даст записать «ok». Cron: `0 2 * * * /opt/backup.sh >> /var/log/backup.log 2>&1`.

## 2. Мониторинг свободного места

Проверяет заполнение всех локальных ФС и печатает алерт при превышении порога.

```bash
#!/usr/bin/env bash
set -euo pipefail
THRESHOLD=85
df -P -x tmpfs -x devtmpfs | awk -v t="$THRESHOLD" '
  NR > 1 { sub("%", "", $5); if ($5 + 0 >= t) printf "ALERT %s %s%% used, %s free\n", $6, $5, $4 }'
```

`-P` — POSIX-формат в одну строку (удобно парсить), `-x` исключает псевдо-ФС, `NR>1` пропускает заголовок, `$5` — процент, `$4` — доступно. Cron: `*/10 * * * * /opt/check_disk.sh | logger -t diskcheck`.

## 3. Проверка доступности сервиса

Дёргает URL через `curl`, делает три попытки и возвращает код выхода для мониторинга.

```bash
#!/usr/bin/env bash
set -uo pipefail
URL="${1:?usage: $0 URL}"
for i in 1 2 3; do
  if curl -sf -m 5 -o /dev/null "$URL"; then
    echo "OK: $URL (try $i)"; exit 0
  fi
  echo "FAIL: $URL (try $i)" >&2; sleep $((i * 5))
done
exit 1
```

`-s` — без прогресса, `-f` — HTTP >= 400 даёт ненулевой код, `-m 5` — таймаут, `-o /dev/null` — тело не нужно. `set -e` намеренно не включён: иначе цикл умрёт на первой неудаче. Cron: `*/5 * * * * /opt/check_url.sh https://intranet/ || logger -t http "service down"`.

## 4. Очистка старых логов

Удаляет `.log` и `.gz` старше 30 дней и пишет в лог, что именно удалено.

```bash
#!/usr/bin/env bash
set -euo pipefail
DIR=/var/log/app; DAYS=30
find "$DIR" -type f \( -name '*.log' -o -name '*.gz' \) -mtime +"$DAYS" -print -delete
echo "$(date '+%F %T') cleaned $DIR older than $DAYS d" >> /var/log/cleanup.log
```

`-print -delete` печатает каждый удалённый файл (аудит); `-mtime +30` — старше 30 суток. Обычно ротацию делает `logrotate`, скрипт нужен, когда правила не подходят. Cron: `30 4 * * * /opt/cleanup_logs.sh`.

## 5. Создание пользователей из CSV

Читает `login,group,shell` и создаёт пользователей, пропуская уже существующих.

```bash
#!/usr/bin/env bash
set -euo pipefail
CSV="${1:?usage: $0 users.csv}"
while IFS=, read -r login group shell; do
  [[ -z "$login" || "$login" == \#* ]] && continue
  if id "$login" &>/dev/null; then echo "skip: $login"; continue; fi
  useradd -m -s "${shell:-/bin/bash}" -G "${group:-users}" "$login"
  echo "created: $login"
done < "$CSV"
```

`IFS=,` разбирает CSV, `read -r` не съедает обратные слэши, проверка `id` даёт идемпотентность, `${shell:-...}` — значение по умолчанию. Пароль отдельно: `echo "user:pass" | chpasswd`, затем `passwd -e user`. Запуск вручную или из Ansible, не из cron.

## 6. Топ-10 IP из access-лога

Считает частоту обращений по первому полю лога и выводит десять самых активных адресов.

```bash
#!/usr/bin/env bash
set -euo pipefail
LOG="${1:?usage: $0 access.log}"
awk '{ ip[$1]++ } END { for (i in ip) print ip[i], i }' "$LOG" | sort -rn | head -10
```

`awk` копит счётчики в ассоциативном массиве, `sort -rn` сортирует как числа по убыванию (лексикографический `sort -r` поставил бы 9 выше 100), `head -10` обрезает. Эквивалент: `awk '{print $1}' log | sort | uniq -c | sort -rn | head`.

## Чек-лист диагностики

1. Сформулировать вход/выход: аргументы, пути, что считается успехом.
2. Прогнать `bash -n` и `shellcheck`, затем `bash -x` на тестовых данных.
3. Проверить скрипт на копии каталога или в контейнере — не на проде.
4. Убедиться, что повторный запуск безопасен (идемпотентность).
5. Запустить от имени того пользователя, под которым пойдёт cron.
6. Проверить логи: код 0/1, запись в файл, что видно в `journalctl`.
7. Продумать откат: где бэкап, как вернуть предыдущую версию.

## Вопросы на собеседовании

**Почему `tar -czf` лучше, чем `tar -cf - | gzip > file`?**
`-z` не создаёт лишний процесс и не оставляет обрезанный архив при ошибке; в пайпе без `pipefail` сбой `tar` можно не заметить.

**Почему для чисел нужен `sort -n`, а не `sort -r`?**
Без `-n` сортировка лексикографическая: «9» окажется больше «100». `-rn` — числовая по убыванию, это и нужно для подсчёта IP.

**Чем `curl -f` отличается от `curl -s`?**
`-s` только убирает прогресс-бар, код возврата остаётся 0 при 404. `-f` превращает HTTP >= 400 в ненулевой код выхода — без него проверка бесполезна.

**Как сделать скрипт идемпотентным?**
Проверять состояние перед действием: `mkdir -p`, `id user`, `systemctl is-active`, `grep -q` в конфиге. Повторный запуск не должен падать и дублировать данные.

**Почему `find -delete` опасен и как себя защитить?**
Он удаляет всё, что подошло под фильтр, включая лишнее при ошибке в `-name`/`-path`. Сначала запустить с `-print`, ограничить `-maxdepth` и `-type f`, тестировать на копии.

**Как логировать вывод из cron?**
Перенаправить в файл: `cmd >> /var/log/x.log 2>&1`, либо `| logger -t tagname` — тогда запись попадёт в journald/syslog с меткой.

## См. также

- [[Bash. Основы скриптов|Bash. Основы скриптов]]
- [[Linux для сисадмина. Чек-лист|Linux для сисадмина. Чек-лист]]
- [[ОС/Управление пользователями и группами в Linux|Пользователи и группы]]
- [[ОС/Системный журнал и логи|Логи и journald]]
