# Учётные записи и права Windows

Локальные учётные записи, группы, UAC, профили и права NTFS — то, с чем сталкиваешься каждый день: «забыл пароль», «нет доступа к папке», «профиль не загружается», «программа требует права администратора».

## Локальные учётки и группы

```text
whoami                 :: текущий пользователь
whoami /all            :: SID, группы, привилегии
whoami /groups         :: членство в группах
net user               :: список локальных пользователей
net user ivanov /add /fullname:"Иван Иванов"
net user ivanov P@ssw0rd /add
net user ivanov /active:no
net localgroup administrators ivanov /add
net localgroup "Remote Desktop Users" /add ivanov
net accounts           :: политика паролей и блокировки
```

| Группа | Права |
|---|---|
| Administrators | полный контроль, UAC-повышение |
| Users | обычная работа |
| Remote Desktop Users | вход по RDP |
| Backup Operators | обход прав при бэкапе |
| Hyper-V Administrators | управление Hyper-V |
| Event Log Readers | чтение журналов |

Встроенные: `Administrator` (по умолчанию отключён), `Guest` (отключён), `SYSTEM` (локальная система), `LOCAL SERVICE`/`NETWORK SERVICE` (службы), `DefaultAccount`.

## UAC

- Разделение токенов: обычный и повышенный; повышение — через consent prompt.
- Уровни: `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System` → `EnableLUA`, `ConsentPromptBehaviorAdmin`, `PromptOnSecureDesktop`.
- `runas /user:.\admin cmd` — запуск от другой учётки; «Запуск от имени администратора» — повышение текущей.
- Отключать UAC нельзя: приложения и настройки рассчитаны на него, а защита падает.

## Профили

| Тип | Где лежит | Особенность |
|---|---|---|
| Локальный | `C:\Users\<user>` | только на этом ПК |
| Перемещаемый | сетевой путь | настройки ездят за пользователем |
| Обязательный | сетевой `.vhdx`/`.man` | изменения не сохраняются |
| Временный | `C:\Users\TEMP` | признак проблемы с профилем |

Пути профилей: `HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\<SID>` → `ProfileImagePath`. Ошибка «User Profile Service failed the logon» лечится переименованием ветки в `.bak` и возвратом `ProfileImagePath` при необходимости.

## Пароли и учётные данные

- Политика: `secpol.msc` → Account Policies (длина, срок, история, блокировка), либо GPO.
- `net accounts /minpwlen:12 /lockoutthreshold:5 /lockoutduration:15`.
- Сброс локального пароля администратором: `net user ivanov NewP@ss` (данные EFS/DPAPI могут стать недоступны).
- Сохранённые креды: `cmdkey /list`, `cmdkey /delete:target`, Credential Manager (`control /name Microsoft.CredentialManager`).
- Автовход: `netplwiz`, но лучше не хранить пароль в открытом виде.

## Права NTFS и общие ресурсы

```text
icacls C:\Share
icacls C:\Share /grant "corp\ivanov:(OI)(CI)M" /t
icacls C:\Share /remove "corp\ivanov" /t
icacls C:\Share /inheritance:e|d
takeown /f C:\Share /r /d y
```

- Эффективное право = пересечение прав **share** и **NTFS**; из двух ограничений действует более строгое.
- `(OI)` — наследование на файлы, `(CI)` — на папки, `M` — modify, `F` — full, `R` — read.
- `takeown`+`icacls` — когда «нет доступа даже у администратора» (сменился владелец).
- Особые идентификаторы: `Everyone`, `Authenticated Users`, `CREATOR OWNER`, `SYSTEM`.
- Аудит доступа: `auditpol /set /subcategory:"File System" /success:enable /failure:enable`.

## Чек-лист диагностики

1. `whoami /all` — под кем реально работает пользователь и в каких группах он состоит.
2. Проверить, локальная это учётка или доменная; при доменной — доступен ли DC (`nltest /dsgetdc:corp.local`).
3. Пароль/блокировка: `net user <user>`, Event 4625/4740, сброс или `Unlock-ADAccount`.
4. Профиль: существует ли папка, что в `ProfileList`, нет ли `.bak`, хватает ли места.
5. Права: `icacls`, вкладка Security → Advanced → Effective Access, сравнить share и NTFS.
6. UAC: запускается ли программа от администратора, не блокирует ли SmartScreen/антивирус.
7. Для RDP — членство в `Remote Desktop Users` и включён ли RDP.
8. Зафиксировать: учётка, группа, что изменено, нужна ли перелогинка.

## Вопросы на собеседовании

**Чем локальная учётка отличается от доменной?** Локальная живёт в SAM этого компьютера, доменная — в AD и аутентифицируется через DC (Kerberos), работает на всех машинах домена.

**Почему пользователь видит папку, но не может открыть?** Права share и NTFS складываются по принципу «строже», либо нет прав на конкретный файл/родителя; смотреть Effective Access.

**Что делает UAC?** Не даёт приложению тихо получить административный токен: повышение требует подтверждения; снижает поверхность атаки.

**Как разблокировать учётку в домене?** `Unlock-ADAccount -Identity ivanov` или ADUC → Unlock; проверить источник блокировки (Event 4740 — с какого ПК).

**Профиль загрузился временный — почему?** Повреждён/недоступен профиль, конфликт `ProfileList`, нет прав или места; проверить журнал и ветку реестра.

## См. также

- [[Системное администрирование/Active Directory/Пользователи и группы AD|Пользователи и группы AD]]
- [[Системное администрирование/Сетевые службы/SMB и общие ресурсы|SMB и общие ресурсы]]
- [[Системное администрирование/Windows/Реестр Windows|Реестр Windows]]
- [[ОС/Управление пользователями и группами в Linux|Пользователи в Linux]]
