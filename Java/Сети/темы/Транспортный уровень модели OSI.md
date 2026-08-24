## Связанные темы

- [[Протоколы TCP и UDP]]
- [[Протокол UDP]]
- [[Протокол TCP]]

## Экзаменационный билет: Транспортный уровень модели OSI/ISO. Задачи. Сокеты.

## 1. Общая характеристика

Транспортный уровень (Transport Layer) — это **4-й уровень** модели OSI. Он находится между сетевым уровнем (который маршрутизирует пакеты) и сеансовым уровнем (который управляет сессиями).

- **Главная цель:** Обеспечить логическую связь (канал) непосредственно между **процессами** (приложениями) на разных хостах.

- Если сетевой уровень (IP) доставляет данные от _компьютера к компьютеру_, то транспортный уровень доставляет их от _программы к программе_.[timeweb+1][1]

## 2. Основные задачи транспортного уровня

Согласно лекции и общим стандартам, транспортный уровень решает следующие ключевые задачи:

1. **Мультиплексирование и демультиплексирование**

 - Позволяет передавать данные от разных приложений (браузер, почта, мессенджер) через один физический канал.

 - Реализуется с помощью **портов** (числовых идентификаторов процессов).

 - Диапазоны портов (из лекции):

 - _Well-known (системные):_ 0 – 1023.

 - _Registered (зарегистрированные):_ 1024 – 49151.

 - _Dynamic/Private (динамические):_ 49152 – 65535.

2. **Сегментация и сборка**

 - Разбиение больших блоков данных прикладного уровня на мелкие фрагменты (**сегменты**) для передачи.

 - На стороне получателя происходит обратная сборка сегментов в правильном порядке.[timeweb+1][1]

3. **Обеспечение надежности (Reliability)**

 - Гарантия того, что данные дошли без ошибок и потерь.

 - Используются механизмы подтверждения получения (**ACK**) и повторной передачи потерянных пакетов (**ARQ** — Automatic Repeat reQuest).

 - Примеры алгоритмов: _Stop-and-Wait_, _Sliding Window_ (скользящее окно), _Selective Repeat_.

4. **Управление потоком (Flow Control)**

 - Предотвращение переполнения буфера получателя. Если отправитель шлет данные слишком быстро, получатель сообщает ему снизить скорость (механизм **Window Size** в TCP).

5. **Управление перегрузкой (Congestion Control)**

 - Механизмы предотвращения «заторов» в самой сети. В лекции упоминаются алгоритмы TCP: _Slow Start_ (медленный старт), _Congestion Avoidance_ (предотвращение перегрузки), _Fast Retransmit_ и _Fast Recovery_.

---

## 3. Сокеты (Sockets)

**Сокет** — это программный интерфейс (API), обеспечивающий обмен данными между процессами. Это конечная точка соединения.

**Структура сокета:**
Для идентификации соединения используется комбинация:

> **IP-адрес** (адрес хоста) + **Номер порта** (адрес процесса) + **Протокол** (TCP или UDP).
> Эта пара (IP:Port) называется сокетом.[arenda-server+1][2]

**Основные типы сокетов:**

|Тип сокета|Соответствующий протокол|Характеристика|
|---|---|---|
|**Потоковые (Stream Sockets, `SOCK_STREAM`)**|**TCP**|- **С установлением соединения:** перед передачей нужно «дозвониться» (Handshake). <br>- **Надежность:** гарантируют доставку и правильный порядок байтов. <br>- **Поток:** данные идут непрерывным потоком, границы сообщений не сохраняются (нужно парсить вручную). <br>- Пример: загрузка веб-страниц, файлы[ya+1][3].|
|**Дейтаграммные (Datagram Sockets, `SOCK_DGRAM`)**|**UDP**|- **Без соединения:** данные просто «выстреливаются» в сеть. <br>- **Ненадежность:** пакеты могут теряться, дублироваться или приходить не по порядку. <br>- **Границы:** сохраняют границы сообщений (один `send` = один `recv`). <br>- Пример: видеозвонки, онлайн-игры, DNS[ya+1][3].|

**Принцип работы (на примере TCP):**

1. **Server:** Создает сокет → Привязывает к порту (`bind`) → Слушает эфир (`listen`) → Принимает входящее (`accept`).

2. **Client:** Создает сокет → Инициирует подключение (`connect`) → Сервер подтверждает.

3. Начинается обмен данными (`send`/`recv`).[arenda-server][2]

## Краткое резюме для ответа

Транспортный уровень отвечает за надежную доставку данных «от приложения к приложению». Его главные инструменты — это протоколы **TCP** (надежный, с установлением соединения) и **UDP** (быстрый, без гарантий). Программисты взаимодействуют с этим уровнем через **сокеты** — абстракцию, объединяющую IP-адрес и порт процесса.

## Источники

1. https://timeweb.cloud/blog/transportnyj-uroven-osi
2. https://arenda-server.cloud/blog/ponimanie-soketov-osnovy-setevogo-programmirovanija/
3. https://ya.ru/neurum/c/tehnologii/q/v_chem_raznica_mezhdu_potokovymi_i_deytagrammnymi_7fc5903d
4. https://ciscotips.ru/transport-layer
5. https://digitalocean.ru/n/chto-takoe-soket
6. https://citforum.ru/book/cook/winsock.shtml
7. https://www.semanticscholar.org/paper/0d4900d3579838fa111c0d96f2f99284d98b9605
8. https://psystudy.ru/index.php/num/article/view/386
9. http://vestnik.volbi.ru/upload/numbers/255/article-255-3071.pdf
10. http://pgs1923.ru/ru/index.php?m=4&y=2024&v=05&p=08
11. http://opi-journal.ru/archives/category/publications
12. https://journals.vsu.ru/sait/article/view/12684
13. https://hetoday.ru/sites/default/files/2023-07/%D0%92%D0%9E%D0%A1_2023_3%D0%BC.pdf#page=20
14. https://moitvivt.ru/ru/journal/pdf?id=1665
15. https://vestnikvgasu.wmsite.ru/vypuski/vypusk-4-72-2023/deformirovanie-i-plastichnost-zhelezobetona
16. https://www.semanticscholar.org/paper/645b0c12c440087a1e0e0e505bc8f8d445c43661
17. https://journals.vsu.ru/sait/article/download/1243/1299
18. https://journals.vsu.ru/sait/article/download/1275/1338
19. https://journals.vsu.ru/sait/article/download/1258/1313
20. https://sky.pro/wiki/sql/transportnyj-uroven-modeli-osi/
21. https://skyeng.ru/magazine/wiki/it-industriya/chto-takoe-soket/
22. https://ru.wikipedia.org/wiki/%D0%94%D0%B0%D1%82%D0%B0%D0%B3%D1%80%D0%B0%D0%BC%D0%BC%D0%BD%D1%8B%D0%B9_%D1%81%D0%BE%D0%BA%D0%B5%D1%82
23. https://neerc.ifmo.ru/wiki/index.php?title=OSI_Model
24. https://lecturesnet.readthedocs.io/net/low-level/ipc/socket/intro.html
25. https://habr.com/ru/companies/smart_soft/articles/184430/
26. https://ru.wikipedia.org/wiki/%D0%A2%D1%80%D0%B0%D0%BD%D1%81%D0%BF%D0%BE%D1%80%D1%82%D0%BD%D1%8B%D0%B9_%D1%83%D1%80%D0%BE%D0%B2%D0%B5%D0%BD%D1%8C
27. https://hyperpc.ru/blog/service/pc-socket-types-and-differences
28. https://ya.ru/neurum/c/tehnologii/q/v_chem_osnovnye_otlichiya_mezhdu_potokovymi_dc3097b5
29. https://habr.com/ru/companies/timeweb/articles/830306/
30. https://parallel.uran.ru/book/export/html/498
31. https://learn.microsoft.com/kk-kz/cpp/mfc/windows-sockets-datagram-sockets?view=msvc-170
32. https://www.it-black.ru/tpost/b58tfm0rg1-funktsii-transportnogo-urovnya-setevoi-m
33. https://ru.wikipedia.org/wiki/%D0%A1%D0%BE%D0%BA%D0%B5%D1%82_\(%D0%BF%D1%80%D0%BE%D0%B3%D1%80%D0%B0%D0%BC%D0%BC%D0%BD%D1%8B%D0%B9_%D0%B8%D0%BD%D1%82%D0%B5%D1%80%D1%84%D0%B5%D0%B9%D1%81\
