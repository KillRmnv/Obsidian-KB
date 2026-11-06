# Реестр Windows

Реестр — иерархическая база настроек ОС и приложений. Для L1–L2 важно не «чистить реестр», а уметь найти нужный параметр, сделать бэкап ветки и объяснить, почему правка через реестр — это то же самое, что правка через GUI.

## Кусты и файлы

| Куст | Сокращение | Файл | Что внутри |
|---|---|---|---|
| HKEY_CLASSES_ROOT | HKCR | собирается из HKLM\Software\Classes + HKCU\Software\Classes | ассоциации файлов, COM |
| HKEY_CURRENT_USER | HKCU | `C:\Users\<user>\NTUSER.DAT` | настройки текущего пользователя |
| HKEY_LOCAL_MACHINE | HKLM | `SYSTEM`, `SOFTWARE`, `SAM`, `SECURITY` в `C:\Windows\System32\config` | настройки компьютера |
| HKEY_USERS | HKU | профили всех загруженных пользователей | HKCU — это HKU\<SID> |
| HKEY_CURRENT_CONFIG | HKCC | ссылка на текущий профиль оборудования | параметры железа |

Типы значений: `REG_SZ` (строка), `REG_EXPAND_SZ` (со `%переменными%`), `REG_DWORD` (32 бита), `REG_QWORD` (64), `REG_MULTI_SZ`, `REG_BINARY`.

Важно: 64-битная система держит 32-битные приложения в `HKLM\SOFTWARE\WOW6432Node` — параметр может лежать «не там», где его ищет regedit по умолчанию.

## `reg.exe` — работа из командной строки

```text
reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v ProductName
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Run"
reg add  "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /t REG_DWORD /d 1 /f
reg delete "HKCU\Software\Vendor\App" /f
reg export "HKLM\SOFTWARE\Vendor" C:\backup\vendor.reg /y
reg import C:\backup\vendor.reg
reg compare "HKLM\SOFTWARE\Vendor" "\\pc02\HKLM\SOFTWARE\Vendor"
```

- `/f` — без подтверждения, `/y` — перезаписать файл.
- В PowerShell удобнее провайдер: `Get-ItemProperty 'HKLM:\SOFTWARE\Vendor'`, `Set-ItemProperty`, `New-ItemProperty`, `New-PSDrive -PSProvider Registry`.
- `regedit` умеет подключать чужие кусты: выделить `HKLM` → File → Load Hive (например, `D:\Windows\System32\config\SOFTWARE` офлайн-системы). Не забыть Unload.

## Где админ реально правит реестр

| Задача | Ветка |
|---|---|
| Автозапуск | `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run` (+ `RunOnce`, `HKCU\...\Run`) |
| Службы | `HKLM\SYSTEM\CurrentControlSet\Services\<name>` (Start, ImagePath, ObjectName) |
| Автовход | `HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon` (`AutoAdminLogon`, `DefaultUserName`) |
| RDP | `HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server` → `fDenyTSConnections=0` |
| USB-накопители | `HKLM\SYSTEM\CurrentControlSet\Services\USBSTOR` → `Start=4` |
| Политики | `HKLM\SOFTWARE\Policies\...` и `HKCU\SOFTWARE\Policies\...` (перекрывают пользовательские настройки) |
| Удалённый доступ/прокси | `HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings` |
| Профили пользователей | `HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\<SID>` |
| Часовой пояс | `HKLM\SYSTEM\CurrentControlSet\Control\TimeZoneInformation` |
| Сетевые профили | `HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\Profiles` |

Правило: если настройка есть в GPO, её не правят реестром — GPO перезапишет значение при следующем `gpupdate`.

## Безопасность и бэкап

- Перед правкой: `reg export` ветки, точка восстановления, в идеале — снимок VM.
- Права на ключи: `regedit` → Permissions, либо `regini`; владельца меняют через Advanced → Owner.
- `.reg`-файл — обычный текст: `Windows Registry Editor Version 5.00` + ветка + значения. Импорт двойным кликом или `reg import`.
- Никаких «оптимизаторов реестра»: выигрыша нет, риск сломать загрузку реальный.
- Правка `HKLM\SYSTEM` без понимания может сделать систему незагружаемой — только с бэкапом.

## Чек-лист диагностики

1. Уточнить, что именно не работает и какая настройка должна это исправлять (GUI-путь).
2. Найти ветку через GUI или поиск в regedit; проверить тип и текущее значение.
3. Сравнить с эталонной машиной (`reg export` там и здесь, `reg compare`).
4. Сделать экспорт ветки и точку восстановления.
5. Изменить значение, перезапустить службу/приложение или перезагрузиться.
6. Проверить, не перекрывает ли значение политика в `...\Policies\...` или GPO (`gpresult /r`).
7. Если система не загружается после правки — WinRE → `regedit` → Load Hive → откатить значение.
8. Зафиксировать в заявке ветку, параметр, старое и новое значение.

## Вопросы на собеседовании

**Чем HKLM отличается от HKCU?** HKLM — настройки компьютера для всех пользователей, HKCU — только текущего (файл NTUSER.DAT).

**Где хранится автозагрузка?** `Run`/`RunOnce` в HKLM и HKCU, плюс папка Startup и планировщик; проверять все три места.

**Как отключить RDP через реестр?** `HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server`, `fDenyTSConnections = 1`.

**Почему параметр не применяется?** Его перекрывает GPO/политика, либо приложение пишет своё значение при старте; проверять `gpresult` и ветку Policies.

**Как поправить реестр незагружающейся системы?** Загрузиться в WinRE, открыть regedit, Load Hive нужный куст из `System32\config`, изменить, Unload, перезагрузиться.

## См. также

- [[Системное администрирование/Windows/Диагностика и восстановление Windows|Диагностика и восстановление]]
- [[Системное администрирование/Windows/Сетевые параметры Windows|Сетевые параметры]]
- [[Системное администрирование/Active Directory/Групповые политики (GPO)|Групповые политики]]
- [[Системное администрирование/PowerShell/PowerShell в администрировании Windows|PowerShell в администрировании]]
