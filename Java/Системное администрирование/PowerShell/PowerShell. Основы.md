# PowerShell. Основы

Эта заметка объясняет PowerShell с нуля: что это, как читать команду, почему все говорят про «объекты» и как собрать из команд что-то полезное. Читать сверху вниз, примеры выполнять в консоли — без запуска всё останется непонятным текстом.

## 1. Что это и зачем

В cmd команды возвращают **текст**. Чтобы найти в нём что-то, приходится разбирать строки.

В PowerShell команда возвращает **объект** — набор свойств с именами. Как строка в Excel: у неё есть колонки `Name`, `Status`, `Id`, и к ним можно обращаться по имени.

| Задача | cmd | PowerShell |
|---|---|---|
| Список процессов | `tasklist` → текст | `Get-Process` → объекты с `Name`, `Id`, `CPU` |
| Найти процесс | `findstr` поверх вывода `tasklist` | `Get-Process chrome` |
| Остановить | `taskkill /IM chrome.exe` | `Stop-Process -Name chrome` |
| Отфильтровать по свойству | невозможно без парсинга | `Get-Process \| Where-Object CPU -gt 100` |

Отсюда главное: в PowerShell не «ищут текст», а **фильтруют объекты по свойствам**.

## 2. Из чего состоит команда

Команда в PowerShell называется **cmdlet** и всегда строится по схеме `Глагол-Существительное`:

```text
Get-Service      получить службы
Set-Service      изменить настройку службы
Start-Service    запустить службу
Stop-Service     остановить службу
Restart-Service  перезапустить
New-Item         создать объект (файл, папку, ключ)
Remove-Item      удалить
```

Глагол говорит, **что делаем**, существительное — **с чем**. Зная это, можно угадать команду, даже если никогда её не видел: `Get-Disk`, `Get-Volume`, `Get-NetIPAddress`, `Get-LocalUser`.

Параметры пишутся через дефис:

```powershell
Get-Service -Name Spooler
#            ^параметр ^значение
```

Значение можно не писать, если параметр стоит первым: `Get-Service Spooler` — то же самое. В скриптах лучше писать полный параметр, так понятнее.

## 3. Первые пять команд

```powershell
Get-Service                    # все службы
Get-Process                    # все процессы
Get-ChildItem C:\Windows       # содержимое папки (аналог dir)
Get-Content C:\Windows\win.ini # прочитать файл (аналог type)
Get-Help Get-Service           # справка по команде
```

Так выглядит ответ `Get-Service Spooler`:

```text
Status   Name               DisplayName
------   ----               -----------
Running  Spooler            Print Spooler
```

Это **одна строка таблицы** с тремя свойствами: `Status`, `Name`, `DisplayName`.

Что делать, когда команда незнакома:

```powershell
Get-Help Get-Service -Examples   # примеры — самое полезное
Get-Command *service*            # найти команды по слову
Get-Command -Verb Get            # все команды, которые что-то получают
```

## 4. Объекты: главный приём

Смотрим, какие свойства есть у результата:

```powershell
Get-Service Spooler | Get-Member
```

В ответе будет:

```text
   TypeName: System.ServiceProcess.ServiceController   ← тип объекта
Name            MemberType
----            ----------
Status          Property      ← свойства (данные)
StartType       Property
Stop            Method        ← методы (действия)
```

Теперь свойства можно выбирать:

```powershell
Get-Service Spooler | Select-Object Status, StartType, Name
```

```text
Status   StartType Name
------   --------- ----
Running  Automatic Spooler
```

`Select-Object` — «покажи только эти колонки». `Select-Object *` — «покажи все».

**Правило трёх шагов для любой незнакомой команды:**

1. Выполнить её без параметров.
2. Добавить `| Get-Member` — узнать свойства.
3. Добавить `| Select-Object свойство1, свойство2` — оставить нужное.

## 5. Конвейер `|`: передай дальше

Вертикальная черта означает «результат левой команды передай правой». Данные не превращаются в текст — передаются объекты.

Разберём одну длинную строку по частям:

```powershell
Get-Process |
    Where-Object { $_.WorkingSet64 -gt 200MB } |
    Sort-Object WorkingSet64 -Descending |
    Select-Object -First 3 Name, Id, WorkingSet64
```

Что происходит по шагам:

| Шаг | Команда | Результат |
|---|---|---|
| 1 | `Get-Process` | ~150 объектов-процессов |
| 2 | `Where-Object { ... }` | только те, у кого память > 200 МБ (например, 8 штук) |
| 3 | `Sort-Object ... -Descending` | те же 8, но сверху самый «тяжёлый» |
| 4 | `Select-Object -First 3 ...` | первые 3 строки, только 3 колонки |

Главное здесь — `$_`. Это **текущий объект**, который сейчас идёт по конвейеру. Блок `{ ... }` выполняется для каждого объекта, и `$_` каждый раз — новый объект. Дословно: «для каждого процесса: если его `WorkingSet64` больше 200 МБ — оставить».

`Where-Object` можно писать короче (PS 3+):

```powershell
Get-Service | Where-Object Status -eq 'Stopped'      # короткая форма
Get-Service | Where-Object { $_.Status -eq 'Stopped' } # полная, работает всегда
```

## 6. Сортировка, подсчёт, группировка

```powershell
Get-Process | Sort-Object CPU -Descending | Select-Object -First 5 Name, CPU
Get-Service | Measure-Object                          # сколько всего
Get-Service | Group-Object Status                     # сколько Running, сколько Stopped
Get-ChildItem C:\Windows -File | Measure-Object Length -Sum
```

`Measure-Object` отвечает на вопрос «сколько/сумма/среднее», `Group-Object` — «сколько в каждой категории».

## 7. Переменные и кавычки

```powershell
$svc = Get-Service Spooler     # в переменной лежит ОБЪЕКТ, не текст
$svc.Status                    # Running
$svc.Name                      # Spooler
```

Знак `$` — часть имени переменной, он обязателен всегда.

Кавычки:

```powershell
$name = 'DC01'

"Сервер $name"        # Сервер DC01      — двойные кавычки подставляют переменные
'Сервер $name'        # Сервер $name      — одинарные не подставляют

$svc = Get-Service Spooler
"Статус: $svc.Status"      # Статус: System.ServiceProcess.ServiceController.Status  ← НЕ работает
"Статус: $($svc.Status)"   # Статус: Running                                        ← работает
```

`$()` означает «сначала вычисли то, что в скобках, потом подставь». Нужно всегда, когда внутри строки не простая переменная, а свойство или выражение.

## 8. Массивы и перебор

```powershell
$servers = @('DC01', 'DC02', 'APP01')   # массив
$servers.Count                          # 3
$servers[0]                             # DC01

foreach ($s in $servers) {
    "Проверяю $s"
}
```

`foreach` — обычный цикл «для каждого элемента». Через конвейер то же самое короче:

```powershell
$servers | ForEach-Object { "Проверяю $_" }
```

`ForEach-Object` (в конвейере) и `foreach` (обычный цикл) делают одно и то же; в коротких однострочниках удобнее первый.

## 9. Своя таблица данных: `[PSCustomObject]`

Нужно, чтобы результат выглядел как строка таблицы с нужными колонками — например, для CSV:

```powershell
[PSCustomObject]@{
    Computer = $env:COMPUTERNAME
    User     = $env:USERNAME
    OS       = (Get-CimInstance Win32_OperatingSystem).Caption
}
```

```text
Computer  User      OS
--------  ----      --
PC-042    ivanov    Microsoft Windows 11 Pro
```

`@{ Ключ = Значение }` — хеш-таблица (словарь). `[PSCustomObject]` превращает её в объект с именованными свойствами. Так строят отчёты: собрал объект → `Export-Csv`.

## 10. Ошибки

По умолчанию ошибка печатается, но скрипт продолжает работу. Чтобы её поймать:

```powershell
try {
    Get-Item 'C:\нет-такого-файла.txt' -ErrorAction Stop
}
catch {
    "Не получилось: $($_.Exception.Message)"
}
```

`-ErrorAction Stop` превращает обычную ошибку в исключение, иначе `catch` не сработает.

```powershell
Get-Item 'C:\нет-такого-файла.txt' -ErrorAction SilentlyContinue   # не показывать ошибку
$Error[0]                                                          # последняя ошибка
```

## 11. Файлы и поиск

```powershell
Get-ChildItem C:\Logs -Filter *.log -Recurse
Get-ChildItem C:\Logs -Recurse -File | Where-Object Length -gt 100MB
Get-ChildItem C:\Logs -Recurse -File | Sort-Object LastWriteTime -Descending | Select-Object -First 5
Get-Content C:\Logs\app.log -Tail 20          # последние 20 строк
```

`-Recurse` — с подпапками, `-File` — только файлы, `-Filter` — быстрый фильтр по имени.

## 12. Что ещё нужно знать про запуск скриптов

```powershell
Get-ExecutionPolicy -List        # текущие политики
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
Unblock-File .\script.ps1        # снять метку «скачано из интернета»
```

Политика выполнения — защита от случайного запуска чужого кода. `RemoteSigned` разрешает локальные скрипты и требует подпись для скачанных. В домене политику обычно задаёт GPO, и `Set-ExecutionPolicy` может не сработать — это нормально.

Файл скрипта — обычный текст с расширением `.ps1`. Запуск: `.\script.ps1` (точка и обратный слэш обязательны).

## 13. Как читать чужой скрипт

1. Найди блок `param(...)` в начале — это входные параметры.
2. Иди сверху вниз, не пытаясь понять всё сразу.
3. Каждую незнакомую команду проверь через `Get-Help <команда> -Examples`.
4. Выпиши переменные и что в них лежит (объект? строка? массив?).
5. Найди места, где что-то **меняется** (`Set-`, `New-`, `Remove-`, `Start-`, `Stop-`) — там основной риск.
6. Если команда меняет систему, проверь её с `-WhatIf`.

## 14. Шпаргалка

| Команда | Что делает |
|---|---|
| `Get-Help <cmd> -Examples` | примеры использования |
| `Get-Command *слово*` | найти команду |
| `Get-Member` | свойства и методы объекта |
| `Select-Object A, B` | оставить колонки A и B |
| `Where-Object { условие }` | фильтр |
| `Sort-Object Prop -Descending` | сортировка |
| `Select-Object -First 5` | первые 5 |
| `Measure-Object -Sum` | количество/сумма/среднее |
| `Group-Object Prop` | группировка |
| `ForEach-Object { ... }` | действие для каждого |
| `Get-ChildItem -Recurse -File` | файлы рекурсивно |
| `Get-Content -Tail 20` | последние строки файла |
| `Test-Path C:\x` | существует ли путь |
| `Test-NetConnection host -Port 443` | доступность порта |
| `Export-Csv file.csv -NoTypeInformation` | выгрузить в CSV |
| `-WhatIf` | показать, что было бы сделано |

## 15. Упражнения (с ответами)

**1. Показать 5 процессов, которые едят больше всего памяти.**

```powershell
Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 5 Name, WorkingSet64
```

**2. Найти все остановленные службы.**

```powershell
Get-Service | Where-Object Status -eq 'Stopped'
```

**3. Посчитать, сколько служб в каждом состоянии.**

```powershell
Get-Service | Group-Object Status | Select-Object Name, Count
```

**4. Найти в `C:\Temp` файлы старше 30 дней.**

```powershell
Get-ChildItem C:\Temp -Recurse -File |
    Where-Object LastWriteTime -lt (Get-Date).AddDays(-30)
```

**5. Вывести имя компьютера и версию Windows одной строкой.**

```powershell
"$env:COMPUTERNAME — $((Get-CimInstance Win32_OperatingSystem).Caption)"
```

## 16. Типичные ошибки новичка

- Использовать алиасы (`ls`, `dir`, `?`) в скриптах: в чужой сессии они могут означать другое. В консоли — можно, в скрипте — полные имена.
- Забыть `$_` внутри `Where-Object { ... }`.
- Путать `=` (присваивание) и `-eq` (сравнение).
- Ждать, что `try/catch` поймает ошибку без `-ErrorAction Stop`.
- Забыть, что для `Stop-Service`, `New-Item` в системных папках нужны права администратора.
- Пути с пробелами без кавычек: `C:\Program Files` → `'C:\Program Files'`.
- Думать, что `>` перенаправляет объекты: `>` пишет текст, для объектов — `Export-Csv`/`Out-File`.

## 17. Чек-лист диагностики

1. Не помню команду → `Get-Command *ключевое*`.
2. Не помню синтаксис → `Get-Help <cmd> -Examples`.
3. Не понимаю результат → `| Get-Member`, затем `| Select-Object *`.
4. Не работает фильтр → проверь `$_` и тип свойства (`$_.Length` — число или строка?).
5. Скрипт не запускается → `Get-ExecutionPolicy -List`, `Unblock-File`.
6. Команда «ничего не делает» → проверь, не съел ли её пайплайн, и `$Error[0]`.
7. Ошибка доступа → запусти консоль от администратора.
8. Версия не та → `$PSVersionTable` (5.1 Desktop или 7.x Core).

## 18. Вопросы на собеседовании

**Чем PowerShell отличается от cmd?** Возвращает объекты с именованными свойствами, а не текст, поэтому фильтрация и передача по конвейеру не требуют разбора строк.

**Что такое cmdlet?** Команда вида `Глагол-Существительное`, обычно на .NET; принимает объекты из конвейера и общие параметры вроде `-WhatIf`.

**Что такое `$_`?** Текущий объект в конвейере внутри блоков `Where-Object`, `ForEach-Object`, `Select-Object`.

**Как узнать, какие свойства есть у результата?** `Get-Member`; посмотреть значения — `Select-Object *`.

**Зачем `-WhatIf`?** Показать, что команда собирается изменить, не выполняя изменений.

**Почему в скриптах не используют алиасы?** Они зависят от хоста и версии, могут быть переопределены и хуже читаются.

**Чем `foreach` отличается от `ForEach-Object`?** `foreach` — конструкция языка (быстрее, не в конвейере), `ForEach-Object` — команда конвейера, удобна в однострочниках.

## См. также

- [[Системное администрирование/PowerShell/PowerShell в администрировании Windows|PowerShell в администрировании Windows]] — те же приёмы на реальных задачах
- [[Системное администрирование/PowerShell/PowerShell и Active Directory|PowerShell и Active Directory]]
- [[Системное администрирование/Windows/Диагностика и восстановление Windows|Диагностика Windows]]
