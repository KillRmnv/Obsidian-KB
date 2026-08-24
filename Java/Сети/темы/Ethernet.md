## 1. Семейство технологий Ethernet

## Связанные темы

- [[Канальный уровень модели OSI]]
- [[Token Ring и FDDI]]

**Ethernet** — семейство технологий проводной пакетной передачи данных, описанное стандартом **IEEE 802.3**.[ionos+2][1]
Используется в LAN, MAN и даже в некоторых WAN. Работает на **физическом (L1)** и **канальном (L2)** уровнях модели OSI.

## 1.1. Общие свойства Ethernet

- **Метод доступа к среде:** CSMA/CD (Carrier Sense Multiple Access with Collision Detection) — множественный доступ с прослушиванием несущей и обнаружением коллизий.[nakivo+3][2]
 В классическом хаб‑Ethernet: логическая шина, half‑duplex, возможны коллизии.
 В современном коммутируемом Ethernet (switch): full‑duplex, коллизий нет, CSMA/CD по сути не используется.

- **Логическая топология:** шина (все станции логически «висят» на общем канале).[spu+3][3]

- **Физическая топология:** звезда или расширенная звезда (каждый хост подключен витой парой/оптикой к коммутатору или хабу).[sciencedirect+3][4]

- **Единица данных:** кадр Ethernet (Ethernet frame) с MAC‑адресами источника и назначения.[wikipedia+2][5]

## 1.2. Обозначения типов Ethernet

Имя стандарта обычно имеет вид, например: **10BASE‑T** или **1000BASE‑LX**.[piazza+3][6]

Расшифровка:

- **Первая часть — скорость:**

 - 10BASE‑… → 10 Мбит/с (классический Ethernet)

 - 100BASE‑… → 100 Мбит/с (Fast Ethernet)

 - 1000BASE‑… → 1 Гбит/с (Gigabit Ethernet)

 - 10GBASE‑… → 10 Гбит/с (10 Gigabit Ethernet)

 - 40GBASE‑…, 100GBASE‑… → 40/100 Гбит/с[wikipedia+3][7]

- **BASE** — передача в полосе (baseband).[ionos+1][1]

- **Последняя часть — тип среды / дальность:**

 - **‑T / ‑TX / ‑T1** — витая пара (Twisted Pair).[ipc2u+2][8]

 - **‑CX / ‑CX4** — медные спец‑кабели малой длины (jumper cable).[piazza+1][6]

 - **‑SX** — оптика, Short (850 нм, до ~300–550 м по MMF).[wikipedia+1][7]

 - **‑LX / ‑LR** — Long (обычно 1310 нм, до 5–10 км по SMF).[ipc2u+2][8]

 - **‑ER** — Extra Long (1550 нм, до 40 км).[piazza+1][6]

 - **‑T1** — однопарный Ethernet (Single Pair Ethernet) для авто/IoT.[wikipedia][7]

---

## 1.3. Основные поколения Ethernet «по скоростям»

## 10 Мбит/с — классический Ethernet

Примеры:[ptgmedia.pearsoncmg+3][9]

- **10BASE‑5** — «толстый» коаксиал (thicknet), до 500 м.

- **10BASE‑2** — «тонкий» коаксиал (thinnet), до 185 м.

- **10BASE‑T** — витая пара (две пары), физическая звезда через хаб/коммутатор, до 100 м.[lantronix+1][10]

Сегодня эти варианты практически не используются, кроме 10BASE‑T в совместимости.

## 100 Мбит/с — Fast Ethernet

Пример: **100BASE‑TX**.[nakivo+2][2]

- Среда: витая пара (2 пары Cat5 или лучше).

- Дальность: до 100 м.

- Широко применялся в 90‑х и 2000‑х, сейчас вытеснен Gigabit Ethernet.

## 1 Гбит/с — Gigabit Ethernet

Ключевой стандарт: **1000BASE‑T** (витая пара).[standards.ieee+4][11]

- Среда: 4 пары Cat5e/Cat6.

- Дальность: до 100 м.[vector+1][12]

- Модуляция: 4D‑PAM5, одновременно передача/приём по всем 4 парам.[wikipedia][7]

Другие варианты:

- **1000BASE‑SX** — оптика MMF, 850 нм, до 220–550 м.[piazza+1][6]

- **1000BASE‑LX** — оптика SMF, 1310 нм, до 5 км; MMF до 550 м.[piazza+1][6]

Gigabit Ethernet сейчас де‑факто стандарт для офисов и домашних сетей.[standards.ieee+1][11]

## 10 Гбит/с — 10 Gigabit Ethernet

Ключевой медный стандарт: **10GBASE‑T**.[tek+4][13]

- Среда: 4 пары Cat6/Cat6A.

- Дальность: до 100 м.[tek+2][13]

- Full‑duplex, сложная модуляция, требовательность к кабелю.

Оптические варианты:[standards.ieee+3][11]

- **10GBASE‑SR** — MMF, 850 нм, до 300–400 м.

- **10GBASE‑LR** — SMF, 1310 нм, до 10 км.

- **10GBASE‑ER** — SMF, 1550 нм, до 40 км.

10G активно используется в ЦОД, на ядре корпоративных сетей и для аплинков коммутаторов доступа.[ipc2u+1][8]

## 2.5G / 5G / 25G / 40G / 100G и дальше

- **2.5GBASE‑T, 5GBASE‑T (802.3bz)** — промежуточные скорости для старой Cat5e/Cat6, например, для Wi‑Fi 6/6E AP.[vector+1][12]

- **40GBASE‑T, 100GBASE‑T** — медь в ЦОД на короткие расстояния.[vector+1][12]

- Однопарный Ethernet: 10BASE‑T1, 100BASE‑T1, 1000BASE‑T1, 802.3ch (2.5/5/10/25G по одной паре) для авто и промышленности.[vector+1][12]

---

## 2. Технология PoE (Power over Ethernet)

**PoE (Power over Ethernet)** — технология, позволяющая передавать **электропитание постоянного тока** по тому же кабелю витой пары, что и данные Ethernet.[phihong+4][14]

PoE описывается стандартами **IEEE 802.3af / 802.3at / 802.3bt**.[ascentoptics+5][15]

## 2.1. Основные понятия PoE

**PSE (Power Sourcing Equipment)** — оборудование, подающее питание:[black-box+2][16]

- PoE‑коммутатор (PoE switch).

- PoE‑инжектор (midspan).

**PD (Powered Device)** — питаемое устройство:[tripplite.eaton+3][17]

- IP‑телефон.

- Точка доступа Wi‑Fi.

- IP‑камера видеонаблюдения.

- Контроллер доступа, IoT‑датчик, панель, мини‑ПК, светильник и т.п.

PoE позволяет:

- не тянуть отдельный силовой кабель и розетку к каждому устройству;

- включать/выключать питание удалённо (через управление сетью);

- проще резервировать питание (UPS на стороне коммутатора).

---

## 2.2. Стандарты PoE и уровни мощности

По IEEE различают **4 типа** PoE (Type 1–4).[skomplekt+5][18]

## Type 1 — PoE (IEEE 802.3af)[wikipedia+5][19]

- Год стандарта: 2003.[skomplekt+1][18]

- Макс. мощность на порту PSE: **15,4 Вт**.[phihong+5][14]

- Гарантированная мощность на PD (с учетом потерь в кабеле): **≈12,95 Вт**.[ascentoptics+4][15]

- Питание подается по **2 парам** витой пары (либо data‑пары, либо spare‑пары).[tripplite.eaton+3][17]

- Применение:[black-box+4][16]

 - VoIP‑телефоны.

 - Простые точки доступа Wi‑Fi.

 - Простые IP‑камеры (без PTZ, без подогрева).

## Type 2 — PoE+ (IEEE 802.3at)[cbtnuggets+5][20]

- Год стандарта: 2009.[phihong+1][14]

- Макс. мощность на порту PSE: **30 Вт**.[cbtnuggets+5][20]

- Мощность на PD: **≈25,5 Вт**.[wikipedia+5][19]

- По-прежнему используются **2 пары** для передачи питания.[ascentoptics+3][15]

- Применение:[cbtnuggets+4][20]

 - PTZ IP‑камеры (с поворотом/зумом).

 - Более мощные Wi‑Fi точки (Wi‑Fi 5/6).

 - Видеотерминалы, панельки.

**Выбор стандарта по мощности:**[cbtnuggets][20]

- До **13 Вт** → достаточно 802.3af.

- 13–25 Вт → нужен 802.3at.

## Type 3 / Type 4 — PoE++ (IEEE 802.3bt)[tripplite.eaton+5][17]

Стандарт 802.3bt (2018) ввёл **два новых типа**: Type 3 и Type 4, часто маркетингово называемых PoE++.[black-box+4][16]

**Общее:** питание идёт уже по **всем 4 парам** витой пары (4‑pair PoE, 4PPoE).[skomplekt+5][18]

**Type 3 (PoE++ / 4PPoE, часть 802.3bt):**[wikipedia+4][19]

- Макс. мощность на PSE: до **60 Вт**.[phihong+3][14]

- Мощность на PD: ≈ **51 Вт**.[tripplite.eaton][17]

- Классы PoE: Class 5 и 6.[tripplite.eaton][17]

- Применение:[ascentoptics+3][15]

 - Поворотно‑наклонные камеры с подогревом.

 - Мощные Wi‑Fi 6/6E точки.

 - Панели, мини‑ПК, сенсорные киоски.

 - Ограниченные PoE‑освещение.

**Type 4 (High‑Power PoE / 802.3bt):**[black-box+4][16]

- Макс. мощность на PSE: **90–100 Вт**.[wikipedia+4][19]

- Мощность на PD: до **71–71,3 Вт**.[ascentoptics+2][15]

- Классы: Class 7 (75 Вт), Class 8 (90 Вт).[tripplite.eaton][17]

- Использование **phantom power** и всех 4 пар для максимальной мощности.[black-box+3][16]

- Применение:[phihong+3][14]

 - Панели и мониторы (digital signage).

 - Тонкие клиенты и мини‑ПК.

 - LED‑освещение (PoE‑lighting).

 - Высокомощные Wi‑Fi 6E/7 точки.

 - Промышленная автоматика.

**Резюме по мощностям:**[skomplekt+5][18]

|Тип|Стандарт|Макс. мощность на PSE|Доступно на PD (примерно)|Пары|
|---|---|---|---|---|
|**Type 1**|802.3af (PoE)|15,4 Вт|12,95 Вт|2 пары|
|**Type 2**|802.3at (PoE+)|30 Вт|25,5 Вт|2 пары|
|**Type 3**|802.3bt (PoE++)|60 Вт|51 Вт|4 пары|
|**Type 4**|802.3bt (PoE++)|90–100 Вт|71–71,3 Вт|4 пары|

---

## 2.3. Как PoE работает логически (очень кратко)

1. **Обнаружение PD (Detection):**
 PSE подаёт небольшой «зондирующий» сигнал и по характерному сопротивлению (signature) определяет, есть ли совместимый PoE‑клиент.[wikipedia][19]

2. **Классификация (Classification):**
 PD сообщает свой класс мощности (Class 0–8).[black-box+1][16]

3. **Подача питания:**
 PSE поднимает напряжение до рабочей величины (обычно 44–57 В DC) и начинает питать устройство.[phihong+4][14]

4. **Мониторинг:**
 При коротком замыкании/перегрузке питание отключается.[wikipedia+2][19]

Всё это делается автоматически, поэтому обычный клиентский порт, не поддерживающий PoE, не сгорит: PSE не подаст на него «боевое» напряжение, пока не увидит подпись PD.

---

## 2.4. Преимущества PoE

- **Нет отдельной розетки у устройства.**

- **Гибкость размещения:** можно повесить камеру/точку доступа в любом месте, куда можно протянуть UTP.

- **Централизованное питание:** питание и резервирование (UPS) в одной точке — в стойке с PoE‑коммутатором.

- **Упрощённый монтаж и обслуживание.**

---

Если нужно, могу отдельно сделать таблицу: «Тип устройства → какой стандарт PoE нужен» или краткую шпаргалку по основным видам Ethernet (10/100/1000/10G/40G/100G).

## Источники

1. https://www.ionos.com/digitalguide/server/know-how/ethernet/
2. https://www.nakivo.com/blog/types-of-network-topology-explained/
3. https://spu.edu.sy/downloads/files/1537107387_lecture8.pdf
4. https://www.sciencedirect.com/topics/computer-science/star-topology
5. https://en.wikipedia.org/wiki/Ethernet
6. https://piazza.com/class_profile/get_resource/h3gukiu63l4vq/hbg39e6qolc1ol
7. https://en.wikipedia.org/wiki/Ethernet_over_twisted_pair
8. https://ipc2u.com/articles/product-reviews/the-backbone-of-networking/
9. http://ptgmedia.pearsoncmg.com/imprint_downloads/informit/learninglabs/9780134213736/ch29.html
10. https://www.lantronix.com/resources/networking-tutorials/ethernet-tutorial-networking-basics/
11. https://standards.ieee.org/beyond-standards/ethernet-50th-anniversary/
12. https://support.vector.com/kb?id=kb_article_view&sysparm_article=KB0013990&sys_kb_id=97ff00263b67eed0c1dc1d24c3e45aff&spa=1
13. https://download.tek.com/document/55W_23486_0_0.pdf
14. https://www.phihong.com/understanding-the-ieee-802-3af-standard-basics-of-power-over-ethernet-poe/
15. https://ascentoptics.com/blog/comparing-poe-standards-understanding-power-over-ethernet-and-power-levels/
16. https://www.black-box.de/en-de/page/23894/Resources/Technical-Resources/Black-Box-Explains/Networking/PoE-in-Networking
17. https://tripplite.eaton.com/pages/overview-of-power-over-ethernet-technology
18. https://skomplekt.com/standarty-pitaniia-poe-do-poe-plus-plus/
19. https://en.wikipedia.org/wiki/Power_over_Ethernet
20. https://www.cbtnuggets.com/blog/technology/networking/802-3at-vs-802-3af-which-poe-standard-to-use
21. https://en.wikipedia.org/wiki/Ethernet_frame
