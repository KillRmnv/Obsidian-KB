# PowerShell в администрировании Windows

Продолжение заметки «Основы»: те же приёмы (команда → объект → свойство → фильтр), только на реальных задачах. Формат: задача → команда → что увидишь → почему так. Всё выполняется в обычной консоли; для изменения служб и системных папок нужен запуск от администратора.

## Службы

```powershell
Get-Service                                   # все службы
Get-Service Spooler                           # одна по имени
Get-Service | Where-Object Status -eq 'Stopped'
```

```text
Status   Name               DisplayName
------   ----               -----------
Stopped  Spooler            Print Spooler
```

```powershell
Start-Service Spooler
Stop-Service Spooler
Restart-Service Spooler -Force                 # -Force — перезапустить зависимые
Set-Service -Name Spooler -StartupType Automatic
```

`Get-Service` не показывает путь к exe и учётку запуска — для этого `Get-CimInstance Win32_Service -Filter "Name='Spooler'"`.

## Процессы

```powershell
Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 5 Name, Id, WorkingSet64
Stop-Process -Name notepad
Stop-Process -Id 4242 -Force
```

`-Name` без `.exe`. Если процессов несколько, `Stop-Process -Name` остановит все — проверяй через `Get-Process -Name`.

## Диски и здоровье железа

```powershell
Get-Volume | Select-Object DriveLetter, FileSystemLabel, SizeRemaining, Size
Get-PhysicalDisk | Select-Object FriendlyName, MediaType, HealthStatus, OperationalStatus
Get-Disk | Select-Object Number, FriendlyName, PartitionStyle, HealthStatus
```

`SizeRemaining` в байтах; чтобы в ГБ: `[math]::Round($_.SizeRemaining/1GB, 1)`.

## Журналы событий

```powershell
Get-WinEvent -LogName System -MaxEvents 20
Get-WinEvent -FilterHashtable @{LogName='System'; Id=41,6008; StartTime=(Get-Date).AddDays(-7)}
Get-WinEvent -LogName Application -MaxEvents 10 |
    Select-Object TimeCreated, Id, LevelDisplayName, ProviderName
```

`-FilterHashtable` фильтрует **на стороне журнала**, поэтому работает быстро; `Where-Object` после `Get-WinEvent` — уже после выгрузки.

## Файлы и папки

```powershell
Get-ChildItem C:\Logs -Recurse -File | Where-Object Length -gt 1GB
Get-ChildItem C:\Logs -Recurse -File |
    Sort-Object LastWriteTime -Descending | Select-Object -First 10 FullName, LastWriteTime
Get-Content C:\Logs\app.log -Tail 50
Test-Path C:\Backup
```

`Get-ChildItem` для файлов = `dir`, `Get-Content` = `type`. `Test-Path` возвращает `True/False` — удобно в условиях `if`.

## Сеть

```powershell
Get-NetIPConfiguration                                   # адрес, шлюз, DNS
Test-NetConnection dc01 -Port 389                        # доступность порта
Resolve-DnsName server.corp.local                        # DNS-запрос
Get-NetTCPConnection -LocalPort 3389 -State Listen       # кто слушает порт
Get-NetAdapter | Select-Object Name, Status, LinkSpeed
```

```text
ComputerName           : dc01
RemotePort             : 389
TcpTestSucceeded       : True
```

`Test-NetConnection` без `-Port` проверяет ICMP (ping), с `-Port` — реальный TCP. Второе надёжнее: ping часто заблокирован файрволом.

## Локальные учётные записи

```powershell
Get-LocalUser | Select-Object Name, Enabled, LastLogon
New-LocalUser -Name 'temp01' -Password (Read-Host -AsSecureString 'Пароль') -AccountNeverExpires
Add-LocalGroupMember -Group 'Remote Desktop Users' -Member 'temp01'
Disable-LocalUser -Name 'temp01'
```

Пароль нельзя передать строкой в открытом виде — `Read-Host -AsSecureString` возвращает защищённую строку, её и принимает `-Password`.

## Реестр

```powershell
Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' |
    Select-Object ProductName, CurrentBuild

New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' `
    -Name NoAutoUpdate -Value 1 -PropertyType DWord -Force
```

Реестр в PowerShell — «диск» `HKLM:`/`HKCU:`. Ключи ведут себя как папки: `Get-ChildItem`, `New-Item`, `Remove-Item` работают и там.

## Установка ПО

```powershell
Start-Process msiexec.exe -ArgumentList '/i','C:\pkg\agent.msi','/qn' -Wait
Start-Process 'C:\pkg\setup.exe' -ArgumentList '/S' -Wait
winget install --id 7zip.7zip -e --silent
```

`-Wait` обязателен: без него скрипт пойдёт дальше, не дождавшись установки. `/qn` у MSI — тихая установка без окон.

## Планировщик и удалённое выполнение

```powershell
Get-ScheduledTask | Where-Object TaskPath -like '\Corp\*'
Get-ScheduledTask -TaskName 'Backup*' | Select-Object TaskName, State

Invoke-Command -ComputerName DC01, DC02 -ScriptBlock { Get-Service Spooler }
```

`Invoke-Command` выполняет блок на удалённых машинах и возвращает объекты с колонкой `PSComputerName` — то есть результат можно фильтровать так же, как локальный.

## Экспорт отчётов

```powershell
Get-Service | Select-Object Name, Status |
    Export-Csv C:\Reports\services.csv -NoTypeInformation -Encoding UTF8

Get-Volume | ConvertTo-Html | Out-File C:\Reports\volumes.html
```

`Export-Csv` пишет объекты в CSV, `-NoTypeInformation` убирает служебную первую строку. `ConvertTo-Html` делает таблицу для письма или отчёта.

## Готовые скрипты с разбором

### 1. Инвентаризация компьютера

```powershell
$out = 'C:\Reports\inventory.csv'
New-Item -ItemType Directory -Path (Split-Path $out) -Force | Out-Null

$os   = Get-CimInstance Win32_OperatingSystem
$cs   = Get-CimInstance Win32_ComputerSystem
$cpu  = Get-CimInstance Win32_Processor | Select-Object -First 1
$disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"

[PSCustomObject]@{
    Computer   = $env:COMPUTERNAME
    User       = $env:USERNAME
    OS         = $os.Caption
    Version    = $os.Version
    CPU        = $cpu.Name
    RAM_GB     = [math]::Round($cs.TotalPhysicalMemory / 1GB, 1)
    DiskFreeGB = [math]::Round($disk.FreeSpace / 1GB, 1)
} | Export-Csv $out -NoTypeInformation -Encoding UTF8
```

- `New-Item ... -Force | Out-Null` — создать папку, если её нет; `Out-Null` убирает лишний вывод.
- `[PSCustomObject]@{}` — одна строка будущей таблицы с понятными именами колонок.
- `[math]::Round(..., 1)` — округлить до одного знака.
- `Export-Csv` — записать. На парке машин добавляют `-Append`, чтобы собрать всех в один файл.

### 2. Очистка `%TEMP%` старше 7 дней

```powershell
$cutoff = (Get-Date).AddDays(-7)

Get-ChildItem $env:TEMP -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object LastWriteTime -lt $cutoff |
    Remove-Item -Force -WhatIf
```

- `$env:TEMP` — переменная окружения текущего пользователя.
- `-ErrorAction SilentlyContinue` — не падать на занятых файлах.
- `-WhatIf` сначала показывает, что будет удалено. **Убери его только после проверки списка.**

### 3. Поиск файлов больше 1 ГБ

```powershell
Get-ChildItem C:\Users -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object Length -gt 1GB |
    Sort-Object Length -Descending |
    Select-Object FullName, @{N='GB';E={[math]::Round($_.Length/1GB,2)}} |
    Export-Csv C:\Reports\bigfiles.csv -NoTypeInformation
```

`@{N='GB';E={...}}` — вычисляемая колонка: `N` имя, `E` выражение. Так в отчёт попадает размер в гигабайтах, а не в байтах.

### 4. Сторож службы

```powershell
$svc  = 'Spooler'
$log  = 'C:\Logs\watchdog.log'
$item = Get-Service $svc

if ($item.Status -ne 'Running') {
    Start-Service $svc -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 5
    $item.Refresh()
    "$(Get-Date -Format s) $svc -> $($item.Status)" | Add-Content $log
}
```

- `-ne` — «не равно».
- После `Start-Service` объект `$item` хранит старое состояние — `Refresh()` перечитывает его.
- `Add-Content` дописывает строку в лог, не затирая файл.

## Чек-лист диагностики

1. Не помню команду — `Get-Command *служб*`, `Get-Command -Module *AD*`.
2. Не помню параметры — `Get-Help <команда> -Examples`, `-Parameter <имя>`.
3. Не понимаю, что вернулось — `| Get-Member`, `| Select-Object *`.
4. Команда меняет систему — сначала `-WhatIf`, потом без него.
5. «Нет прав» — запустить консоль от имени администратора, проверить, та ли это машина.
6. Ошибка не ловится `catch` — добавить `-ErrorAction Stop`.
7. Пусто в результате — проверить фильтр (`-eq`/`-like`), регистр и тип свойства.
8. Скрипт не запускается — `Get-ExecutionPolicy -List`, `Unblock-File .\script.ps1`.

## Вопросы на собеседовании

**Как узнать, запущена ли служба, и запустить её?** `Get-Service Spooler` → `Status`; `Start-Service Spooler` (от администратора).

**Как найти процесс, который ест больше всего памяти?** `Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 5 Name, WorkingSet64`.

**Как проверить, что порт на сервере доступен?** `Test-NetConnection server -Port 443`; смотреть `TcpTestSucceeded`.

**Как посмотреть события за последние сутки по ID?** `Get-WinEvent -FilterHashtable @{LogName='System'; Id=41; StartTime=(Get-Date).AddDays(-1)}`.

**Как выгрузить список служб в CSV?** `Get-Service | Select-Object Name, Status | Export-Csv services.csv -NoTypeInformation`.

**Зачем `-WhatIf` и `-Confirm`?** Первый показывает план без выполнения, второй спрашивает подтверждение перед каждым действием.

**Как выполнить команду сразу на 20 компьютерах?** `Invoke-Command -ComputerName (Get-Content pcs.txt) -ScriptBlock { ... }`.

## См. также

- [[Системное администрирование/PowerShell/PowerShell. Основы|PowerShell. Основы]] — если что-то ниже осталось непонятным
- [[Системное администрирование/PowerShell/PowerShell и Active Directory|PowerShell и Active Directory]]
- [[Системное администрирование/Windows/Сетевые параметры Windows|Сетевые параметры Windows]]
