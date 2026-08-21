**Lazy Loading** (ленивая загрузка) — это стратегия, при которой связанные сущности загружаются из базы данных не сразу, а только в момент первого обращения к ним. Это критически важно для производительности, но требует понимания контекста персистентности.

---

## Best Practices: чек-лист

|Практика|Зачем|
|---|---|
| Всегда ставьте `fetch = LAZY` для `@ManyToOne`|Избегаете лишних `JOIN` и перегрузки памяти|
| Используйте `JOIN FETCH` только когда данные точно нужны|Иначе получите дубликаты в результате и лишнюю нагрузку|
| Возвращайте из сервисов DTO, а не сущности|Контролируете, какие данные и когда загружаются|
| Тестируйте с отключённым OSIV|`spring.jpa.open-in-view: false` выявляет скрытые проблемы с lazy|
| Не вызывайте `lazy`-поля в `toString()` / `equals()`|Риск случайной инициализации и `StackOverflowError`|
| Не используйте `CascadeType.ALL` с `LAZY` без понимания|Можно случайно загрузить весь граф объектов|

##  Частые ошибки и как их избежать

```java
//  Ошибка: обращение к lazy после закрытия сессии
Order order = orderService.findById(id); // сессия закрылась
return order.getItems().get(0); //  LazyInitializationException

//  Решение 1: загрузить в транзакции
@Transactional
public OrderItem getFirstItem(Long id) {
    Order order = orderRepo.findById(id).orElseThrow();
    return order.getItems().get(0); // OK, сессия активна
}

//  Решение 2: использовать DTO-проекцию
@Query("SELECT new com.example.dto.ItemDto(i.id, i.name) " +
       "FROM Order o JOIN o.items i WHERE o.id = :id")
List<ItemDto> findItemDtos(@Param("id") Long id);
```

---

##  Отладка: что реально загружается?

Включите логирование SQL в `application.properties`:
```properties
spring.jpa.show-sql=true
spring.jpa.properties.hibernate.format_sql=true
# Показывает параметры запросов
logging.level.org.hibernate.type.descriptor.sql.BasicBinder=TRACE
```



Ищите в логах:

- `select ... from order_items` → признак N+1 проблемы
- `join fetch` → данные загружены оптимально

---