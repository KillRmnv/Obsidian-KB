# UserType в Hibernate

**UserType** (в Hibernate 6+ переименован в **`BasicType`**) — это механизм для создания **пользовательских типов** данных, когда стандартных маппингов недостаточно. Позволяет контролировать, как Java-объект сохраняется и загружается из базы данных.

---

## 1. Когда использовать UserType

| Сценарий | Пример |
|----------|--------|
| Кастомная сериализация | Шифрование данных, JSON, XML |
| Специфичные типы БД | ENUM, ARRAY, GEO-типы |
| Сложные значения | Деньги, диапазоны, цвет |
| Совместимость | Миграция со старой схемой БД |

---

## 2. Реализация в Hibernate 5 (UserType)

### 2.1. Пример: Шифрование строки

```java
import org.hibernate.usertype.UserType;
import java.io.Serializable;
import java.sql.*;

public class EncryptedStringUserType implements UserType {

    private static final int[] SQL_TYPES = {Types.VARCHAR};

    @Override
    public int[] sqlTypes() {
        return SQL_TYPES;
    }

    @Override
    public Class returnedClass() {
        return String.class;
    }

    @Override
    public Object nullSafeGet(ResultSet rs, String[] names, 
                              SharedSessionContractImplementor session, 
                              Object owner) throws SQLException {
        String value = rs.getString(names[0]);
        if (value == null) return null;
        return decrypt(value); // Ваша логика расшифровки
    }

    @Override
    public void nullSafeSet(PreparedStatement st, Object value, 
                            int index, 
                            SharedSessionContractImplementor session) throws SQLException {
        if (value == null) {
            st.setNull(index, Types.VARCHAR);
        } else {
            st.setString(index, encrypt((String) value)); // Ваша логика шифрования
        }
    }

    @Override
    public Object deepCopy(Object value) {
        return value; // Для неизменяемых типов
    }

    @Override
    public boolean isMutable() {
        return false;
    }

    @Override
    public Serializable disassemble(Object value) {
        return (Serializable) value;
    }

    @Override
    public Object assemble(Serializable cached, Object owner) {
        return cached;
    }

    @Override
    public Object replace(Object original, Object target, Object owner) {
        return original;
    }

    @Override
    public int hashCode(Object x) throws HibernateException {
        return x == null ? 0 : x.hashCode();
    }

    @Override
    public boolean equals(Object x, Object y) throws HibernateException {
        return x == y || (x != null && x.equals(y));
    }

    // Методы шифрования/дешифрования
    private String encrypt(String plain) { /* ... */ }
    private String decrypt(String encrypted) { /* ... */ }
}
```

### 2.2. Использование в сущности

```java
@Entity
@Table(name = "users")
public class User {

    @Id
    private Long id;

    @Type(type = "com.example.EncryptedStringUserType")
    @Column(name = "ssn")
    private String ssn; // Будет зашифровано в БД
}
```

Или через `@Convert` (предпочтительнее в Hibernate 5+):

```java
@Convert(converter = EncryptedStringConverter.class)
private String ssn;
```

---

## 3. Реализация в Hibernate 6+ (BasicType)

В Hibernate 6 интерфейс `UserType` устарел. Теперь используется **`BasicType`** или **`AttributeConverter`**.

### 3.1. Пример: Тип Money

```java
import org.hibernate.usertype.BasicType;
import org.hibernate.engine.spi.SharedSessionContractImplementor;
import java.sql.*;

public class MoneyBasicType implements BasicType<Money> {

    @Override
    public Class<Money> getJavaType() {
        return Money.class;
    }

    @Override
    public JdbcType getJdbcType() {
        return JdbcType.VARCHAR; // Или другой тип
    }

    @Override
    public Money get(ResultSet rs, int paramIndex, 
                     SharedSessionContractImplementor session, 
                     Object owner) throws SQLException {
        String value = rs.getString(paramIndex);
        if (value == null) return null;
        // Парсим из строки "100.50 USD"
        String[] parts = value.split(" ");
        return new Money(new BigDecimal(parts[0]), parts[1]);
    }

    @Override
    public void set(PreparedStatement st, int paramIndex, 
                    Money value, 
                    SharedSessionContractImplementor session) throws SQLException {
        if (value == null) {
            st.setNull(paramIndex, Types.VARCHAR);
        } else {
            st.setString(paramIndex, value.getAmount() + " " + value.getCurrency());
        }
    }
}
```

### 3.2. Регистрация типа

```java
// В конфигурации Hibernate
configuration.addAuxiliaryDatabaseObject(new MoneyBasicType());

// Или через аннотацию
@Type(MoneyBasicType.class)
private Money price;
```

---

## 4. Современный подход: AttributeConverter (рекомендуется)

Для большинства случаев лучше использовать **`AttributeConverter`** (работает в Hibernate 5 и 6).

### 4.1. Пример: JSON

```java
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;
import com.fasterxml.jackson.databind.ObjectMapper;

@Converter
public class JsonConverter implements AttributeConverter<Object, String> {

    private static final ObjectMapper mapper = new ObjectMapper();

    @Override
    public String convertToDatabaseColumn(Object attribute) {
        if (attribute == null) return null;
        try {
            return mapper.writeValueAsString(attribute);
        } catch (Exception e) {
            throw new IllegalArgumentException("Ошибка сериализации", e);
        }
    }

    @Override
    public Object convertToEntityAttribute(String dbData) {
        if (dbData == null) return null;
        try {
            return mapper.readValue(dbData, Object.class);
        } catch (Exception e) {
            throw new IllegalArgumentException("Ошибка десериализации", e);
        }
    }
}
```

### 4.2. Использование

```java
@Entity
public class Product {

    @Id
    private Long id;

    @Convert(converter = JsonConverter.class)
    @Column(columnDefinition = "TEXT")
    private Map<String, Object> attributes;
}
```

---

## 5. Сравнение подходов

| Подход | Hibernate | Сложность | Гибкость | Рекомендация |
|--------|-----------|-----------|----------|--------------|
| **`UserType`** | 5.x | Высокая | Максимальная | Устарел, не использовать в новых проектах |
| **`BasicType`** | 6.x | Высокая | Максимальная | Для сложных кастомных типов |
| **`AttributeConverter`** | 5.x/6.x | Низкая | Средняя | ✅ **Рекомендуется для 90% случаев** |
| **`@JdbcTypeCode`** | 6.x | Очень низкая | Средняя | Для JSON в современных БД |

---

## 6. Практические примеры

### 6.1. Шифрование данных

```java
@Converter
public class CryptoConverter implements AttributeConverter<String, String> {

    @Override
    public String convertToDatabaseColumn(String plain) {
        return Base64.getEncoder().encodeToString(plain.getBytes());
    }

    @Override
    public String convertToEntityAttribute(String encrypted) {
        return new String(Base64.getDecoder().decode(encrypted));
    }
}

// Использование
@Convert(converter = CryptoConverter.class)
private String password;
```

### 6.2. Enum как код (не название)

```java
@Converter
public class StatusCodeConverter implements AttributeConverter<StatusCode, Integer> {

    @Override
    public Integer convertToDatabaseColumn(StatusCode status) {
        return status == null ? null : status.getCode();
    }

    @Override
    public StatusCode convertToEntityAttribute(Integer code) {
        return StatusCode.fromCode(code);
    }
}
```

### 6.3. GPS Координаты

```java
@Embeddable
public class Coordinates {
    private Double latitude;
    private Double longitude;
}

// В сущности
@Embedded
private Coordinates location;

// В БД: location_latitude, location_longitude
```

---

## 7. Регистрация кастомного типа (Hibernate 6)

```java
import org.hibernate.boot.model.TypeContributions;
import org.hibernate.boot.model.TypeContributor;
import org.hibernate.service.ServiceRegistry;

public class CustomTypeContributor implements TypeContributor {

    @Override
    public void contribute(TypeContributions typeContributions, 
                          ServiceRegistry serviceRegistry) {
        typeContributions.contributeType(
            new MoneyBasicType(), 
            "money"
        );
    }
}
```

В `META-INF/services/org.hibernate.boot.model.TypeContributor`:
```
com.example.CustomTypeContributor
```

---

## 8. Best Practices

✅ **Рекомендуется:**
- Использовать `AttributeConverter` вместо `UserType` в новых проектах
- Делать конвертеры неизменяемыми и потокобезопасными
- Обрабатывать `null` значения корректно
- Тестировать конвертеры отдельно от сущностей

❌ **Избегать:**
- Сложной логики в конвертерах (выносить в сервисы)
- Зависимостей от сессии Hibernate в конвертерах
- Изменяемых типов без реализации `deepCopy`

---

## 9. Миграция с UserType на AttributeConverter

| UserType метод | AttributeConverter аналог |
|----------------|---------------------------|
| `nullSafeGet` | `convertToEntityAttribute` |
| `nullSafeSet` | `convertToDatabaseColumn` |
| `returnedClass` | Определяется дженериком |
| `sqlTypes` | Определяется типом колонки |

**Пример миграции:**

```java
// Было (Hibernate 5)
public class OldUserType implements UserType { ... }

// Стало (Hibernate 5+/6)
@Converter
public class NewConverter implements AttributeConverter<MyType, String> { ... }
```

---

## 10. Подключение в Spring Boot

```properties
# application.properties
spring.jpa.properties.hibernate.types.print.banner=false
```

```java
@Configuration
public class HibernateConfig {

    @Bean
    public HibernatePropertiesCustomizer hibernatePropertiesCustomizer() {
        return props -> props.put(
            "hibernate.type_contributors",
            "com.example.CustomTypeContributor"
        );
    }
}
```

---

## Итог

| Задача | Решение |
|--------|---------|
| Простая конвертация | `@Convert` + `AttributeConverter` |
| JSON в БД | `@JdbcTypeCode(SqlTypes.JSON)` (Hibernate 6) |
| Сложная логика | `BasicType` (Hibernate 6) |
| Шифрование | `AttributeConverter` |
| Встраиваемые объекты | `@Embeddable` + `@Embedded` |

**Для 90% случаев используйте `AttributeConverter`** — это проще, стандартизировано (JPA) и работает в Hibernate 5 и 6.

Нужен пример под конкретный сценарий? Укажите, какой тип данных вы хотите мапить.