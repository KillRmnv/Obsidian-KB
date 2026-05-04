MapStruct — это генератор кода для преобразования Java-бинов (DTO, Entity, ViewModel и т.д.). В отличие от рефлексивных библиотек (ModelMapper, Dozer), MapStruct работает на этапе компиляции через annotation processing, генерируя типобезопасный Java-код без накладных расходов во время выполнения.

Ниже приведено подробное руководство с примерами кода.

---

### 1. Подключение зависимостей

**Maven**
```xml
<dependencies>
    <dependency>
        <groupId>org.mapstruct</groupId>
        <artifactId>mapstruct</artifactId>
        <version>1.5.5.Final</version>
    </dependency>
</dependencies>

<build>
    <plugins>
        <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-compiler-plugin</artifactId>
            <version>3.11.0</version>
            <configuration>
                <annotationProcessorPaths>
                    <path>
                        <groupId>org.mapstruct</groupId>
                        <artifactId>mapstruct-processor</artifactId>
                        <version>1.5.5.Final</version>
                    </path>
                </annotationProcessorPaths>
            </configuration>
        </plugin>
    </plugins>
</build>
```

**Gradle**
```groovy
dependencies {
    implementation 'org.mapstruct:mapstruct:1.5.5.Final'
    annotationProcessor 'org.mapstruct:mapstruct-processor:1.5.5.Final'
}
```

Важно: если используется Lombok, порядок процессоров должен быть следующим: `mapstruct-processor` после `lombok`. В Gradle это настраивается через `annotationProcessor` последовательно, в Maven — через порядок в `annotationProcessorPaths`.

---

### 2. Базовый пример маппинга

**Исходные классы**
```java
public class UserEntity {
    private Long id;
    private String firstName;
    private String lastName;
    private LocalDate birthDate;
    // геттеры и сеттеры
}

public class UserDto {
    private Long id;
    private String fullName;
    private String birthDate; // строковое представление
    // геттеры и сеттеры
}
```

**Интерфейс маппера**
```java
@Mapper
public interface UserMapper {
    UserMapper INSTANCE = Mappers.getMapper(UserMapper.class);

    @Mapping(source = "firstName", target = "fullName", qualifiedByName = "buildFullName")
    @Mapping(source = "lastName", target = "ignored")
    @Mapping(source = "birthDate", target = "birthDate", dateFormat = "dd.MM.yyyy")
    UserDto toDto(UserEntity entity);

    @Named("buildFullName")
    default String buildFullName(UserEntity source) {
        return source.getFirstName() + " " + source.getLastName();
    }
}
```

MapStruct автоматически сопоставляет поля с одинаковыми именами и типами. Для нестандартных преобразований используются `@Mapping`, `@Named` или вспомогательные классы через `uses`.

---

### 3. Ключевые параметры аннотации @Mapping

| Параметр | Назначение | Пример |
|----------|------------|--------|
| `source` | Исходное поле | `source = "user.name"` |
| `target` | Целевое поле | `target = "userName"` |
| `ignore` | Игнорировать поле | `ignore = true` |
| `defaultValue` | Значение при null | `defaultValue = "UNKNOWN"` |
| `dateFormat` | Формат даты | `dateFormat = "yyyy-MM-dd"` |
| `expression` | Java-выражение | `expression = "source.isActive() ? \"ACTIVE\" : \"INACTIVE\""` |
| `qualifiedByName` | Кастомный метод | `qualifiedByName = "toStatusDto"` |

Пример игнорирования и значения по умолчанию:
```java
@Mapping(target = "createdAt", ignore = true)
@Mapping(target = "status", defaultValue = "PENDING")
OrderDto toDto(OrderEntity entity);
```

---

### 4. Работа с вложенными объектами и коллекциями

MapStruct автоматически маппит коллекции и вложенные объекты, если для них существуют мапперы.

```java
@Mapper
public interface AddressMapper {
    AddressDto toDto(AddressEntity entity);
}

@Mapper(uses = {AddressMapper.class})
public interface UserMapper {
    @Mapping(source = "address", target = "addressInfo")
    UserDto toDto(UserEntity entity);

    List<UserDto> toDtoList(List<UserEntity> entities);
}
```

При генерации кода MapStruct вызовет `addressMapper.toDto()` автоматически. Для коллекций создаётся цикл с вызовом маппера для каждого элемента.

---

### 5. Обновление существующего объекта (@MappingTarget)

Иногда нужно не создавать новый объект, а обновить поля существующего экземпляра. Для этого используется `@MappingTarget`.

```java
@Mapper
public interface UserMapper {
    void updateFromDto(UserDto dto, @MappingTarget UserEntity entity);
}
```

Сгенерированный метод будет копировать значения из DTO в переданный экземпляр Entity, минуя создание нового объекта. Поля, отсутствующие в DTO, остаются без изменений. Если нужно игнорировать null-значения:
```java
@Mapping(target = "email", ignore = true) // если в DTO email может быть null
```
Или использовать `nullValuePropertyMappingStrategy`:
```java
@BeanMapping(nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE)
void updateFromDto(UserDto dto, @MappingTarget UserEntity entity);
```

---

### 6. Кастомные преобразователи через uses

Вместо написания логики внутри интерфейса маппера удобно выносить преобразования в отдельные классы.

```java
public class CurrencyConverter {
    public CurrencyDto toDto(CurrencyEnum entity) {
        if (entity == null) return null;
        return new CurrencyDto(entity.getCode(), entity.getSymbol());
    }
}

@Mapper(uses = CurrencyConverter.class)
public interface ProductMapper {
    ProductDto toDto(ProductEntity entity);
}
```

MapStruct автоматически найдёт метод `toDto` в `CurrencyConverter` и использует его при маппинге поля типа `CurrencyEnum`.

---

### 7. Централизованная конфигурация (@MapperConfig)

Для единообразного поведения всех мапперов в проекте создаётся конфигурационный интерфейс.

```java
@MapperConfig(
    componentModel = "spring",
    unmappedTargetPolicy = ReportingPolicy.ERROR,
    unmappedSourcePolicy = ReportingPolicy.WARN,
    nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE
)
public interface MapStructConfig {}
```

Подключение к мапперу:
```java
@Mapper(config = MapStructConfig.class)
public interface UserMapper {
    UserDto toDto(UserEntity entity);
}
```

`unmappedTargetPolicy = ReportingPolicy.ERROR` заставляет компилятор падать, если в целевом объекте остались несопоставленные поля. Это предотвращает потерю данных при изменении DTO.

---

### 8. Интеграция со Spring

Достаточно указать `componentModel = "spring"`. MapStruct сгенерирует компонент, который можно внедрять через конструктор.

```java
@Mapper(componentModel = "spring")
public interface UserMapper {
    UserDto toDto(UserEntity entity);
}

@Service
@RequiredArgsConstructor
public class UserService {
    private final UserMapper userMapper;

    public UserDto getUser(Long id) {
        UserEntity entity = repository.findById(id).orElseThrow();
        return userMapper.toDto(entity);
    }
}
```

Сгенерированный класс будет помечен `@Component` и зарегистрирован в контексте Spring.

---

### 9. Стратегии обработки null

MapStruct предоставляет тонкий контроль над поведением при работе с null:

```java
@BeanMapping(
    nullValueCheckStrategy = NullValueCheckStrategy.ALWAYS,
    nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE,
    nullValueMappingStrategy = NullValueMappingStrategy.RETURN_NULL
)
UserDto toDto(UserEntity entity);
```

- `NullValueCheckStrategy.ALWAYS` — всегда проверять источник на null перед вызовом методов.
- `NullValuePropertyMappingStrategy.IGNORE` — не перезаписывать целевые поля, если источник равен null.
- `NullValueMappingStrategy.RETURN_NULL` — возвращать null, если весь источник равен null (по умолчанию создаётся пустой объект).

---

### 10. Где смотреть сгенерированный код

После компиляции MapStruct создаёт файл `<ИмяMapper>Impl.java` в директории:
- Maven: `target/generated-sources/annotations/`
- Gradle: `build/generated/sources/annotationProcessor/java/`

Пример сгенерированной реализации:
```java
@Generated(value = "org.mapstruct.ap.MappingProcessor")
@Component
public class UserMapperImpl implements UserMapper {

    @Override
    public UserDto toDto(UserEntity source) {
        if (source == null) {
            return null;
        }

        UserDto target = new UserDto();
        target.setId(source.getId());
        target.setFullName(source.getFirstName() + " " + source.getLastName());
        if (source.getBirthDate() != null) {
            target.setBirthDate(DateTimeFormatter.ofPattern("dd.MM.yyyy").format(source.getBirthDate()));
        }
        return target;
    }
}
```

---

### 11. Типичные ошибки и рекомендации

1. **Отсутствие геттеров/сеттеров** — MapStruct работает только с JavaBean-соглашением. Приватные поля без аксессоров не будут сопоставлены.
2. **Конфликт с Lombok** — процессор Lombok должен выполняться до MapStruct. В Maven добавьте порядок в `annotationProcessorPaths`, в Gradle убедитесь, что `lombok` стоит перед `mapstruct-processor`.
3. **Игнорирование политик маппинга** — без `unmappedTargetPolicy = ReportingPolicy.ERROR` новые поля в DTO могут остаться пустыми без предупреждения.
4. **Избыточное использование expression** — сложные выражения снижают читаемость. Предпочитайте выносить логику в методы с `@Named` или в классы, подключенные через `uses`.
5. **Отсутствие проверки сгенерированного кода** — при обновлении версий MapStruct или изменении типов полей всегда проверяйте `*Impl.java`, чтобы убедиться в корректности преобразований.

MapStruct остаётся стандартом де-факто для маппинга в enterprise-проектах на Java благодаря скорости, предсказуемости и полной совместимости с современными инструментами сборки и фреймворками.