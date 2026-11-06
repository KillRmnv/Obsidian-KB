# Linux для сисадмина. Чек-лист

Практический минимум команд для повседневной работы и разбора инцидентов. Порядок секций повторяет путь от «что за машина» до «почему не работает».

## Железо и система

| Команда | Назначение |
|---|---|
| `uname -a` / `cat /etc/os-release` | Ядро и архитектура / дистрибутив и версия |
| `lscpu` | CPU: сокеты, ядра, потоки, флаги (`nproc` — только число) |
| `free -h` | RAM и swap; смотреть `available`, а не `free` |
| `dmidecode -t system` | Модель/серийник железа (нужен root) |
| `lsblk -f` | Блочные устройства, разделы, ФС, UUID |

## Сеть

| Команда | Назначение |
|---|---|
| `ip a` / `ip -br a` | Интерфейсы, состояние, адреса (коротко) |
| `ip r` | Таблица маршрутизации, default gateway |
| `ss -tulpn` | Слушающие порты и их PID/процессы |
| `dig +short example.com` / `dig @8.8.8.8` | Проверка DNS и конкретного резолвера |
| `traceroute -n 8.8.8.8` | Путь до узла, где теряются пакеты |
| `tcpdump -i any port 53` | Что реально летит по сети (DNS) |

## Диски, файловые системы, LVM

| Команда | Назначение |
|---|---|
| `df -h` / `df -i` | Место и **inodes** — вторая по частоте причина «нет места» |
| `du -sh /*` / `du -xhd1 /var \| sort -h` | Кто съел место (глубже — без перехода на другие ФС) |
| `mount` / `findmnt` | Что и куда смонтировано сейчас |
| `cat /etc/fstab` / `blkid` | Монтирование при загрузке / UUID для fstab |
| `pvs` / `vgs` / `lvs` | Состояние LVM: PV → VG → LV |
| `lvextend -r -L +5G /dev/vg0/lv_root` | Расширить LV вместе с ФС (`-r` = resize2fs/xfs_growfs) |

## Процессы и службы

| Команда | Назначение |
|---|---|
| `ps aux --sort=-%cpu \| head` | Топ по CPU (аналогично `-%mem`) |
| `top` / `htop` | Интерактивно: load, зомби, потоки |
| `kill -15 PID` / `kill -9 PID` | SIGTERM (штатно) / SIGKILL (без уборки) |
| `nice -n 10 cmd` / `renice -n 5 -p PID` | Понизить приоритет при старте / на лету |
| `systemctl status svc` | Состояние, последние строки лога, PID |
| `systemctl start svc` / `enable --now svc` | Запустить сейчас / автозагрузка + запуск |
| `systemctl --failed` | Все упавшие юниты — первый шаг диагностики |
| `journalctl -u svc -f` | Живой лог конкретной службы |

## Пользователи, права, sudo

| Команда | Назначение |
|---|---|
| `id user` / `groups user` | UID, GID, все группы |
| `useradd -m -s /bin/bash user` / `passwd user` | Создать с домашним каталогом / задать пароль |
| `usermod -aG docker user` | Добавить в группу (`-a` обязателен, иначе перезапишет список) |
| `visudo` / `sudo -l` | Правка sudoers с проверкой синтаксиса / что разрешено мне |
| `chmod 640 f` / `chown user:group f` | Права / владелец |
| `umask` | Маска прав новых файлов (022 → 644, 077 → 600) |
| `getfacl f` / `setfacl -m u:ivan:rw f` | Просмотр и выдача [[ОС/ACL и ACE\|ACL]] |
| `chmod +t /shared` | Sticky bit: удалять может только владелец |

## Пакеты и логи

| Команда | Назначение |
|---|---|
| `apt update && apt install pkg` / `dnf install pkg` | Debian / RHEL семейства |
| `journalctl -p err -b` / `--since "1 hour ago"` | Ошибки с загрузки / логи за период |
| `tail -f /var/log/syslog` (Debian) / `/var/log/messages` (RHEL) | Системный журнал |
| `logrotate -d /etc/logrotate.conf` | Проверить правила ротации без применения |

## SSH и файрвол

| Команда | Назначение |
|---|---|
| `ssh-keygen -t ed25519` / `ssh-copy-id user@host` | Ключ / публикация ключа |
| `sshd -t && systemctl reload sshd` | Проверить конфиг и применить без разрыва сессий |
| `PermitRootLogin no`, `PasswordAuthentication no`, `Port 2222` | Базовое ужесточение `/etc/ssh/sshd_config` |
| `ufw status verbose` / `ufw allow 22/tcp` | Простой файрвол на Debian/Ubuntu |
| `firewall-cmd --add-service=http --permanent && firewall-cmd --reload` | firewalld на RHEL |
| `nft list ruleset` | Актуальные правила nftables |

## Cron, timers, SELinux/AppArmor

| Команда | Назначение |
|---|---|
| `crontab -e` / `crontab -l` | Свои задачи / список |
| `systemctl list-timers` | Активные systemd timers (точнее и с логами) |
| `getenforce` / `setenforce 0` / `ausearch -m avc -ts recent` | Режим SELinux / временно выключить / отказы |
| `ls -Z f` / `restorecon -Rv /path` | Контекст SELinux / вернуть дефолтный |
| `aa-status` / `aa-complain <profile>` | Статус AppArmor / режим жалоб |

## Типовые инциденты

- **Диск заполнен:** `df -h` → `df -i` → `du -xhd1 /var | sort -h` → `lsof +L1` (удалённый, но открытый файл держит место — лечится рестартом процесса).
- **Сервис не стартует:** `systemctl status` → `journalctl -u svc -n 50` → проверить конфиг (`nginx -t`, `sshd -t`), права, порт, `Type=` и `ExecStart`.
- **Порт занят:** `ss -tulpn | grep :8080` или `fuser -n tcp 8080` → убить/перевесить чужой процесс, проверить дубль юнита.
- **Высокий load average:** сравнить `uptime` с `nproc`; много `D` в `top` = диск/NFS, много `R` = CPU; проверить `iostat -x 1`.
- **OOM killer:** `dmesg -T | grep -i "killed process"` → виновник и объём; лечить лимитами (`MemoryMax=` в юните) или добавить RAM/swap.
- **Не монтируется раздел:** `findmnt`, `blkid`, `mount -a` и текст ошибки; частая причина — битый UUID в `/etc/fstab` или неверный тип ФС.
- **Нет сети после перезагрузки:** `ip -br a` (интерфейс DOWN) → `nmcli device status`, конфиг в `/etc/netplan` или `ifcfg-*`, `systemctl status NetworkManager`; статический адрес мог не сохраниться.

## Чек-лист диагностики

1. `uptime`, `who`, `last` — что изменилось и кто был в системе.
2. `systemctl --failed` — упавшие юниты.
3. `df -h`, `df -i`, `free -h` — место, inodes, память.
4. `journalctl -p err -b --since "-30 min"` — ошибки за период.
5. `ip -br a`, `ip r`, `ss -tulpn` — сеть и порты.
6. `ps aux --sort=-%cpu | head`, `dmesg -T | tail -30` — нагрузка и сообщения ядра.
7. Зафиксировать причину и действие: тикет, `history`, заметка.

## Вопросы на собеседовании

**Чем `kill -15` отличается от `kill -9`?**
SIGTERM можно перехватить: процесс завершится штатно, закрыв файлы и соединения. SIGKILL ядро обрабатывает само, уборки не будет — только как последнее средство.

**Диск заполнен, а `du` не находит виновника. Что делать?**
Искать inodes (`df -i`) и удалённые открытые файлы (`lsof +L1`). Место освободится после перезапуска держащего процесса; также проверить снапшоты.

**`systemctl start` вернул успех, но сервис не работает. Почему?**
Юнит `Type=simple` считается запущенным сразу после fork, хотя процесс уже упал. Смотреть `systemctl status`, `journalctl -u`, `ExecStart`, конфиг и права.

**Как узнать, какой процесс слушает порт 8080?**
`ss -tulpn | grep 8080` или `lsof -i :8080`; дальше `systemctl status <PID>` покажет, какой это юнит.

**`chmod 777` стоит, но доступ всё равно запрещён. В чём причина?**
SELinux/AppArmor, ACL, `noexec`/`nosuid` на монтировании, отсутствие `x` на родительских каталогах (`namei -l /path`), атрибут immutable (`lsattr`).

**Что такое load average и когда он критичен?**
Средняя длина очереди задач (R + D) за 1/5/15 минут. Сравнивать с `nproc`: устойчиво выше числа ядер — узкое место; много `D` указывает на диск, а не CPU.

## См. также

- [[ОС/Управление процессами|Управление процессами]]
- [[ОС/Управление службами (инициализация)|Службы и systemd]]
- [[ОС/Сетевые настройки|Сетевые настройки]]
- [[ОС/Управление дисками и файловыми системами|Диски и ФС]]
- [[Bash. Основы скриптов|Bash. Основы скриптов]]
