`HttpHeaders` — это класс из Spring (`org.springframework.http.HttpHeaders`), который используется для  
**управления HTTP-заголовками** в исходящих (`RestTemplate`, `WebClient`) и входящих (`@RequestHeader`) запросах.

Он представляет собой обычную **многозначную карту (`MultiValueMap<String, String>`)**,  
где каждый ключ — это имя заголовка (`Content-Type`, `Authorization`, `Accept` и т.д.),  
а значение — одно или несколько значений этого заголовка.

---

## 🧠 Основная идея

Когда ты отправляешь HTTP-запрос через `RestTemplate`, тебе нужно сообщить серверу:

- какой тип контента ты отправляешь (`Content-Type`)
    
- какой тип данных ты ожидаешь в ответ (`Accept`)
    
- есть ли авторизация (`Authorization`)
    
- можно ли кэшировать (`Cache-Control`)
    
- и т.д.
    

Spring упрощает это с помощью `HttpHeaders`.

---

## 🧰 Пример базового использования

`HttpHeaders headers = new HttpHeaders(); headers.setContentType(MediaType.APPLICATION_JSON); headers.setAccept(List.of(MediaType.APPLICATION_JSON)); headers.set("Authorization", "Bearer " + apiKey);  HttpEntity<Map<String, Object>> request = new HttpEntity<>(body, headers);  ResponseEntity<Map> response = restTemplate.postForEntity(         "https://example.com/api/v1/analyze",         request,         Map.class );`

🔹 `HttpEntity` объединяет тело запроса (`body`) и заголовки (`headers`).  
🔹 `RestTemplate` использует это, чтобы собрать правильный HTTP-запрос.

---

## ⚙️ Часто используемые заголовки

| Заголовок         | Описание                          | Пример                                    |
| ----------------- | --------------------------------- | ----------------------------------------- |
| `Content-Type`    | Тип тела запроса                  | `application/json`, `multipart/form-data` |
| `Accept`          | Какие типы ответов клиент ожидает | `application/json`, `image/png`           |
| `Authorization`   | Авторизационный токен             | `Bearer eyJhbGciOi...`                    |
| `User-Agent`      | Информация о клиенте              | `MyApp/1.0`                               |
| `Cache-Control`   | Политика кэширования              | `no-cache`, `max-age=3600`                |
| `Accept-Language` | Язык предпочтений                 | `ru-RU, en;q=0.8`                         |
| `Referer`         | Источник запроса                  | `https://myapp.com/page`                  |
## 🧩 Пример для multipart-запроса (как с Imgbb)

`HttpHeaders headers = new HttpHeaders(); headers.setContentType(MediaType.MULTIPART_FORM_DATA);  MultiValueMap<String, Object> body = new LinkedMultiValueMap<>(); body.add("key", apiKey); body.add("image", Base64.getEncoder().encodeToString(file.getBytes())); body.add("name", file.getOriginalFilename());  HttpEntity<MultiValueMap<String, Object>> requestEntity = new HttpEntity<>(body, headers);  ResponseEntity<Map> response = restTemplate.postForEntity(         "https://api.imgbb.com/1/upload",         requestEntity,         Map.class );`

🧠 Здесь `HttpHeaders` сообщает серверу, что тело запроса — **мультичастевое (multipart/form-data)**,  
и Spring автоматически сформирует корректный формат запроса с разделителями (boundary).

---

## 📥 Использование в контроллерах (приёме запросов)

Ты можешь также читать заголовки в контроллере:

`@PostMapping("/upload") public ResponseEntity<?> upload(@RequestHeader HttpHeaders headers,                                 @RequestParam("file") MultipartFile file) {     System.out.println("Content-Type: " + headers.getContentType());     System.out.println("User-Agent: " + headers.getFirst("User-Agent"));     return ResponseEntity.ok("Received file"); }`

Или конкретно:

`@RequestHeader("Authorization") String token`

---

## 🧱 Пример комбинированного использования

`HttpHeaders headers = new HttpHeaders(); headers.setContentType(MediaType.APPLICATION_JSON); headers.set("Authorization", "Bearer " + apiKey); headers.set("Accept-Language", "ru-RU");  // тело запроса Map<String, Object> body = Map.of("query", "analyze image");  // объединяем HttpEntity<Map<String, Object>> entity = new HttpEntity<>(body, headers);  // отправляем ResponseEntity<String> response = restTemplate.exchange(         "https://api.example.com/analyze",         HttpMethod.POST,         entity,         String.class );`

---

## 💡 Важные методы `HttpHeaders`

|Метод|Что делает|
|---|---|
|`set(String name, String value)`|Устанавливает одно значение заголовка|
|`add(String name, String value)`|Добавляет дополнительное значение (если несколько)|
|`getFirst(String name)`|Получает первое значение|
|`get(String name)`|Получает все значения|
|`setContentType(MediaType type)`|Устанавливает Content-Type|
|`setAccept(List<MediaType> types)`|Устанавливает список поддерживаемых форматов|
|`setBearerAuth(String token)`|Устанавливает `Authorization: Bearer <token>`|

---

## 🔐 Пример авторизации с Bearer-токеном

`HttpHeaders headers = new HttpHeaders(); headers.setBearerAuth("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...");`

Результат:

`Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

---

## ⚠️ Типичные ошибки

|Ошибка|Причина|
|---|---|
|`415 Unsupported Media Type`|Неправильно указан `Content-Type`|
|`400 Bad Request`|Сервер ожидал `form-data`, а пришёл `json`|
|`401 Unauthorized`|Отсутствует или неверный `Authorization`|
|`405 Method Not Allowed`|Заголовок или метод не соответствует API|