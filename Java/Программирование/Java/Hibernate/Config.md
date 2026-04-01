# Конфигурация Hibernate

Hibernate — это мощный ORM-фреймворк для работы с базами данных в Java-приложениях. Правильная конфигурация играет ключевую роль в производительности, безопасности и поддерживаемости приложения. Ниже приведено подробное руководство по настройке Hibernate.

---

## 1. Основные способы конфигурации

### 1.1. `hibernate.cfg.xml` (классический способ)

```xml
<!DOCTYPE hibernate-configuration PUBLIC
    "-//Hibernate/Hibernate Configuration DTD 3.0//EN"
    "http://www.hibernate.org/dtd/hibernate-configuration-3.0.dtd">

<hibernate-configuration>
    <session-factory>
        <!-- JDBC настройки -->
        <property name="hibernate.connection.driver_class">com.mysql.cj.jdbc.Driver</property>
        <property name="hibernate.connection.url">jdbc:mysql://localhost:3306/mydb</property>
        <property name="hibernate.connection.username">root</property>
        <property name="hibernate.connection.password">password</property>

        <!-- Диалект -->
        <property name="hibernate.dialect">org.hibernate.dialect.MySQL8Dialect</property>

        <!-- Показать SQL -->
        <property name="hibernate.show_sql">true</property>
        <property name="hibernate.format_sql">true</property>

        <!-- DDL автоматизация -->
        <property name="hibernate.hbm2ddl.auto">update</property>

        <!-- Кэш -->
        <property name="hibernate.cache.use_second_level_cache">true</property>
        <property name="hibernate.cache.region.factory_class">org.hibernate.cache.ehcache.EhCacheRegionFactory</property>

        <!-- Маппинг -->
        <mapping class="com.example.User"/>
        <mapping resource="User.hbm.xml"/>
    </session-factory>
</hibernate-configuration>
```

### 1.2. `hibernate.properties`

```properties
hibernate.connection.driver_class=com.mysql.cj.jdbc.Driver
hibernate.connection.url=jdbc:mysql://localhost:3306/mydb
hibernate.connection.username=root
hibernate.connection.password=password
hibernate.dialect=org.hibernate.dialect.MySQL8Dialect
hibernate.show_sql=true
hibernate.format_sql=true
hibernate.hbm2ddl.auto=update
```

### 1.3. Java Config (программная конфигурация)

```java
Configuration config = new Configuration();
config.configure("hibernate.cfg.xml");

// или
Properties props = new Properties();
props.put("hibernate.connection.driver_class", "com.mysql.cj.jdbc.Driver");
props.put("hibernate.connection.url", "jdbc:mysql://localhost:3306/mydb");
props.put("hibernate.connection.username", "root");
props.put("hibernate.connection.password", "password");
props.put("hibernate.dialect", "org.hibernate.dialect.MySQL8Dialect");

Configuration config = new Configuration();
config.addProperties(props);
config.addAnnotatedClass(User.class);

SessionFactory sessionFactory = config.buildSessionFactory();
```

### 1.4. Spring Boot (`application.properties` / `application.yml`)

```properties
spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=true
spring.jpa.properties.hibernate.format_sql=true
spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.MySQL8Dialect

spring.datasource.url=jdbc:mysql://localhost:3306/mydb
spring.datasource.username=root
spring.datasource.password=password
spring.datasource.driver-class-name=com.mysql.cj.jdbc.Driver
```

---

## 2. Ключевые настройки

### 2.1. Подключение к БД

| Свойство | Описание |
|----------|----------|
| `hibernate.connection.driver_class` | JDBC драйвер |
| `hibernate.connection.url` | URL подключения |
| `hibernate.connection.username` | Имя пользователя |
| `hibernate.connection.password` | Пароль |

### 2.2. Диалект базы данных

| БД | Диалект |
|----|---------|
| MySQL 8+ | `org.hibernate.dialect.MySQL8Dialect` |
| PostgreSQL | `org.hibernate.dialect.PostgreSQLDialect` |
| Oracle | `org.hibernate.dialect.OracleDialect` |
| H2 | `org.hibernate.dialect.H2Dialect` |

### 2.3. DDL автоматизация (`hbm2ddl.auto`)

| Значение | Описание |
|----------|----------|
| `none` | Без изменений |
| `validate` | Проверка схемы |
| `update` | Обновление схемы |
| `create` | Создание с потерей данных |
| `create-drop` | Создание и удаление при остановке |

> ⚠️ В продакшене используйте `validate` или `none`.

### 2.4. Логирование и отладка

```properties
hibernate.show_sql=true
hibernate.format_sql=true
hibernate.use_sql_comments=true
hibernate.generate_statistics=true
```

### 2.5. Кэширование

```properties
hibernate.cache.use_second_level_cache=true
hibernate.cache.use_query_cache=true
hibernate.cache.region.factory_class=org.hibernate.cache.ehcache.EhCacheRegionFactory
```

### 2.6. Пул соединений

```properties
hibernate.connection.provider_class=org.hibernate.c3p0.internal.C3P0ConnectionProvider
hibernate.c3p0.min_size=5
hibernate.c3p0.max_size=20
hibernate.c3p0.timeout=300
hibernate.c3p0.max_statements=50
```

### 2.7. Производительность

```properties
hibernate.jdbc.batch_size=20
hibernate.order_inserts=true
hibernate.order_updates=true
hibernate.jdbc.fetch_size=50
hibernate.default_batch_fetch_size=16
```

---

## 3. Пример полной конфигурации для продакшена

```xml
<property name="hibernate.connection.driver_class">com.mysql.cj.jdbc.Driver</property>
<property name="hibernate.connection.url">jdbc:mysql://prod-db:3306/mydb?useSSL=true</property>
<property name="hibernate.connection.username">app_user</property>
<property name="hibernate.connection.password">${DB_PASSWORD}</property>

<property name="hibernate.dialect">org.hibernate.dialect.MySQL8Dialect</property>
<property name="hibernate.hbm2ddl.auto">validate</property>

<property name="hibernate.show_sql">false</property>
<property name="hibernate.format_sql">false</property>

<property name="hibernate.cache.use_second_level_cache">true</property>
<property name="hibernate.cache.use_query_cache">true</property>
<property name="hibernate.cache.region.factory_class">org.hibernate.cache.ehcache.EhCacheRegionFactory</property>

<property name="hibernate.c3p0.min_size">10</property>
<property name="hibernate.c3p0.max_size">50</property>
<property name="hibernate.c3p0.timeout">300</property>
<property name="hibernate.c3p0.max_statements">100</property>

<property name="hibernate.jdbc.batch_size">30</property>
<property name="hibernate.order_inserts">true</property>
<property name="hibernate.order_updates">true</property>
<property name="hibernate.jdbc.fetch_size">50</property>
```

---

## 4. Best Practices

✅ **Рекомендуется:**
- Использовать `validate` или `none` в продакшене
- Выносить чувствительные данные в переменные окружения
- Включать кэширование второго уровня
- Настраивать пул соединений
- Использовать пакетную обработку для больших объемов данных

❌ **Избегать:**
- `create` или `create-drop` в продакшене
- Хардкод паролей
- `show_sql=true` в продакшене
- Отключение кэша без причины

---

## 5. Подключение в Spring Boot

```java
@Configuration
@EnableJpaRepositories
@EntityScan
public class HibernateConfig {

    @Bean
    public LocalContainerEntityManagerFactoryBean entityManagerFactory(
            DataSource dataSource, JpaVendorAdapter jpaVendorAdapter) {

        LocalContainerEntityManagerFactoryBean em = new LocalContainerEntityManagerFactoryBean();
        em.setDataSource(dataSource);
        em.setPackagesToScan("com.example.model");
        em.setJpaVendorAdapter(jpaVendorAdapter);

        Properties props = new Properties();
        props.put("hibernate.hbm2ddl.auto", "validate");
        props.put("hibernate.show_sql", "false");
        props.put("hibernate.format_sql", "true");
        em.setJpaProperties(props);

        return em;
    }

    @Bean
    public JpaVendorAdapter jpaVendorAdapter() {
        HibernateJpaVendorAdapter adapter = new HibernateJpaVendorAdapter();
        adapter.setShowSql(false);
        adapter.setGenerateDdl(false);
        adapter.setDatabasePlatform("org.hibernate.dialect.MySQL8Dialect");
        return adapter;
    }
}
```
