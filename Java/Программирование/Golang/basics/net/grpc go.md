gRPC — это высокопроизводительный RPC-фреймворк от Google, использующий Protocol Buffers и HTTP/2. В Go это стандартный инструмент для микросервисного взаимодействия.

### Зачем gRPC вместо REST?

| Критерий | gRPC | REST (HTTP/1.1 + JSON) |
|----------|------|------------------------|
| **Протокол** | HTTP/2 (мультиплексирование) | HTTP/1.1 (очередь запросов) |
| **Сериализация** | Protobuf (бинарный, компактный) | JSON (текстовый, громоздкий) |
| **Производительность** | До 7-10 раз быстрее | Медленнее |
| **Типизация** | Строгая (из .proto) | Нестрогая |
| **Стриминг** | Встроенная поддержка всех типов | Требует WebSocket/long-polling |
| **Генерация клиентов** | Автоматическая под любые языки | Ручная или через OpenAPI |
| **Браузерная совместимость** | Ограничена (нужен grpc-web) | Нативная |

В распределённых системах выбор gRPC часто обусловлен производительностью и строгой типизацией интерфейсов.

---

## 1. Определение сервиса (.proto)

Всё начинается с контракта — файла `helloworld.proto`:

```protobuf
syntax = "proto3";

package helloworld;

option go_package = "github.com/yourname/project/helloworld";

service Greeter {
  // Unary RPC
  rpc SayHello (HelloRequest) returns (HelloReply) {}

  // Server Streaming RPC
  rpc SayHelloServerStream (HelloRequest) returns (stream HelloReply) {}

  // Client Streaming RPC
  rpc SayHelloClientStream (stream HelloRequest) returns (HelloReply) {}

  // Bidirectional Streaming RPC
  rpc SayHelloBidiStream (stream HelloRequest) returns (stream HelloReply) {}
}

message HelloRequest {
  string name = 1;
}

message HelloReply {
  string message = 1;
}
```

---

## 2. Генерация кода

Устанавливаем инструменты:
```bash
# protoc компилятор
brew install protobuf  # macOS
sudo apt install protobuf-compiler  # Ubuntu

# Плагины для Go
go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
```

Генерируем код:
```bash
protoc --proto_path=api \
       --go_out=gen --go_opt=paths=source_relative \
       --go-grpc_out=gen --go-grpc_opt=paths=source_relative \
       api/helloworld.proto
```

Что появится:
- `helloworld.pb.go` — структуры сообщений (сериализация/десериализация)
- `helloworld_grpc.pb.go` — интерфейсы для сервера и клиента

---

## 3. Реализация сервера

```go
package main

import (
    "context"
    "log"
    "net"
    "google.golang.org/grpc"
    pb "yourmodule/gen/helloworld"
)

type server struct {
    pb.UnimplementedGreeterServer // обязательное встраивание
}

// --- Unary RPC ---
func (s *server) SayHello(ctx context.Context, req *pb.HelloRequest) (*pb.HelloReply, error) {
    log.Printf("Received: %v", req.Name)
    return &pb.HelloReply{Message: "Hello " + req.Name}, nil
}

// --- Server Streaming RPC ---
func (s *server) SayHelloServerStream(req *pb.HelloRequest, stream pb.Greeter_SayHelloServerStreamServer) error {
    for i := 0; i < 5; i++ {
        if err := stream.Send(&pb.HelloReply{
            Message: "Hello " + req.Name + " (message " + string(rune(i)) + ")",
        }); err != nil {
            return err
        }
    }
    return nil
}

// --- Client Streaming RPC ---
func (s *server) SayHelloClientStream(stream pb.Greeter_SayHelloClientStreamServer) error {
    var names []string
    for {
        req, err := stream.Recv()
        if err == io.EOF {
            // Все сообщения получены
            return stream.SendAndClose(&pb.HelloReply{
                Message: "Hello " + strings.Join(names, ", "),
            })
        }
        if err != nil {
            return err
        }
        names = append(names, req.Name)
    }
}

// --- Bidirectional Streaming RPC ---
func (s *server) SayHelloBidiStream(stream pb.Greeter_SayHelloBidiStreamServer) error {
    for {
        req, err := stream.Recv()
        if err == io.EOF {
            return nil
        }
        if err != nil {
            return err
        }
        if err := stream.Send(&pb.HelloReply{
            Message: "Hello " + req.Name,
        }); err != nil {
            return err
        }
    }
}
```

### Запуск сервера

```go
func main() {
    lis, err := net.Listen("tcp", ":50051")
    if err != nil {
        log.Fatalf("failed to listen: %v", err)
    }

    grpcServer := grpc.NewServer()
    pb.RegisterGreeterServer(grpcServer, &server{})

    log.Println("gRPC server listening on :50051")
    if err := grpcServer.Serve(lis); err != nil {
        log.Fatalf("failed to serve: %v", err)
    }
}
```

---

## 4. Реализация клиента

```go
package main

import (
    "context"
    "io"
    "log"
    "time"
    "google.golang.org/grpc"
    "google.golang.org/grpc/credentials/insecure"
    pb "yourmodule/gen/helloworld"
)

func main() {
    conn, err := grpc.NewClient("localhost:50051",
        grpc.WithTransportCredentials(insecure.NewCredentials()))
    if err != nil {
        log.Fatalf("did not connect: %v", err)
    }
    defer conn.Close()

    client := pb.NewGreeterClient(conn)
    ctx, cancel := context.WithTimeout(context.Background(), time.Second)
    defer cancel()

    // --- Unary Call ---
    reply, err := client.SayHello(ctx, &pb.HelloRequest{Name: "World"})
    if err != nil {
        log.Fatalf("could not greet: %v", err)
    }
    log.Printf("Unary response: %s", reply.Message)

    // --- Server Streaming ---
    stream, err := client.SayHelloServerStream(ctx, &pb.HelloRequest{Name: "Stream"})
    if err != nil {
        log.Fatalf("could not stream: %v", err)
    }
    for {
        reply, err := stream.Recv()
        if err == io.EOF {
            break
        }
        if err != nil {
            log.Fatalf("stream error: %v", err)
        }
        log.Printf("Server stream response: %s", reply.Message)
    }

    // --- Client Streaming ---
    streamClient, err := client.SayHelloClientStream(ctx)
    if err != nil {
        log.Fatalf("could not start client stream: %v", err)
    }
    for _, name := range []string{"Alice", "Bob", "Charlie"} {
        if err := streamClient.Send(&pb.HelloRequest{Name: name}); err != nil {
            log.Fatalf("send error: %v", err)
        }
    }
    reply, err := streamClient.CloseAndRecv()
    if err != nil {
        log.Fatalf("close error: %v", err)
    }
    log.Printf("Client stream response: %s", reply.Message)
}
```

---

## 5. Четыре типа RPC в одном месте

| Тип | Использование | Особенность |
|-----|---------------|-------------|
| **Unary** | Обычный запрос-ответ | `ctx` + точка, возвращает структуру |
| **Server Streaming** | Сервер "льёт" данные клиенту | `stream.Send()` несколько раз, один запрос |
| **Client Streaming** | Клиент "льёт" данные серверу | `stream.Recv()` в цикле до `io.EOF`, ответ через `SendAndClose()` |
| **Bidirectional** | Двусторонний обмен | Клиент и сервер одновременно отправляют/получают |

---

## 6. Важные нюансы

### Context и таймауты
```go
ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
defer cancel()
reply, err := client.SayHello(ctx, req)
```

### Graceful Shutdown
```go
grpcServer.GracefulStop() // ждёт завершения всех RPC
```

### TLS/mTLS
```go
creds, err := credentials.NewClientTLSFromFile("cert.pem", "")
conn, err := grpc.NewClient("localhost:50051", grpc.WithTransportCredentials(creds))
```

### Interceptors (middleware)
```go
unaryInterceptor := func(ctx context.Context, req interface{}, info *grpc.UnaryServerInfo, handler grpc.UnaryHandler) (interface{}, error) {
    log.Println("Before handler:", info.FullMethod)
    resp, err := handler(ctx, req)
    log.Println("After handler")
    return resp, err
}
grpcServer := grpc.NewServer(grpc.UnaryInterceptor(unaryInterceptor))
```

### Health Checks
```go
import "google.golang.org/grpc/health/grpc_health_v1"
// регистрируем стандартный health сервис
```

---

## 7. Когда не использовать gRPC

- API открыто для браузеров (без grpc-web)
- Нужна человекочитаемая отладка (curl для REST)
- Прототип или небольшой проект (overhead настройки)
- Команда не знает Protobuf

---

## Итог: gRPC vs REST в Go

| Сценарий | Инструмент |
|----------|------------|
| Внутренние микросервисы с высокой нагрузкой | gRPC |
| Публичное API (браузеры, мобилки) | REST + OpenAPI |
| Стриминг данных (логи, метрики) | gRPC |
| Кэш-запросы, простая CRUD | Оба, но REST проще |
| Команда знает Go и Protobuf | gRPC |

В Go экосистема gRPC зрелая и хорошо документирована. Официальный туториал — лучшее место для старта.