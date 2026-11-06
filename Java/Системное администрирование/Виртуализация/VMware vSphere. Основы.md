# VMware vSphere. Основы

vSphere — платформа виртуализации: ESXi исполняет ВМ, vCenter управляет парком хостов. Ниже — состав платформы, расход ресурсов, снапшоты и точки диагностики для L1–L2.

## ESXi и vCenter

| Компонент | Что это | Зачем |
|---|---|---|
| ESXi | Гипервизор типа 1 на железе | Запускает ВМ, распределяет CPU/RAM/устройства |
| vCenter Server | Центр управления (обычно VCSA) | Кластеры, HA/DRS, шаблоны, права, алерты, API |
| vSphere Client | Web-интерфейс | Работа руками |
| SSO | Единая аутентификация | Один логин на vCenter и сервисы |

Без vCenter хостом можно управлять через Host Client, но не будет HA/DRS, шаблонов и централизованных прав. vCenter не точка отказа для работающих ВМ: при его падении ВМ живут, но управление и HA недоступны.

## Инвентарь

**Datacenter → Cluster → Host → VM**: datacenter — логический контейнер, cluster — группа хостов с общими HA/DRS, host — ESXi, VM — гостевая машина. Папки нужны только для организации и прав, ресурсов не дают.

## vCPU и RAM

- vCPU — поток, планируемый на физическое ядро; «сокеты × ядра» в ВМ влияют на лицензирование гостевой ОС, не на скорость.
- Overcommit vCPU — норма (2–4 на ядро). При перегрузке растёт **CPU ready (%RDY)** — ожидание ядра; устойчиво выше ~5% на vCPU — нехватка CPU.
- **Reservation** — гарантия физической RAM при старте ВМ. **Ballooning** (`vmmemctl`) отдаёт страницы хосту, **hypervisor swapping** пишет их в `.vswp`, compression сжимает перед свопом — всё это просадка latency.
- Overcommit RAM допустим на фактическом потреблении, но критичным ВМ (SQL, 1С, DC) нужен reservation, иначе при дефиците их ждёт ballooning и swap.

## Диск, datastore, thin/thick

Файлы ВМ: `.vmx` (конфиг), `.vmdk` (диск), `.nvram`, `.log`, при снапшоте — delta. Контроллер: `pvscsi` под нагрузку, `lsilogic`/`sata` для совместимости.

| Datastore | Доступ | Особенности |
|---|---|---|
| VMFS | Блочный (FC/iSCSI/SAS) | Кластерная ФС VMware, блокировки на уровне файла |
| NFS | Файловый по IP | Просто, часто для ISO, шаблонов, бэкапов |
| iSCSI | Блочный по IP | SAN без FC, зависит от сети и MTU |
| vSAN | SDS | Локальные диски хостов в общее хранилище, политики |

| Тип | Выделение | Когда |
|---|---|---|
| Thin | По факту записи | Экономия, риск переполнения datastore |
| Thick lazy zeroed | Весь объём, блоки обнуляются при записи | Предсказуемое место |
| Thick eager zeroed | Весь объём и обнулён | Кластеры, FT, требования приложений |

Thin требует контроля свободного места: сумма «выделено» может превышать ёмкость. Для критичных ВМ — `space reservation`.

## Сеть

- **vSwitch** — виртуальный коммутатор; standard настраивается на каждом хосте, distributed — из vCenter с едиными port groups.
- **Port group** — политики: VLAN ID, security, teaming/failover, shaping. **VLAN trunk** — ID 4095 пропускает все теги; на физическом порту нужен trunk.
- **VMkernel (vmk)** — служебный интерфейс: management, vMotion, iSCSI/NFS, vSAN; каждый трафик лучше в своей VLAN.
- `Promiscuous Mode`, `MAC Address Changes`, `Forged Transmits` по умолчанию `Reject`; promiscuous нужен для IDS и nested.
- **MTU** совпадает end-to-end, иначе большие кадры теряются; 9000 типично для vMotion, iSCSI, vSAN.

## VMware Tools

Драйверы (`vmxnet3`, `pvscsi`), graceful shutdown, heartbeat, синхронизация времени, ballooning и **quiescing** — заморозка ФС через VSS/sync для консистентного снапшота. Для Linux VMware рекомендует `open-vm-tools` из репозитория вместо bundled.

## Snapshot

Базовый диск становится read-only, записи идут в **delta-диск (redo log)**; можно сохранить и RAM. Удаление — **consolidation**: дельта переносится в базу, нужны время и место; при нехватке места операция зависает.

- Живёт на том же datastore и зависит от базы: потеря datastore — потеря и ВМ, и снапшота.
- Практический срок — часы (патч), не недели: дельта растёт, производительность падает.
- Технический предел — 32 в цепочке, но это не рекомендация.
- **«Consolidation needed»** — остались delta без слияния: запустить Consolidate и разобрать причину.
- Это **не бэкап**: нет копии на другом носителе, истории и защиты от удаления ВМ.

## Clone, template, vMotion

- **Clone** — копия ВМ; full независим, linked делит базовый диск и зависит от родителя.
- **Template** — read-only эталон для деплоя; **customization spec** задаёт hostname/IP/домен через sysprep (Windows) или cloud-init (Linux).
- **vMotion** переносит работающую ВМ на другой хост (нужны vMotion-сеть и совместимость CPU/EVC); **Storage vMotion** — диски между datastores без простоя.
- Оба механизма — обслуживание без окна простоя, но не замена отказоустойчивости хранилища.

## HA, DRS, resource pool

**HA** перезапускает ВМ при отказе хоста, **admission control** резервирует ресурсы под N отказов. **DRS** балансирует кластер (manual/partially/fully automated). **Resource pool**: shares — относительный приоритет при конкуренции, reservations — гарантия, limits — потолок.

## Права и роли

**Role** — набор privileges, **permission** — назначение роли пользователю/группе на объект с propagate; пользователи из SSO/AD. Не выдавать Administrator на root: helpdesk — read + console + reset, изменения через группы.

## PowerCLI

```powershell
Connect-VIServer -Server vcsa.corp.local -User 'CORP\admin'
Get-VM | Select-Object Name, PowerState, NumCpu, MemoryGB
Get-VM 'app01' | New-Snapshot -Name 'before-patch' -Memory:$false -Quiesce:$true
Get-Snapshot -VM 'app01' | Select-Object Name, Created, SizeGB
New-VM -Name 'test01' -Template 'Tpl-Win2022' -VMHost esxi01 -Datastore ds01
```

## Где смотреть проблемы

- **Tasks & Events** — кто что запустил и где ошибка; **Monitor → Performance** — CPU ready, balloon/swap, disk latency.
- Логи: `/var/log/vmkernel.log`, `hostd.log`, `vpxa.log`; в папке ВМ — `vmware.log`.

```text
esxcli vm process list
esxcli storage core path list
esxcli network vm list
esxcli hardware memory get
```

## Чек-лист диагностики

1. `Tasks & Events` — свежая ошибка и объект, к которому она относится.
2. Хост: `esxcli hardware memory get`, `esxcli vm process list`, связь с vCenter.
3. `Monitor → Performance`: CPU ready, balloon/swap, disk latency за период.
4. Свободное место на datastore и наличие «Consolidation needed».
5. Снапшоты: `Get-Snapshot -VM <vm>`, возраст и размер дельты.
6. Сеть: link state vmnic, VLAN/MTU на port group, шлюз из ВМ.
7. `vmware.log`/`hostd.log` — последняя ошибка перед сбоем; фиксация в тикете.

## Вопросы на собеседовании

**Зачем нужен vCenter, если есть Host Client?**
vCenter даёт кластерные функции: HA, DRS, шаблоны, distributed switch, права, алерты и API. Host Client — только один хост.

**Что такое CPU ready и когда это проблема?**
Время ожидания физического ядра. Устойчиво выше ~5% на vCPU — переподписка CPU; лечится снижением vCPU, добавлением хостов, разбором «шумного соседа».

**Чем снапшот отличается от бэкапа?**
Снапшот — delta на том же datastore, зависит от базы и не является копией. Бэкап — независимая копия, из которой восстановятся после потери datastore.

**Thin или thick — что выбрать?**
Thin экономит место, но требует алертов и контроля роста. Thick — предсказуемость и требования кластеров/FT; при гарантированном росте данных часто лучше thick lazy zeroed.

**Что будет с ВМ, если упадёт vCenter?**
Работающие ВМ продолжат работать, но управление и HA-реакция станут недоступны. Поэтому vCenter ставят в HA-кластер и бэкапят отдельно.

**Разница vMotion и Storage vMotion?**
Первый переносит вычислительное состояние на другой хост, второй — диски между datastores. Оба без простоя, задачи разные.

## См. также

- [[Системное администрирование/Виртуализация/Виртуальная инфраструктура|Виртуальная инфраструктура]]
- [[Системное администрирование/Резервное копирование/Veeam Backup & Replication|Veeam Backup & Replication]]
- [[Системное администрирование/Резервное копирование/Резервное копирование. Принципы|Принципы резервного копирования]]
- [[Системное администрирование/PowerShell/PowerShell. Основы|PowerShell]]
