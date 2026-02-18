
## 🌐 1. **HTTP / HTTPS**

Это классика, то, с чем ты уже работаешь.  
Используется для REST, GraphQL, SOAP, Webhook, Web API и т.д.

📦 Примеры:

- `GET`, `POST`, `PUT`, `DELETE`, `PATCH`
    
- Используется в Spring `RestTemplate`, `WebClient`, Postman
    
- Обычно работает поверх **TCP**
    

---

## ⚡ 2. **WebSocket**

Это **двусторонний постоянный канал** между клиентом и сервером.  
Позволяет обмениваться сообщениями без пересоздания соединения.

🧠 Отличие:

- HTTP — запрос-ответ
    
- WebSocket — _stream сообщений в обе стороны_
    

📦 Пример: чат, онлайн-игры, стриминг данных, нотификации

Пример URI:

```
ws://example.com/socket
wss://example.com/socket   (защищённый)
```

---

## 📨 3. **gRPC (Google Remote Procedure Call)**

Современная альтернатива REST, работает поверх HTTP/2.  
Передаёт данные в **protobuf** (бинарном формате), а не JSON.

📦 Применение:

- Микросервисы (Java, Go, Python)
    
- Быстрее REST
    
- Поддерживает streaming-запросы и ответы
    

Пример:

```protobuf
service Greeter {
  rpc SayHello (HelloRequest) returns (HelloReply);
}
```

---

## 🧵 4. **TCP / UDP сокеты**

Низкоуровневое взаимодействие без HTTP.

### 🔹 TCP

- Надёжная доставка (гарантирует порядок)
    
- Используется в HTTP, FTP, SMTP и т.д.
    

### 🔹 UDP

- Быстрый, но без гарантии доставки
    
- Используется в онлайн-играх, VoIP, видео-конференциях
    

📦 В Java:

```java
Socket socket = new Socket("localhost", 8080);
DataOutputStream out = new DataOutputStream(socket.getOutputStream());
out.writeUTF("Hello Server");
```

---

## 🪣 5. **MQ (Message Queue) — очереди сообщений**

Это **асинхронные запросы**, передаваемые через брокеры:

- RabbitMQ
    
- Kafka
    
- ActiveMQ
    
- Redis Streams
    

📦 Пример:  
Микросервис «A» отправляет задачу → очередь → микросервис «B» получает.

Формат запроса может быть JSON, Avro, Protobuf и т.п.

---

## 🧩 6. **GraphQL**

Это тоже HTTP, но с другим **подходом к структуре запроса**.

Вместо REST-эндпоинтов — один `/graphql`, в который отправляется **запрос-описание**.

📦 Пример:

```graphql
query {
  user(id: "5") {
    name
    email
  }
}
```

---

## 🛰️ 7. **SOAP (XML-based)**

Старый, но всё ещё используемый протокол.  
Передаёт данные в формате XML по HTTP или SMTP.  
Работает через WSDL (описание интерфейсов).

📦 Пример:

```xml
<soap:Envelope>
  <soap:Body>
    <GetUser>
      <id>123</id>
    </GetUser>
  </soap:Body>
</soap:Envelope>
```

---

## 🔄 8. **FTP / SFTP**

Для передачи файлов, а не данных API.

📦 Пример:

```java
FTPClient ftp = new FTPClient();
ftp.connect("ftp.server.com");
ftp.login("user", "pass");
ftp.storeFile("/remote/path/file.txt", new FileInputStream(localFile));
```

---

## 📡 9. **SMTP / IMAP / POP3**

Для обмена **электронной почтой**.  
Используются, например, для ботов, уведомлений и интеграций.

📦 Пример:

- `SMTP` — отправка писем
    
- `IMAP` / `POP3` — получение
    

---

## 🔐 10. **CoAP / MQTT (IoT-протоколы)**

Используются в **интернете вещей (IoT)**, когда нужно минимальное потребление энергии и трафика.

- **MQTT** — Pub/Sub-протокол, лёгкий, работает поверх TCP
    
- **CoAP** — похож на REST, но поверх UDP
    

📦 Пример (MQTT):

```java
MqttClient client = new MqttClient("tcp://broker.hivemq.com:1883", "clientId");
client.connect();
client.publish("test/topic", "Hello IoT".getBytes(), 0, false);
```

---

## 🧠 11. **Custom Binary Protocols**

Некоторые системы используют свои собственные протоколы на сокетах.  
Например, игровые движки, биржи, системы телеметрии.

---

## 🔬 12. **Named Pipes / Unix Domain Sockets**

Используются **внутри одной машины** для обмена данными между процессами.  
Быстрее TCP, но не работают по сети.

---

## 🧩 Итого

|Тип запроса|Протокол|Тип обмена|Применение|
|---|---|---|---|
|REST|HTTP/HTTPS|Синхронный|API, Web|
|WebSocket|WS/WSS|Двусторонний|Чаты, нотификации|
|gRPC|HTTP/2|Синхронный/Streaming|Микросервисы|
|TCP/UDP|—|Низкоуровневый|Игры, сенсоры|
|MQ|AMQP/Kafka/etc|Асинхронный|Микросервисы|
|GraphQL|HTTP|Гибкий REST|API|
|SOAP|HTTP/SMTP|XML|Корпоративные системы|
|FTP/SFTP|TCP|Файлы|Обмен файлами|
|SMTP/IMAP|TCP|Почта|Уведомления|
|MQTT/CoAP|TCP/UDP|IoT|Сенсоры, устройства|

---

Хочешь, я покажу, **как можно реализовать один и тот же запрос** (например — "загрузить файл") на трёх разных протоколах — HTTP, gRPC и WebSocket, чтобы ты сравнил их на практике?