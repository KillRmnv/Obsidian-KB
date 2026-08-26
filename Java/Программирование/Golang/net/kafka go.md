# Работа с Kafka в Go

В Go работа с Kafka строится вокруг двух основных клиентских библиотек: **kafka-go** (чистый Go) и **confluent-kafka-go** (обертка над C-библиотекой librdkafka). Для большинства задач и обучения подходит **kafka-go**, так как он не требует CGO и проще в использовании.

## Основные концепции Kafka

Kafka — это распределенная очередь сообщений, где:

| Компонент | Описание |
|-----------|----------|
| **Topic** | Категория/канал для сообщений |
| **Producer** | Отправляет сообщения в Topic  |
| **Consumer** | Читает сообщения из Topic  |
| **Broker** | Сервер Kafka, хранящий данные |
| **Partition** | Параллельные очереди внутри Topic |
| **Consumer Group** | Группа консьюмеров, делящих нагрузку |

---

## Установка и подключение

```go
// Для kafka-go (рекомендуется)
go get github.com/segmentio/kafka-go

// Для confluent-kafka-go (нужен CGO)
go get github.com/confluentinc/confluent-kafka-go/v2/kafka
```

## Producer (отправка сообщений)

### Базовый Producer

```go
package main

import (
    "context"
    "fmt"
    "log"
    "github.com/segmentio/kafka-go"
)

func main() {
    // Настройка писателя (producer)
    writer := kafka.NewWriter(kafka.WriterConfig{
        Brokers:  []string{"localhost:9092"},
        Topic:    "my-topic",
        Balancer: &kafka.LeastBytes{}, // стратегия распределения по партициям
    })
    defer writer.Close()

    // Отправка сообщения
    err := writer.WriteMessages(context.Background(),
        kafka.Message{
            Key:   []byte("key-1"),
            Value: []byte("Hello, Kafka from Go!"),
        },
    )
    if err != nil {
        log.Fatal("Ошибка отправки:", err)
    }

    fmt.Println("Сообщение отправлено успешно!")
}
```

### Producer с подтверждениями и ретраями

```go
package main

import (
    "context"
    "log"
    "time"
    "github.com/segmentio/kafka-go"
)

func main() {
    writer := kafka.NewWriter(kafka.WriterConfig{
        Brokers: []string{"localhost:9092"},
        Topic:   "my-topic",
        // Настройки надежности
        RequiredAcks: kafka.RequireAll, // ждем подтверждения от всех реплик
        BatchTimeout: 100 * time.Millisecond,
        ReadTimeout:  5 * time.Second,
        WriteTimeout: 5 * time.Second,
        // Автоматический ретрай при ошибках
        MaxAttempts: 3,
    })
    defer writer.Close()

    messages := []kafka.Message{
        {Key: []byte("k1"), Value: []byte("сообщение 1")},
        {Key: []byte("k2"), Value: []byte("сообщение 2")},
        {Key: []byte("k3"), Value: []byte("сообщение 3")},
    }

    // batch-отправка
    err := writer.WriteMessages(context.Background(), messages...)
    if err != nil {
        log.Printf("Ошибка при отправке батча: %v", err)
    }
}
```

### Producer с хедерами и кастомной балансировкой

```go
type CustomBalancer struct{}

func (b *CustomBalancer) Balance(msg kafka.Message, partitions ...int) int {
    // Извлекаем tenant-id из хедеров
    var tenantID string
    for _, h := range msg.Headers {
        if h.Key == "tenant-id" {
            tenantID = string(h.Value)
            break
        }
    }
    if tenantID == "" {
        tenantID = string(msg.Key)
    }

    // FNV хеш для распределения
    hasher := fnv.New32a()
    hasher.Write([]byte(tenantID))
    return partitions[int(hasher.Sum32())%len(partitions)]
}

func main() {
    writer := kafka.NewWriter(kafka.WriterConfig{
        Brokers:  []string{"localhost:9092"},
        Topic:    "multi-tenant-events",
        Balancer: &CustomBalancer{},
    })
    defer writer.Close()

    msg := kafka.Message{
        Key: []byte("tenant-a"),
        Value: []byte(`{"data": "событие для tenant A"}`),
        Headers: []kafka.Header{
            {Key: "tenant-id", Value: []byte("tenant-a")},
        },
    }
    writer.WriteMessages(context.Background(), msg)
}
```

---

## Consumer (чтение сообщений)

### Простой Consumer

```go
package main

import (
    "context"
    "fmt"
    "log"
    "github.com/segmentio/kafka-go"
)

func main() {
    // Создание читателя (consumer)
    reader := kafka.NewReader(kafka.ReaderConfig{
        Brokers:  []string{"localhost:9092"},
        Topic:    "my-topic",
        GroupID:  "my-group", // consumer group
        MinBytes: 10e3,       // 10KB - минимальный батч
        MaxBytes: 10e6,       // 10MB - максимальный батч
    })
    defer reader.Close()

    // Чтение сообщений в цикле
    ctx := context.Background()
    for {
        msg, err := reader.ReadMessage(ctx)
        if err != nil {
            log.Printf("Ошибка чтения: %v", err)
            break
        }
        fmt.Printf("Получено: partition=%d offset=%d key=%s value=%s\n",
            msg.Partition, msg.Offset, string(msg.Key), string(msg.Value))
    }
}
```

### Consumer Group (балансировка нагрузки)

```go
func main() {
    reader := kafka.NewReader(kafka.ReaderConfig{
        Brokers:  []string{"localhost:9092"},
        Topic:    "my-topic",
        GroupID:  "my-consumer-group",
        // Настройки offset
        StartOffset: kafka.LastOffset, // читаем с последнего
        // или kafka.FirstOffset - с самого начала
    })
    defer reader.Close()

    for {
        msg, err := reader.ReadMessage(context.Background())
        if err != nil {
            log.Printf("Ошибка: %v", err)
            continue
        }
        // Обработка сообщения
        processMessage(msg)
        // offset коммитится автоматически при ReadMessage
    }
}
```

### Ручное управление offset-ами

```go
func main() {
    reader := kafka.NewReader(kafka.ReaderConfig{
        Brokers: []string{"localhost:9092"},
        Topic:   "my-topic",
        GroupID: "manual-offset-group",
    })
    defer reader.Close()

    for {
        // Читаем без автоматического коммита
        msg, err := reader.FetchMessage(context.Background())
        if err != nil {
            break
        }

        // Обрабатываем сообщение
        if err := processMessage(msg); err != nil {
            log.Printf("Ошибка обработки: %v", err)
            // Не коммитим - сообщение будет перечитано
            continue
        }

        // Коммитим offset только после успешной обработки
        if err := reader.CommitMessages(context.Background(), msg); err != nil {
            log.Printf("Ошибка коммита: %v", err)
        }
    }
}
```

---

## Интеграция с контекстом и graceful shutdown

```go
package main

import (
    "context"
    "log"
    "os"
    "os/signal"
    "syscall"
    "time"
    "github.com/segmentio/kafka-go"
)

func main() {
    ctx, cancel := context.WithCancel(context.Background())
    defer cancel()

    // Обработка сигналов
    sigCh := make(chan os.Signal, 1)
    signal.Notify(sigCh, syscall.SIGINT, syscall.SIGTERM)
    go func() {
        <-sigCh
        log.Println("Получен сигнал остановки...")
        cancel()
    }()

    // Consumer с контекстом
    reader := kafka.NewReader(kafka.ReaderConfig{
        Brokers: []string{"localhost:9092"},
        Topic:   "my-topic",
        GroupID: "graceful-group",
    })
    defer reader.Close()

    // Канал для сигнала готовности к остановке
    done := make(chan struct{})

    go func() {
        defer close(done)
        for {
            select {
            case <-ctx.Done():
                log.Println("Завершаем чтение...")
                return
            default:
                msg, err := reader.ReadMessage(ctx)
                if err != nil {
                    log.Printf("Ошибка чтения: %v", err)
                    continue
                }
                log.Printf("Получено: %s", string(msg.Value))
            }
        }
    }()

    // Ждем завершения или сигнала
    select {
    case <-ctx.Done():
        log.Println("Контекст отменен")
    case <-done:
        log.Println("Consumer завершил работу")
    }

    // Даем время на завершение обработки
    time.Sleep(2 * time.Second)
    log.Println("Приложение остановлено")
}
```

---

## Сравнение библиотек

| Характеристика | kafka-go (segmentio) | confluent-kafka-go |
|---------------|----------------------|-------------------|
| **CGO** | Не требуется (чистый Go) | Требуется (обертка над librdkafka) |
| **Производительность** | Хорошая | Очень высокая |
| **Простота** | Проще API | Сложнее |
| **Consumer Group** | Полная поддержка | Полная поддержка |
| **Поддержка** | Сообщество | Confluent (коммерческая) |
| **Выбор для обучения** | **Рекомендуется** | Для production с высокой нагрузкой |

---

## Типичные ошибки и их решение

### 1. Deadlock при отправке без получателя
```go
// producer без работающего consumer
writer.WriteMessages(ctx, msg) // может зависнуть если нет брокера
// Решение: проверка соединения или таймаут
```

### 2. Неправильный GroupID
```go
// Если GroupID меняется - consumer начинает читать с начала (если StartOffset = FirstOffset)
// Решение: фиксированный GroupID для продакшена
```

### 3. Потеря сообщений при рестарте
```go
// Не забываем про auto.commit
// Лучше использовать ручной коммит после обработки
```