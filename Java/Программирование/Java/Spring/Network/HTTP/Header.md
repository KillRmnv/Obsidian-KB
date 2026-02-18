

## 🧩 1. **Основные заголовки HTTP**

Эти заголовки используются почти в каждом REST-запросе:

|Заголовок|Назначение|Пример|
|---|---|---|
|`Content-Type`|Тип содержимого тела запроса|`application/json`, `multipart/form-data`, `application/x-www-form-urlencoded`|
|`Accept`|Какие форматы ответов клиент принимает|`application/json`, `image/png`, `*/*`|
|`Authorization`|Авторизация (Bearer-токен, Basic и др.)|`Bearer eyJhbGciOiJI...`, `Basic dXNlcjpwYXNz`|
|`User-Agent`|Кто делает запрос (инфо о клиенте)|`Mozilla/5.0`, `Spring-RestTemplate/1.0`|
|`Cache-Control`|Контроль кеширования|`no-cache`, `max-age=3600`|
|`Host`|Имя хоста (обычно ставится автоматически)|`api.example.com`|
|`Connection`|Управление соединением|`keep-alive`, `close`|

---

## 🔑 2. **Заголовки безопасности и авторизации**

|Заголовок|Назначение|Пример|
|---|---|---|
|`Authorization`|Аутентификация пользователя|`Bearer <токен>`|
|`X-API-Key`|Ключ API (альтернатива Bearer)|`X-API-Key: 12345abcdef`|
|`X-Requested-With`|Используется для защиты от CSRF|`XMLHttpRequest`|
|`Cookie`|Передача сессионных данных|`JSESSIONID=xyz123`|
|`Referer`|Откуда пришёл запрос|`https://example.com/form`|
|`Origin`|Источник (часто проверяется CORS)|`https://myapp.com`|

---

## 🧠 3. **Контроль формата и кодировки**

|Заголовок|Назначение|Пример|
|---|---|---|
|`Accept-Encoding`|Какие алгоритмы сжатия поддерживаются|`gzip, deflate, br`|
|`Accept-Charset`|Кодировки|`utf-8`|
|`Content-Encoding`|Как тело запроса сжато|`gzip`|
|`Content-Language`|Язык контента|`en-US`, `ru-RU`|
|`Transfer-Encoding`|Потоковая передача|`chunked`|

---

## 🕒 4. **Контроль кеширования и сроков**

|Заголовок|Назначение|Пример|
|---|---|---|
|`Cache-Control`|Поведение кеша|`no-cache`, `max-age=60`|
|`ETag`|Идентификатор версии ресурса|`"33a64df551425fcc55e..."`|
|`If-Modified-Since`|Запросить только если обновлён после даты|`Wed, 21 Oct 2015 07:28:00 GMT`|
|`Expires`|Срок годности кеша|`Thu, 01 Dec 2025 16:00:00 GMT`|
|`Pragma`|Устаревший, но иногда нужен (`no-cache`)|`no-cache`|

---

## 📦 5. **Заголовки для загрузки файлов / форм**

|Заголовок|Назначение|Пример|
|---|---|---|
|`Content-Disposition`|Как обрабатывать файл|`form-data; name="file"; filename="img.png"`|
|`Content-Length`|Размер тела запроса|`1048576`|
|`Content-Transfer-Encoding`|Тип кодирования содержимого|`binary`, `base64`|
|`Boundary`|Граница частей для `multipart/form-data`|`----WebKitFormBoundary7MA4YWxkTrZu0gW`|

---

## 🧰 6. **Заголовки для REST API и интеграций**

|Заголовок|Назначение|Пример|
|---|---|---|
|`X-Request-ID`|Уникальный идентификатор запроса (для трекинга)|`abc123`|
|`X-Correlation-ID`|ID для корреляции логов между системами|`req-7890`|
|`X-Client-Version`|Версия клиента|`1.0.3`|
|`X-Timestamp`|Время отправки|`2025-10-30T12:34:56Z`|

---

## 💻 Примеры в коде

### 📘 Пример 1: JSON-запрос

```java
HttpHeaders headers = new HttpHeaders();
headers.setContentType(MediaType.APPLICATION_JSON);
headers.setAccept(List.of(MediaType.APPLICATION_JSON));
headers.setBearerAuth("your_api_token_here");
headers.set("User-Agent", "MyApp/1.0");

HttpEntity<String> entity = new HttpEntity<>("{\"name\":\"Alex\"}", headers);
```

---

### 📗 Пример 2: Multipart (файл + данные)

```java
HttpHeaders headers = new HttpHeaders();
headers.setContentType(MediaType.MULTIPART_FORM_DATA);
headers.add("X-API-Key", "abc123");
headers.add("User-Agent", "UploaderService/2.0");
```

---

### 📙 Пример 3: URL-encoded форма

```java
HttpHeaders headers = new HttpHeaders();
headers.setContentType(MediaType.APPLICATION_FORM_URLENCODED);
headers.setAccept(List.of(MediaType.APPLICATION_JSON));
```

---

## 🧩 7. **Добавление своих заголовков**

Ты можешь добавлять любые кастомные:

```java
headers.add("X-Session-Id", UUID.randomUUID().toString());
headers.add("X-Feature-Flag", "beta");
headers.add("X-Device-Type", "Desktop");
```

---

## 🧠 Краткий итог

|Тип задачи|Основные заголовки|
|---|---|
|JSON API|`Content-Type`, `Accept`, `Authorization`|
|Загрузка файлов|`Content-Type: multipart/form-data`, `Authorization`|
|URL-encoded формы|`Content-Type: application/x-www-form-urlencoded`|
|Безопасность|`Authorization`, `Origin`, `Referer`, `X-API-Key`|
|Отладка и логирование|`X-Request-ID`, `X-Correlation-ID`|
