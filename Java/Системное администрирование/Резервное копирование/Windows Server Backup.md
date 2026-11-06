# Windows Server Backup

Встроенное средство Windows Server: копирует файлы, тома, system state и умеет bare-metal recovery, но не заменяет корпоративную систему бэкапа. Полезно знать границы возможностей и как восстановиться без GUI.

## Что умеет и чего не умеет

| Умеет | Не умеет |
|---|---|
| Файлы, папки, тома, system state | Централизованное управление парком |
| Расписание на выделенный диск или шару | Дедупликация и продвинутое сжатие |
| Bare-metal recovery через WinRE | GFS и гибкая политика хранения |
| VSS-консистентные копии, Hyper-V на хосте | Application-aware для любых приложений |
| PowerShell-модуль `WindowsServerBackup` | Офсайт-репликация и immutable-копии |

На локальный диск копия идёт блоками (инкрементально), на сетевую шару — каждый раз полная. Одна политика на сервер; целевой диск выделяется под бэкап и при настройке переформатируется.

## wbadmin: основные команды

Формат даты зависит от локали; ниже ММ/ДД/ГГГГ-ЧЧ:ММ, точный вид подскажет `wbadmin get versions`.

```text
:: Разовая копия критичных томов на E:
wbadmin start backup -backupTarget:E: -include:C: -allCritical -quiet

:: Версии и содержимое
wbadmin get versions
wbadmin get items -version:03/15/2024-23:00

:: Только system state
wbadmin start systemstatebackup -backupTarget:E: -quiet

:: Восстановление файла и system state
wbadmin start recovery -version:03/15/2024-23:00 -itemType:File ^
  -items:C:\Data\report.xlsx -recoveryTarget:C:\Restore
wbadmin start systemstaterecovery -version:03/15/2024-23:00

:: Ротация и расписание
wbadmin delete backup -keepVersions:3
wbadmin enable backup -addtarget:E: -schedule:23:00 -include:C: -allCritical
```

`-allCritical` включает системные тома, нужные для загрузки; без него bare-metal может не получиться. `wbadmin get status` показывает, идёт ли копия сейчас.

## System state и bare-metal recovery

**System state** — реестр, COM+ class registration, загрузочные файлы, SYSVOL; на контроллере домена — база AD (`NTDS.dit`), на CA — база сертификатов, на кластере — сведения о кворуме.

**Bare-metal recovery** восстанавливает ОС на чистый диск: загрузка с установочного носителя → Repair → System Image Recovery либо Windows Server Backup → Recovery → «Этот сервер». Нужны драйверы хранилища/сети, если железо отличается. System state возвращает роль, но не пользовательские данные.

## Восстановление AD

1. Загрузить DC в **DSRM**: `bcdedit /set safeboot dsrepair`, перезагрузка; пароль DSRM задавался при повышении роли.
2. Восстановить system state из бэкапа (`wbadmin start systemstaterecovery`).
3. Перезагрузиться в обычный режим: по умолчанию восстановление **non-authoritative**, после репликации DC получит актуальные данные от партнёров.
4. Если объект удалён на всех DC — **authoritative restore**: `ntdsutil` → `authoritative restore` → `restore subtree "OU=..."`; версия объекта повышается, и он реплицируется обратно.
5. SYSVOL при необходимости восстанавливают через BurFlags (`D4` на authoritative, `D2` на остальных). Перед восстановлением понимать, что именно вернётся, и не поднимать старый DC с устаревшими паролями без плана.

## PowerShell

```powershell
Install-WindowsFeature Windows-Server-Backup
Import-Module WindowsServerBackup

$policy = New-WBPolicy
Add-WBBackupTarget -Policy $policy -Target (New-WBBackupTarget -VolumePath 'E:')
Add-WBVolume -Policy $policy -Volume (Get-WBVolume -VolumePath 'C:')
Add-WBFileSpec -Policy $policy -FileSpec 'C:\Data'
Add-WBSystemState -Policy $policy
Set-WBSchedule -Policy $policy -Schedule 23:00
Set-WBPolicy -Policy $policy

Start-WBBackup -Policy $policy
Get-WBJob -Previous 5
Get-WBSummary
```

`Get-WBPolicy` показывает текущую политику, `Get-WBSummary` — последний результат, следующий запуск и причину ошибки.

## Гранулярность и ограничения

- Файлы/папки и тома: точечно или том целиком; отдельный файл из образа достаётся монтированием VHD(X).
- System state — роль целиком (AD, DNS, DHCP, сертификаты), не отдельные объекты.
- Hyper-V на хосте — ВМ копируются, но без прикладной согласованности гостей.
- Почтовых алертов нет, ретеншн ограничен: Event Viewer, `Get-WBSummary`, `Get-WBJob`, `-keepVersions`.

## Когда достаточно WSB, а когда нужен Veeam

| Ситуация | Выбор |
|---|---|
| Один файловый сервер, нет виртуализации | WSB |
| Нужен только system state/AD | WSB |
| Парк ВМ, app-aware, offsite, проверка восстановления | Veeam B&R |
| Нужны immutable-копия и отчётность | Veeam B&R |
| Физический сервер вне домена, простой сценарий | WSB или Veeam Agent |

## Чек-лист «бэкап настроен правильно»

1. Цель — отдельный диск или шара, не системный том.
2. В копию входят нужные тома, `-allCritical` для BMR.
3. Расписание соответствует RPO и не пересекается с окном нагрузки.
4. На цели есть место и понятная ротация версий.
5. Контроль: `Get-WBSummary`, Event Viewer, внешний мониторинг.
6. Проверено восстановление файла и отдельно system state.
7. Для DC известен пароль DSRM и порядок authoritative restore.
8. Есть копия вне сервера: WSB сам офсайт не делает.

## Чек-лист диагностики

1. `Get-WBSummary` / `Get-WBJob` — результат и причина.
2. Event Viewer → `Microsoft-Windows-Backup` — ошибки задания и VSS.
3. `vssadmin list writers` — все ли writers в состоянии `Stable`.
4. Цель: доступность диска/шары, свободное место, права.
5. `wbadmin get versions` — есть ли свежая версия и что в неё входит.
6. Службы: `Virtual Disk`, `Volume Shadow Copy`, `Windows Backup`.
7. Для шары — учётная запись, DNS, SMB, брандмауэр; пробное восстановление файла с записью результата.

## Вопросы на собеседовании

**Чем system state отличается от полного бэкапа тома?**
System state — элементы ОС и ролей: реестр, загрузочные файлы, AD, SYSVOL, CA. Данные и приложения в него не входят, том копируется целиком отдельно.

**Как восстановить контроллер домена из бэкапа?**
Загрузиться в DSRM, восстановить system state, перезагрузиться. По умолчанию восстановление non-authoritative; для удалённых объектов — authoritative через `ntdsutil`.

**Почему бэкап на сетевую шару делается дольше и больше?**
На шару каждая копия пишется полностью, без блочного инкремента, который работает при копировании на локальный диск.

**Что такое bare-metal recovery и что для него нужно?**
Восстановление ОС на чистый диск из образа: загрузочный носитель/WinRE, доступ к бэкапу и драйверы хранилища/сети при другом железе.

**Можно ли использовать WSB для парка виртуальных машин?**
Технически можно копировать ВМ на хосте Hyper-V, но нет центрального управления, app-aware, офсайта и проверок. Для парка нужен Veeam или аналог.

## См. также

- [[Системное администрирование/Резервное копирование/Резервное копирование. Принципы|Принципы резервного копирования]]
- [[Системное администрирование/Резервное копирование/Veeam Backup & Replication|Veeam Backup & Replication]]
- [[Системное администрирование/Windows/Windows Server. Роли и службы|Windows Server]]
- [[Системное администрирование/Active Directory/Active Directory. Основы|Active Directory]]
- [[Системное администрирование/PowerShell/PowerShell. Основы|PowerShell]]
