# PowerShell и Active Directory

AD администрируют двумя способами: мышкой в `dsa.msc` (ADUC) и командами. Команды нужны, когда объектов много: создать 30 пользователей, найти всех, кто не заходил 90 дней, проверить состав групп. Здесь — минимум, который спрашивают, с объяснением каждого шага.

## Подготовка

Модуль `ActiveDirectory` ставится вместе с RSAT:

```powershell
# Windows 10/11, PowerShell от администратора
Add-WindowsCapability -Online -Name Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0
Import-Module ActiveDirectory
Get-Command -Module ActiveDirectory | Measure-Object      # сколько команд доступно
```

Если команды `Get-ADUser` не найдены — модуль не установлен или вы в PowerShell без нужной разрядности (64-бит).

## Как устроены команды AD

Почти все они начинаются с `Get-AD…`, `New-AD…`, `Set-AD…`, `Remove-AD…` и работают с объектами: пользователь, группа, компьютер, OU.

Важная особенность `Get-ADUser`: по умолчанию возвращает **мало свойств**. Дополнительные нужно просить через `-Properties`:

```powershell
Get-ADUser ivanov                                   # базовые поля
Get-ADUser ivanov -Properties Department, Title, LastLogonDate
```

Смотри, что доступно: `Get-ADUser ivanov -Properties * | Get-Member`.

## Найти пользователя

```powershell
Get-ADUser -Identity ivanov                         # по логину (SamAccountName)
Get-ADUser -Filter "Surname -eq 'Иванов'"           # по фамилии
Get-ADUser -Filter "Department -eq 'Бухгалтерия'" -Properties Department |
    Select-Object Name, SamAccountName, Department
Get-ADUser -LDAPFilter "(sAMAccountName=ivan*)"     # маска по логину
Get-ADUser -Filter * -SearchBase "OU=Users,OU=Corp,DC=corp,DC=local"
```

Разница фильтров:

| Способ | Когда использовать |
|---|---|
| `-Filter "свойство -eq 'значение'"` | обычные условия, синтаксис PowerShell |
| `-Filter { ... }` | сложные условия, но осторожно с переменными |
| `-LDAPFilter "(...)"` | маски, вложенные условия, привычный LDAP-синтаксис |
| `-SearchBase "OU=..."` | искать только в конкретном подразделении |

`-Filter` не понимает переменные в кавычках так, как кажется: `"Name -eq '$name'"` подставит значение, а `-Filter { Name -eq $name }` может повести себя иначе. Для скриптов безопаснее собрать строку заранее.

## Состояния учётных записей

```powershell
Search-ADAccount -LockedOut
Search-ADAccount -AccountDisabled
Search-ADAccount -PasswordNeverExpires
Search-ADAccount -AccountInactive -TimeSpan 90.00:00:00 -UsersOnly
```

`Search-ADAccount` — готовые отчёты «кто заблокирован / отключён / не заходил». Это быстрее, чем писать фильтры вручную.

Разблокировать и включить:

```powershell
Unlock-ADAccount -Identity ivanov
Enable-ADAccount -Identity ivanov
Disable-ADAccount -Identity ivanov
```

## Создать пользователя

```powershell
$password = Read-Host -AsSecureString 'Пароль для нового пользователя'

New-ADUser `
    -Name "Иван Иванов" `
    -GivenName "Иван" `
    -Surname "Иванов" `
    -SamAccountName "ivanov" `
    -UserPrincipalName "ivanov@corp.local" `
    -Path "OU=Users,OU=Corp,DC=corp,DC=local" `
    -AccountPassword $password `
    -Enabled $true `
    -ChangePasswordAtLogon $true
```

Разбор:

- `-Name` — отображаемое имя, `-SamAccountName` — логин для входа (до 20 символов).
- `-UserPrincipalName` — логин в формате `login@domain`, по нему входят в современные сервисы.
- `-Path` — OU, куда положить объект. Если не указать, попадёт в `CN=Users` в корне домена.
- `-AccountPassword` принимает **защищённую строку**, поэтому `Read-Host -AsSecureString`.
- `-Enabled $true` — без этого учётка создастся отключённой.
- `-ChangePasswordAtLogon $true` — попросить сменить пароль при первом входе.

Обратная кавычка `` ` `` — перенос длинной команды на новую строку.

## Группы

```powershell
Get-ADGroupMember "Domain Admins" -Recursive | Select-Object Name, SamAccountName, objectClass
Add-ADGroupMember -Identity "GG-IT-Support" -Members ivanov, petrov
Remove-ADGroupMember -Identity "GG-IT-Support" -Members petrov -Confirm:$false
New-ADGroup -Name "GG-Finance-Read" -GroupScope Global -GroupCategory Security `
    -Path "OU=Groups,OU=Corp,DC=corp,DC=local"
```

`-Recursive` важен: без него вы увидите только прямых членов, а не вложенные группы. Именно поэтому «я добавил его в группу, а доступа нет» — проверять надо цепочку.

Найти пустые группы:

```powershell
Get-ADGroup -Filter * -Properties Members |
    Where-Object { $_.Members.Count -eq 0 } |
    Select-Object Name
```

## Компьютеры

```powershell
Get-ADComputer -Filter * -Properties LastLogonTimeStamp |
    Where-Object { $_.LastLogonTimeStamp -lt (Get-Date).AddDays(-90) } |
    Select-Object Name, LastLogonDate
```

`LastLogonTimeStamp` обновляется не мгновенно (репликация, до 14 дней), но для поиска «мёртвых» машин подходит. Точное значение — атрибут `LastLogon`, он не реплицируется между DC.

## Переместить объект в другой OU

```powershell
Move-ADObject -Identity "CN=Иван Иванов,OU=Users,OU=Corp,DC=corp,DC=local" `
    -TargetPath "OU=Archive,OU=Corp,DC=corp,DC=local"
```

## Массовое создание из CSV

Файл `C:\Temp\users.csv`:

```text
SamAccountName,FirstName,LastName,Department
ivanov,Иван,Иванов,Бухгалтерия
petrov,Пётр,Петров,ИТ
sidorov,Сидор,Сидоров,ИТ
```

Скрипт:

```powershell
param(
    [string]$CsvPath = 'C:\Temp\users.csv',
    [string]$OuPath  = 'OU=Users,OU=Corp,DC=corp,DC=local'
)

$defaultPassword = Read-Host -AsSecureString 'Пароль для новых учёток'

Import-Csv $CsvPath | ForEach-Object {
    $login = $_.SamAccountName

    if (Get-ADUser -Filter "SamAccountName -eq '$login'" -ErrorAction SilentlyContinue) {
        Write-Warning "$login уже есть — пропускаю"
        return
    }

    try {
        New-ADUser -Name "$($_.FirstName) $($_.LastName)" `
            -GivenName $_.FirstName -Surname $_.LastName `
            -SamAccountName $login -UserPrincipalName "$login@corp.local" `
            -Path $OuPath -AccountPassword $defaultPassword `
            -Enabled $true -ChangePasswordAtLogon $true

        Write-Host "Создан: $login"
    }
    catch {
        Write-Warning "Ошибка для ${login}: $($_.Exception.Message)"
    }
}
```

Что здесь важно понять:

- `Import-Csv` превращает каждую строку файла в объект, колонки становятся свойствами: `$_.SamAccountName`.
- Проверка `if (Get-ADUser ...)` защищает от повторного запуска: скрипт можно запускать дважды.
- `return` внутри `ForEach-Object` пропускает текущую строку и переходит к следующей.
- `try/catch` не даёт упасть всему циклу из-за одного плохого пользователя.
- Если запустить без `-WhatIf`-защиты, учётки создадутся сразу. Сначала прогони на тестовом OU.

## Отчёты

Кто входит в группу администраторов:

```powershell
Get-ADGroupMember "Domain Admins" -Recursive |
    Select-Object Name, SamAccountName |
    Export-Csv C:\Reports\domain-admins.csv -NoTypeInformation
```

Учётки с бессрочным паролем:

```powershell
Get-ADUser -Filter { PasswordNeverExpires -eq $true } -Properties PasswordNeverExpires |
    Select-Object Name, SamAccountName
```

Информация о домене:

```powershell
Get-ADDomain | Select-Object Name, DomainMode, PDCEmulator
Get-ADForest | Select-Object Name, ForestMode, GlobalCatalogs
Get-ADOrganizationalUnit -Filter * | Select-Object Name, DistinguishedName
```

## Что модуль не умеет

Для части задач (нестандартные атрибуты, работа с объектами, которых нет в модуле) используют ADSI:

```powershell
$user = [ADSI]"LDAP://CN=Иван Иванов,OU=Users,OU=Corp,DC=corp,DC=local"
$user.Description = "Бухгалтерия, каб. 305"
$user.SetInfo()
```

Но в 95% случаев хватает командлетов, а ADSI оставь на крайний случай.

## Безопасность

- Не хранить пароли в скрипте. `Read-Host -AsSecureString`, `Get-Credential` или Windows Credential Manager.
- Перед массовыми изменениями — тестовый OU или пользователь.
- Не удалять (`Remove-ADUser`), а отключать и перемещать в архив: удаление необратимо без бэкапа/корзины AD.
- Проверять, что скрипт запущен под нужной учёткой: `whoami /all`.
- Логировать, что сделано: `Write-Host`/`Start-Transcript` в файл.

## Чек-лист диагностики

1. `Get-ADUser` не найдена — модуль RSAT не установлен (`Get-Module -ListAvailable ActiveDirectory`).
2. Пользователь не находится — проверить `-Identity` (логин), `-Filter` (фамилия), `-SearchBase` (OU), права.
3. Свойство пустое — не запрошено через `-Properties`.
4. Не создаётся учётка — проверить OU, уникальность логина, сложность пароля, права делегирования.
5. «Нет доступа» у пользователя — проверить `Get-ADGroupMember -Recursive` и вложенность групп.
6. Учётка заблокирована — `Search-ADAccount -LockedOut`, источник в Event 4740, затем `Unlock-ADAccount`.
7. Команда сработала не на том DC — репликация: `repadmin /replsummary`, подождать или указать `-Server`.
8. Массовый скрипт — сначала на одном тестовом пользователе, затем на всех.

## Вопросы на собеседовании

**Как создать пользователя в AD через PowerShell?** `New-ADUser` с `-Name`, `-SamAccountName`, `-UserPrincipalName`, `-Path`, `-AccountPassword`, `-Enabled $true`.

**Как найти всех, кто не заходил 90 дней?** `Search-ADAccount -AccountInactive -TimeSpan 90.00:00:00 -UsersOnly` или фильтр по `LastLogonTimeStamp`.

**Почему свойство пустое, хотя в ADUC оно заполнено?** `Get-ADUser` по умолчанию отдаёт ограниченный набор; нужно `-Properties <имя>`.

**Чем `-Filter` отличается от `-LDAPFilter`?** Первый — синтаксис PowerShell, второй — LDAP-выражение с масками; оба фильтруют на стороне DC.

**Как добавить 50 человек в группу?** `Add-ADGroupMember -Identity Group -Members (Get-Content logins.txt)` или цикл по CSV.

**Почему после добавления в группу доступа нет?** Пользователь должен перелогиниться (обновление токена Kerberos), плюс проверить вложенные группы и права на ресурсе.

## См. также

- [[Системное администрирование/PowerShell/PowerShell. Основы|PowerShell. Основы]]
- [[Системное администрирование/PowerShell/PowerShell в администрировании Windows|PowerShell в администрировании Windows]]
- [[Системное администрирование/Active Directory/Пользователи и группы AD|Пользователи и группы AD]]
- [[Системное администрирование/Active Directory/Active Directory. Основы|Active Directory. Основы]]
