# Сетевые параметры Windows

Всё, что нужно, чтобы настроить сеть на рабочей станции и объяснить «почему у одного пользователя не работает интернет». Основные инструменты: `ncpa.cpl`, `ipconfig`, `netsh`, `Get-Net*` и встроенные диагностики.

## Параметры адаптера

| Параметр | Где | Замечание |
|---|---|---|
| IP-адрес | `ncpa.cpl` → IPv4 → свойства | в офисе чаще DHCP, статика — для серверов/принтеров |
| Маска | там же | определяет подсеть |
| Шлюз | там же | без него нет выхода за пределы подсети |
| DNS | там же | внутренний DNS (DC) для домена, внешний — как forwarder |
| DNS-суффикс | `sysdm.cpl` → имя компьютера → дополнительно | нужен для коротких имён в домене |
| Метрика | `Get-NetIPInterface`, Advanced → Metric | при двух адаптерах определяет приоритет |
| Speed/Duplex | свойства адаптера → Configure → Advanced | автоподбор обычно лучше ручного |

Адрес `169.254.x.x` — APIPA: DHCP не ответил. Это диагноз, а не настройка.

## `ipconfig` — базовый минимум

```text
ipconfig /all           :: полная конфигурация: MAC, DHCP, DNS, lease
ipconfig /release       :: отказаться от адреса (DHCP)
ipconfig /renew         :: запросить заново
ipconfig /flushdns      :: очистить DNS-кэш
ipconfig /displaydns    :: показать кэш
ipconfig /registerdns   :: перерегистрировать имя в DNS
```

## `netsh` — когда GUI недоступен

```text
netsh interface ip show config
netsh interface ip set address name="Ethernet" static 10.0.0.50 255.255.255.0 10.0.0.1
netsh interface ip set dns name="Ethernet" static 10.0.0.10
netsh interface ip set address name="Ethernet" dhcp
netsh wlan show profiles
netsh wlan show profile name="CorpWiFi" key=clear
netsh winhttp show proxy
netsh int ip reset            :: сброс стека (после — перезагрузка)
netsh winsock reset           :: сброс Winsock (после — перезагрузка)
netsh advfirewall show allprofiles
```

## Диагностика по слоям

| Уровень | Команда | Что проверяем |
|---|---|---|
| Кабель/Wi-Fi | `Get-NetAdapter`, индикаторы | link up, скорость, ошибки |
| IP | `ipconfig /all` | адрес, маска, шлюз, DHCP-сервер |
| L2 | `arp -a` | MAC шлюза в таблице ARP |
| L3 | `ping 10.0.0.1`, `tracert`, `pathping` | доступность шлюза и маршрут |
| DNS | `nslookup server.corp.local`, `Resolve-DnsName` | резолвинг имён |
| TCP | `Test-NetConnection host -Port 443`, `netstat -ano` | порт открыт, кто слушает |
| Приложение | `curl`, браузер, логи | прокси, сертификат, аутентификация |

`ping` может быть заблокирован файрволом — отсутствие ответа не доказывает отсутствие связи. Проверяйте порт (`Test-NetConnection -Port`).

## Профили сети и брандмауэр

- Профили: Domain / Private / Public. От профиля зависит, что разрешает `wf.msc`.
- Домен определяется по доступности DC; «сеть стала Public» — частая причина «не видно шар и принтеров».
- Сброс профиля: `Get-NetConnectionProfile`, `Set-NetConnectionProfile -NetworkCategory Private`.
- Правила: `wf.msc` → входящие/исходящие, либо `New-NetFirewallRule -DisplayName "..." -Direction Inbound -Protocol TCP -LocalPort 3389 -Action Allow`.
- Включение: `Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True`.

## Прокси, VPN, диски

- Прокси: «Параметры» → «Сеть» → «Прокси»; системный WinHTTP отдельно — `netsh winhttp show proxy` / `import proxy source=ie`.
- VPN: клиент, профиль, маршруты (`route print`), «подключено, но нет доступа» — DNS или split tunneling.
- Сетевые диски: `net use Z: \\server\share /persistent:yes`, `net use * /delete`, `cmdkey /list` для сохранённых учёток.

## Типовые сбои

| Симптом | Причина | Решение |
|---|---|---|
| 169.254.x.x | DHCP недоступен | кабель/VLAN, DHCP-сервер, `ipconfig /renew` |
| Пинг по IP есть, по имени нет | DNS | `nslookup`, DNS-сервер, суффикс, `flushdns` |
| Нет интернета, локальная сеть работает | шлюз/DNS/прокси | `ping` шлюза, `tracert 8.8.8.8`, прокси |
| Сайт открывается, приложение нет | порт/прокси/сертификат | `Test-NetConnection -Port`, логи приложения |
| «Не видно» другие ПК | профиль сети/обнаружение | Private-профиль, сетевое обнаружение, файрвол |
| Постоянные обрывы Wi-Fi | канал, драйвер, питание адаптера | смена канала, драйвер, отключить энергосбережение |
| Медленно | дуплекс, ошибки, загрузка канала | скорость/дуплекс, `netstat`, QoS |

## Чек-лист диагностики

1. `ipconfig /all` — адрес, маска, шлюз, DNS, DHCP, суффикс. APIPA → проблема DHCP.
2. `ping` шлюза, затем внешнего IP (`8.8.8.8`), затем имени.
3. Если IP пингуется, а имя нет — `nslookup` и `ipconfig /flushdns`, проверить DNS-сервер.
4. `Test-NetConnection <host> -Port <port>` — проверить конкретный сервис.
5. `netstat -ano` + PID в Task Manager — кто слушает порт.
6. Проверить профиль сети, файрвол, прокси, VPN.
7. `netsh int ip reset` / `winsock reset` — только после всего остального, с перезагрузкой.
8. Зафиксировать адрес, шлюз, DNS и результат проверок в заявке.

## Вопросы на собеседовании

**Что такое APIPA и о чём он говорит?** 169.254.x.x — клиент не получил адрес по DHCP: нет связи с DHCP, не тот VLAN, сервер лежит.

**Пользователь не открывает внутренний сайт, внешние работают. Почему?** Скорее всего DNS/маршрут до внутренней сети/VPN; проверять `nslookup`, `route print`, прокси.

**Чем ping отличается от проверки порта?** Ping — ICMP, может быть запрещён; `Test-NetConnection -Port` проверяет реальный TCP-порт сервиса.

**Зачем `ipconfig /flushdns`?** Сбрасывает локальный кэш DNS, помогает после смены записи или при устаревшем/отравленном ответе.

**Как понять, кто занял порт 3389?** `netstat -ano | findstr :3389`, затем PID в Task Manager/`Get-Process -Id`.

## См. также

- [[Системное администрирование/Сетевые службы/DNS на практике|DNS на практике]]
- [[Системное администрирование/Сетевые службы/DHCP на практике|DHCP на практике]]
- [[Системное администрирование/Сетевые службы/RDP и удалённый доступ|RDP]]
- [[Сети/темы/Стек протоколов TCP-IP|Стек TCP/IP]]
