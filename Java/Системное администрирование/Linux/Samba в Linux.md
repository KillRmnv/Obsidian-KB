# Samba в Linux

Samba — реализация протокола SMB/CIFS, которая делает Linux-сервер файловым хранилищем, понятным Windows, macOS и сетевым сканерам. Типичные задачи: общий сетевой диск `\\server\share` для Windows-клиентов, права из Active Directory (`security = ads`), приём сканов с МФУ.

## Установка

```bash
apt install samba cifs-utils          # Debian/Ubuntu
dnf install samba samba-client cifs-utils   # RHEL-семейство
```

## Минимальный `/etc/samba/smb.conf`

```ini
[global]
   workgroup = WORKGROUP
   security = user
   map to guest = never
   log file = /var/log/samba/log.%m

[share]
   path = /srv/share
   browseable = yes
   valid users = @smbusers
   read only = no
   create mask = 0660
   directory mask = 0770
```

Для домена меняются три строки в `[global]`: `security = ads`, `realm = CONTOSO.LOCAL`, `workgroup = CONTOSO`.

## Пользователи и пароли

| Команда | Назначение |
|---|---|
| `smbpasswd -a user` | Добавить Samba-пароль существующему Unix-пользователю |
| `smbpasswd -e user` / `-d user` | Включить / отключить учётку |
| `pdbedit -L` | Список пользователей Samba |
| `groupadd smbusers && usermod -aG smbusers ivan` | Группа для `valid users = @smbusers` |

Пользователь обязан существовать в Unix (`useradd`), иначе `smbpasswd -a` создаст «висячую» запись. Пароль Samba хранится отдельно от `/etc/shadow`.

## Запуск и проверка

| Команда | Назначение |
|---|---|
| `systemctl enable --now smbd nmbd` | Сервер и NetBIOS-именование (на RHEL юнит — `smb`) |
| `smbclient -L //127.0.0.1 -U ivan` | Список шар под своей учёткой |
| `smbstatus` | Кто подключён и какие файлы открыты |
| `testparm -s` | Итоговый конфиг без комментариев |

Из Windows — `\\192.168.1.10\share` в проводнике или `net use Z: \\192.168.1.10\share /user:ivan`. Если по имени не открывается, а по IP работает — виноват DNS/NetBIOS, а не Samba.

## Права Unix и Samba

Доступ проверяется дважды: сначала Samba (`valid users`, `read only`, `write list`), затем Unix (владелец, группа, права).

| Параметр | Действие |
|---|---|
| `create mask = 0660` | Права новых файлов (вычитается из umask) |
| `directory mask = 0770` | Права новых каталогов |
| `force group = smbusers` | Все файлы получают группу шары |
| `force user = shareuser` | Все операции от одного Unix-пользователя |

`create mask` не даёт прав больше, чем разрешает Unix: при `chmod 750` на каталоге запись не появится. Для точечного доступа — [[ОС/ACL и ACE|ACL]] (`setfacl -m g:smbusers:rwx`).

## Монтирование cifs

```bash
printf 'username=backup\npassword=Secret\ndomain=WORKGROUP\n' > /root/.smbcred
chmod 600 /root/.smbcred
mount -t cifs //192.168.1.10/share /mnt/share \
  -o credentials=/root/.smbcred,vers=3.0,uid=1000,gid=1000,iocharset=utf8
```

В `/etc/fstab` та же строка плюс `_netdev,nofail`, иначе при недоступном сервере загрузка зависнет:

```fstab
//192.168.1.10/share /mnt/share cifs credentials=/root/.smbcred,vers=3.0,uid=1000,gid=1000,_netdev,nofail 0 0
```

`vers=3.0` обязателен для современных Windows и NAS: без него возможен откат на SMB1 или отказ. `uid`/`gid` нужны, потому что CIFS не хранит Unix-владельцев.

## Домен: winbind или sssd

- `realm join -U Administrator contoso.local` — ввод в домен (пакет `realmd`).
- `security = ads` + `kerberos method = secrets and keytab`, затем `net ads testjoin`.
- winbind: `winbind use default domain = yes`, `idmap config` для диапазонов UID/GID.
- sssd: службы `sssd`, `smbd`; в `sssd.conf` — `id_provider = ad`, `access_provider = ad`; проверка `id user@contoso.local` и `getent passwd`.

## Диагностика

| Симптом | Что смотреть |
|---|---|
| `NT_STATUS_ACCESS_DENIED` | Unix-права и ACL, `valid users`, SELinux: `ls -Z`, `setsebool -P samba_export_all_rw on` |
| `NT_STATUS_LOGON_FAILURE` | Пароль Samba (`smbpasswd -a`), `pdbedit -L`, не истёк ли срок |
| Шара не видна, но по IP открывается | `nmbd` не запущен, разные `workgroup`, порты 137-139/445 закрыты |
| Медленно или рвётся | `log level = 3`, `/var/log/samba/log.smbd`, `log.<client>` |
| Ошибка монтирования cifs | `dmesg \| tail`, `vers=`, `credentials`, `mount -t cifs -vv` |

## SMB1 и старые МФУ

Старые сканеры умеют только SMB1 (NT1), который в Samba 4.11+ отключён, а в Windows — удалён из-за EternalBlue. Быстрый костыль — `server min protocol = NT1` в `[global]` (действует на весь сервер, не на шару).

Безопасно: отдельный хост/VM для печати, `hosts allow = 192.168.1.50` (только IP МФУ), шара только на запись, отдельный пользователь без доступа к остальному, VLAN и правило файрвола на 445. Приоритет — обновление прошивки или scan-to-FTP/SFTP/email.

## Чек-лист диагностики

1. `testparm -s` — синтаксис и итоговый конфиг.
2. `systemctl status smbd nmbd` — службы запущены и включены.
3. `ss -tlnp | grep 445` и файрвол (`ufw status`, `firewall-cmd --list-all`).
4. `smbclient -L //server -U user` — видит ли шары сам сервер.
5. `smbclient //server/share -U user` + `ls`/`put` — проверка записи.
6. `tail -f /var/log/samba/log.smbd` при попытке клиента.
7. Проверить Unix-права (`namei -l /srv/share`), ACL и SELinux-контекст.

## Вопросы на собеседовании

**Чем `security = user` отличается от `security = ads`?**
`user` — локальная база Samba-паролей. `ads` — аутентификация в Active Directory через Kerberos, пользователи и группы берутся из домена, ввод в домен обязателен.

**Почему `smbpasswd -a` не работает для нового пользователя?**
Учётной записи нет в Unix. Сначала `useradd`, потом `smbpasswd -a`; иначе Samba не сможет сопоставить SMB-сессию с UID/GID.

**Клиент получает `NT_STATUS_ACCESS_DENIED`, права в Samba выставлены. В чём дело?**
Проверка идёт и по Unix: владелец, группа, права каталога, ACL. Плюс SELinux — у шары должен быть контекст `samba_share_t` (`semanage fcontext`/`restorecon`).

**Шара не видна в «Сети» Windows, но по `\\ip\share` открывается. Почему?**
Просмотр сети — это NetBIOS/WS-Discovery: `nmbd`, порты 137-138/udp, одинаковый `workgroup`. Сам доступ по SMB при этом работает.

**Как безопасно подключить старый МФУ с SMB1?**
Изолировать: отдельный сервер или VLAN, `server min protocol = NT1` только там, `hosts allow` с IP МФУ, отдельная шара и учётка, файрвол на 445. Идеально — обновить прошивку или перейти на FTP/SFTP.

## См. также

- [[Linux для сисадмина. Чек-лист|Linux для сисадмина. Чек-лист]]
- [[ОС/ACL и ACE|ACL и ACE]]
- [[ОС/Управление пользователями и группами в Linux|Пользователи и группы]]
- [[ОС/Управление службами (инициализация)|Службы и systemd]]
- [[Active Directory. Основы|Active Directory]]
