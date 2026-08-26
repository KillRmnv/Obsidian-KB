# Работа с SQL в Go

В Go работа с SQL построена вокруг стандартного пакета `database/sql`. Это абстракция над драйверами БД, которая предоставляет единый интерфейс для работы с разными СУБД.

---

## 1. Подключение к БД

### Установка драйвера

```bash
# PostgreSQL
go get github.com/lib/pq
# или
go get github.com/jackc/pgx/v5

# MySQL
go get github.com/go-sql-driver/mysql

# SQLite
go get github.com/mattn/go-sqlite3
```

### Подключение

```go
package main

import (
    "database/sql"
    "log"
    _ "github.com/lib/pq" // импорт для side-effect (регистрация драйвера)
)

func main() {
    // PostgreSQL
    connStr := "postgres://user:password@localhost:5432/dbname?sslmode=disable"
    db, err := sql.Open("postgres", connStr)
    if err != nil {
        log.Fatal(err)
    }
    defer db.Close()

    // Проверка соединения
    if err := db.Ping(); err != nil {
        log.Fatal(err)
    }
    log.Println("Подключено к БД!")
}
```

### Настройка пула соединений

```go
// Настройка пула (важно!)
db.SetMaxOpenConns(25)      // максимум открытых соединений
db.SetMaxIdleConns(10)      // максимум простаивающих
db.SetConnMaxLifetime(5 * time.Minute) // время жизни соединения
db.SetConnMaxIdleTime(1 * time.Minute) // время жизни простаивающего соединения
```

---

## 2. Модели и маппинг

```go
type User struct {
    ID        int
    Name      string
    Email     string
    Age       int
    CreatedAt time.Time
    IsActive  bool
}

type NullableUser struct {
    ID     int
    Name   string
    Email  sql.NullString // для NULL в БД
    Age    sql.NullInt64
}
```

---

## 3. CRUD операции

### CREATE (INSERT)

```go
// Вставка одной записи
func createUser(db *sql.DB, user User) (int64, error) {
    query := `INSERT INTO users (name, email, age, created_at, is_active)
              VALUES ($1, $2, $3, $4, $5) RETURNING id`
    
    var id int64
    err := db.QueryRow(
        query,
        user.Name,
        user.Email,
        user.Age,
        user.CreatedAt,
        user.IsActive,
    ).Scan(&id)
    
    return id, err
}

// Использование
user := User{
    Name:      "Alice",
    Email:     "alice@example.com",
    Age:       30,
    CreatedAt: time.Now(),
    IsActive:  true,
}
id, err := createUser(db, user)
```

### READ (SELECT)

```go
// Получение одной записи
func getUser(db *sql.DB, id int) (*User, error) {
    query := `SELECT id, name, email, age, created_at, is_active
              FROM users WHERE id = $1`
    
    var user User
    err := db.QueryRow(query, id).Scan(
        &user.ID,
        &user.Name,
        &user.Email,
        &user.Age,
        &user.CreatedAt,
        &user.IsActive,
    )
    if err == sql.ErrNoRows {
        return nil, fmt.Errorf("user not found")
    }
    if err != nil {
        return nil, err
    }
    return &user, nil
}

// Получение всех записей
func getUsers(db *sql.DB) ([]User, error) {
    query := `SELECT id, name, email, age, created_at, is_active
              FROM users ORDER BY id`
    
    rows, err := db.Query(query)
    if err != nil {
        return nil, err
    }
    defer rows.Close()

    var users []User
    for rows.Next() {
        var user User
        err := rows.Scan(
            &user.ID,
            &user.Name,
            &user.Email,
            &user.Age,
            &user.CreatedAt,
            &user.IsActive,
        )
        if err != nil {
            return nil, err
        }
        users = append(users, user)
    }
    return users, rows.Err()
}
```

### UPDATE

```go
func updateUser(db *sql.DB, user User) error {
    query := `UPDATE users
              SET name = $1, email = $2, age = $3, is_active = $4
              WHERE id = $5`
    
    result, err := db.Exec(
        query,
        user.Name,
        user.Email,
        user.Age,
        user.IsActive,
        user.ID,
    )
    if err != nil {
        return err
    }
    
    rows, err := result.RowsAffected()
    if err != nil {
        return err
    }
    if rows == 0 {
        return fmt.Errorf("user not found")
    }
    return nil
}
```

### DELETE

```go
func deleteUser(db *sql.DB, id int) error {
    query := `DELETE FROM users WHERE id = $1`
    
    result, err := db.Exec(query, id)
    if err != nil {
        return err
    }
    
    rows, err := result.RowsAffected()
    if err != nil {
        return err
    }
    if rows == 0 {
        return fmt.Errorf("user not found")
    }
    return nil
}
```

---

## 4. Транзакции

```go
func createUserAndProfile(db *sql.DB, user User, bio string) error {
    // Начинаем транзакцию
    tx, err := db.Begin()
    if err != nil {
        return err
    }
    // defer + rollback на случай паники
    defer func() {
        if err != nil {
            tx.Rollback()
        }
    }()

    // Вставляем пользователя
    query1 := `INSERT INTO users (name, email, age) VALUES ($1, $2, $3) RETURNING id`
    var userID int
    err = tx.QueryRow(query1, user.Name, user.Email, user.Age).Scan(&userID)
    if err != nil {
        return err
    }

    // Вставляем профиль
    query2 := `INSERT INTO profiles (user_id, bio) VALUES ($1, $2)`
    _, err = tx.Exec(query2, userID, bio)
    if err != nil {
        return err
    }

    // Фиксируем транзакцию
    return tx.Commit()
}

// Использование
err := createUserAndProfile(db, user, "Software developer")
if err != nil {
    log.Printf("Ошибка: %v", err)
}
```

### Транзакция с контекстом и таймаутом

```go
func withTransaction(ctx context.Context, db *sql.DB, fn func(*sql.Tx) error) error {
    tx, err := db.BeginTx(ctx, &sql.TxOptions{
        Isolation: sql.LevelSerializable,
        ReadOnly:  false,
    })
    if err != nil {
        return err
    }
    defer tx.Rollback()

    if err := fn(tx); err != nil {
        return err
    }
    return tx.Commit()
}

// Использование
ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
defer cancel()

err := withTransaction(ctx, db, func(tx *sql.Tx) error {
    // несколько операций в одной транзакции
    return nil
})
```

---

## 5. Подготовленные запросы (Prepared Statements)

```go
// Подготовка запроса
stmt, err := db.Prepare(`INSERT INTO users (name, email, age) VALUES ($1, $2, $3)`)
if err != nil {
    return err
}
defer stmt.Close()

// Многократное использование
users := []User{{"Alice", "a@ex.com", 30}, {"Bob", "b@ex.com", 25}}
for _, u := range users {
    _, err := stmt.Exec(u.Name, u.Email, u.Age)
    if err != nil {
        return err
    }
}
```

---

## 6. NULL значения

```go
type User struct {
    ID    int
    Name  string
    Email sql.NullString // NULL разрешён
    Age   sql.NullInt64
}

func getUser(db *sql.DB, id int) (User, error) {
    var user User
    err := db.QueryRow(`SELECT id, name, email, age FROM users WHERE id = $1`, id).Scan(
        &user.ID,
        &user.Name,
        &user.Email,
        &user.Age,
    )
    return user, err
}

// Проверка
if user.Email.Valid {
    fmt.Println("Email:", user.Email.String)
} else {
    fmt.Println("Email is NULL")
}
```

---

## 7. QueryBuilder (sqlx)

```go
// Установка
go get github.com/jmoiron/sqlx

// Использование
db := sqlx.Connect("postgres", connStr)

// SELECT
var users []User
err := db.Select(&users, `SELECT * FROM users WHERE age > $1`, 25)

// INSERT с возвратом ID
var id int
err := db.QueryRowx(`INSERT INTO users (name, email) VALUES ($1, $2) RETURNING id`,
    "Alice", "a@ex.com").Scan(&id)

// Named параметры
query := `SELECT * FROM users WHERE name = :name AND age = :age`
params := map[string]interface{}{"name": "Alice", "age": 30}
rows, err := db.NamedQuery(query, params)
```

---

## 8. Миграции (golang-migrate)

```bash
# Установка CLI
brew install golang-migrate

# Создание миграции
migrate create -ext sql -dir migrations -seq init_schema

# Применение
migrate -path migrations -database "postgres://..." up

# Откат
migrate -path migrations -database "postgres://..." down
```

---

## 9. Безопасность и Prepared Statements

```go
//  Опасно: SQL Injection
query := fmt.Sprintf("SELECT * FROM users WHERE name = '%s'", userInput)

//  Безопасно: параметризованный запрос
rows, err := db.Query("SELECT * FROM users WHERE name = $1", userInput)
```

---

## 10. Тестирование с memory-БД

```go
func TestDB(t *testing.T) {
    // SQLite in-memory
    db, err := sql.Open("sqlite3", ":memory:")
    if err != nil {
        t.Fatal(err)
    }
    defer db.Close()

    // Инициализация схемы
    _, err = db.Exec(`
        CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            email TEXT NOT NULL
        )
    `)
    if err != nil {
        t.Fatal(err)
    }

    // Тесты...
}
```

---

## 11. Пул соединений и логирование

```go
import "log/slog"

// Обертка для sql.DB с логированием
type LoggingDB struct {
    *sql.DB
    logger *slog.Logger
}

func (db *LoggingDB) Query(query string, args ...any) (*sql.Rows, error) {
    db.logger.Debug("Query", "sql", query, "args", args)
    start := time.Now()
    rows, err := db.DB.Query(query, args...)
    db.logger.Debug("Query done", "duration", time.Since(start))
    return rows, err
}
```

---

## 12. Пример: репозиторий с интерфейсом

```go
type UserRepository interface {
    GetByID(ctx context.Context, id int) (*User, error)
    Create(ctx context.Context, user *User) error
    Update(ctx context.Context, user *User) error
    Delete(ctx context.Context, id int) error
    List(ctx context.Context) ([]User, error)
}

type userRepo struct {
    db *sql.DB
}

func NewUserRepository(db *sql.DB) UserRepository {
    return &userRepo{db: db}
}

func (r *userRepo) GetByID(ctx context.Context, id int) (*User, error) {
    // реализация
}
```

---

## Итог: выбор БД/драйвера

| СУБД | Драйвер | Когда использовать |
|------|---------|-------------------|
| **PostgreSQL** | `lib/pq` или `pgx/v5` | Основной выбор для продакшена |
| **MySQL** | `go-sql-driver/mysql` | Если уже используется MySQL |
| **SQLite** | `mattn/go-sqlite3` | Прототипы, тесты, десктоп-приложения |
| **ORM** | `gorm` (слой поверх sql) | Сложные модели, но теряется контроль |

**Ключевые моменты для Go-разработчика:**
- Используй `database/sql` как стандарт
- Всегда закрывай `rows` через `defer rows.Close()`
- Используй параметризованные запросы для безопасности
- Настраивай пул соединений
- Транзакции обязательны для атомарных операций
- Для сложных запросов — `sqlx` или `squirrel` (более удобный query builder)