# Windows Server. Роли и службы

Минимум по Windows Server для L1–L2: чем редакции отличаются, как ставится роль, какие роли вообще бывают и что делать после установки. Глубокая настройка каждой роли — в отдельных заметках (AD, DNS, DHCP, файлы, бэкап).

## Редакции и лицензирование

| Редакция | Отличие |
|---|---|
| Standard | до 2 виртуальных ОС на лицензию (при лицензировании по ядрам) |
| Datacenter | неограниченное число виртуальных ОС, Storage Spaces Direct |
| Essentials | для малых организаций, ограничения по числу пользователей |

- Лицензия — по ядрам (минимум 16 на сервер, 8 на процессор) + **CAL** на пользователя/устройство.
- Варианты установки: **Desktop Experience** (GUI) и **Server Core** (минимум, управление через `sconfig`, PowerShell, RSAT/WAC).
- Активация: MAK/KMS/AD-based; пробный период обычно 180 дней.

## Установка и первичная настройка

1. Установка с ISO/USB, выбор редакции и типа (Core или GUI).
2. `sconfig` (Core) или Server Manager: имя, часовой пояс, сеть, обновления, домен.
3. Статический IP + DNS (для будущего DC DNS должен указывать на себя).
4. Включить удалённое управление (`Enable-PSRemoting`, WinRM), настроить брандмауэр.
5. Обновления, драйверы (особенно для RAID/сетевых карт), антивирус с исключениями для ролей.
6. Присоединить к домену (или повысить в DC, если это первый сервер).

## Основные роли

| Роль | Зачем | Ключевое |
|---|---|---|
| AD DS | домен, аутентификация | DNS обязателен, статический IP, `dcpromo` → `Install-ADDSForest` |
| DNS Server | внутренние зоны | зоны интегрированы в AD, SRV-записи DC |
| DHCP Server | выдача адресов | авторизация в AD, scope, options |
| File and Storage Services | шара, квоты, DFS, iSCSI | NTFS/share-права, FSRM, Storage Spaces |
| Print and Document Services | сервер печати | драйверы, очереди, GPO-развёртывание |
| Remote Desktop Services | терминальный доступ | лицензирование RDS, коллекции |
| Hyper-V | виртуализация | vSwitch, checkpoints, live migration |
| WSUS | обновления | группы компьютеров, одобрение |
| IIS | веб-сервер | сайты, привязки, пулы |
| Windows Deployment Services | установка по сети | PXE, boot.wim/install.wim |

Полезные компоненты: BitLocker, Failover Clustering, NLB, SNMP, Telnet Client, Backup.

## PowerShell для ролей

```powershell
Get-WindowsFeature
Get-WindowsFeature -Name AD-Domain-Services,DNS,DHCP
Install-WindowsFeature -Name DNS -IncludeManagementTools
Install-WindowsFeature -Name Web-Server -IncludeAllSubFeature
Uninstall-WindowsFeature -Name Web-Server
Get-Service | Where-Object Status -eq 'Stopped'
Get-EventLog -LogName System -Newest 50   # или Get-WinEvent
```

## Диски, тома и файловый сервер

- `diskmgmt.msc` / `Get-Disk` / `Initialize-Disk` / `New-Partition` / `Format-Volume`.
- Тома: базовая/динамическая, MBR/GPT; для серверов — GPT.
- Storage Spaces: пул + виртуальный диск + том (чётность/зеркало).
- Шары: `New-SmbShare -Name Share -Path C:\Share -FullAccess "corp\Domain Admins"`.
- Квоты и отчёты — FSRM; DFS — пространство имён и репликация между серверами.

## Типовые задачи администратора

| Задача | Инструмент |
|---|---|
| Повысить сервер в DC | `Install-ADDSForest` / `Install-ADDSDomainController` |
| Присоединить к домену | `Add-Computer -DomainName corp.local -Restart` |
| Добавить роль | `Install-WindowsFeature` / Server Manager |
| Настроить шару | `New-SmbShare`, `icacls` |
| Посмотреть журналы | `eventvwr.msc`, `Get-WinEvent` |
| Управлять удалённо | RSAT, `Enter-PSSession`, Windows Admin Center |
| Бэкап | `wbadmin`, Windows Server Backup, Veeam |

## Чек-лист диагностики

1. Понять, какая роль «отвечает» за симптом (DNS не резолвит → DNS-роль; вход в домен → AD DS).
2. Проверить службы роли: `Get-Service`, `services.msc`, журнал Application/System.
3. Проверить сеть: статический IP, шлюз, DNS, брандмауэр (роли открывают свои порты).
4. Для AD — `dcdiag`, `repadmin /replsummary`, `nltest /dsgetdc`.
5. Для роли, которая «не ставится» — журнал установки, свободное место на C:, права, зависимости.
6. Проверить лицензирование/активацию (`slmgr /dlv`), особенно для RDS.
7. Зафиксировать изменения и перезагрузки; серверные изменения — только в окно обслуживания.

## Вопросы на собеседовании

**Чем Standard отличается от Datacenter?** Правом на виртуальные экземпляры: Standard — 2 ВМ, Datacenter — неограниченно (плюс S2D).

**Что нужно до повышения сервера в DC?** Статический IP, корректный DNS, уникальное имя, актуальные обновления, понимание, что DNS станет частью AD.

**Server Core — как управлять?** `sconfig` для базового, дальше PowerShell/RSAT/WinRM или Windows Admin Center; GUI не нужен.

**Зачем CAL?** Клиентские лицензии на доступ к серверным службам; без них использование нелицензировано.

**Сервер не виден в сети — что проверить?** Профиль сети (Domain/Private), брандмауэр, службы обнаружения, DNS-регистрация, `Test-NetConnection`.

## См. также

- [[Системное администрирование/Active Directory/Active Directory. Основы|Active Directory. Основы]]
- [[Системное администрирование/Сетевые службы/DNS на практике|DNS на практике]]
- [[Системное администрирование/Сетевые службы/DHCP на практике|DHCP на практике]]
- [[Системное администрирование/Виртуализация/VMware vSphere. Основы|VMware vSphere]]
- [[Системное администрирование/Резервное копирование/Windows Server Backup|Windows Server Backup]]
