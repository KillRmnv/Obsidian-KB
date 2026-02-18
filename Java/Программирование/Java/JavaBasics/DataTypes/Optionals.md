
empty() returns empty Optional
```java
@Test
public void whenCreatesEmptyOptional_thenCorrect() {
    Optional<String> empty = Optional.empty();
    assertFalse(empty.isPresent());
}
```

of(value) passes value into optional
```java
@Test
public void givenNonNull_whenCreatesNonNullable_thenCorrect() {
    String name = "baeldung";
    Optional<String> opt = Optional.of(name);
    assertTrue(opt.isPresent());
}
```

Like of(),but works with nulls
```java
@Test
public void givenNonNull_whenCreatesNullable_thenCorrect() {
    String name = "baeldung";
    Optional<String> opt = Optional.ofNullable(name);
    assertTrue(opt.isPresent());
}
```

```java
@Test
public void givenOptional_whenIfPresentWorks_thenCorrect() {
    Optional<String> opt = Optional.of("baeldung");
    opt.ifPresent(name -> System.out.println(name.length()));
}
```

```java
@Test
public void whenOrElseWorks_thenCorrect() {
    String nullName = null;
    String name = Optional.ofNullable(nullName).orElse("john");
    assertEquals("john", name);
}
```

```java
@Test
public void whenOrElseGetWorks_thenCorrect() {
    String nullName = null;
    String name = Optional.ofNullable(nullName).orElseGet(() -> "john");
    assertEquals("john", name);
}
```
Difference between orElse() and orElseGet() that orElseGet() does not create diffault value, if value is present in Optional, and one methods takes value as parameter while the other takes function
```java
@Test(expected = IllegalArgumentException.class)
public void whenOrElseThrowWorks_thenCorrect() {
    String nullName = null;
    String name = Optional.ofNullable(nullName).orElseThrow(
      IllegalArgumentException::new);
}
```

```java
@Test
public void givenOptional_whenGetsValue_thenCorrect() {
    Optional<String> opt = Optional.of("baeldung");
    String name = opt.get();
    assertEquals("baeldung", name);
}
```


```java
@Test
public void whenOptionalFilterWorks_thenCorrect() {
    Integer year = 2016;
    Optional<Integer> yearOptional = Optional.of(year);
    boolean is2016 = yearOptional.filter(y -> y == 2016).isPresent();
    assertTrue(is2016);
    boolean is2017 = yearOptional.filter(y -> y == 2017).isPresent();
    assertFalse(is2017);
}
```


Метод `map` у `Optional` позволяет **преобразовать хранящееся значение**, если оно есть, и вернуть новый `Optional`.  
Если значение пустое — вернётся `Optional.empty()`.
```java
Optional<String> opt = Optional.of("hello");

Optional<String> upper = opt.map(String::toUpperCase);

System.out.println(upper.get()); // HELLO

```

JDK 9
or() is like orElse(), but returns Optional,not wrapped value
```java
@Test
public void givenOptional_whenPresent_thenShouldTakeAValueFromIt() {
    //given
    String expected = "properValue";
    Optional<String> value = Optional.of(expected);
    Optional<String> defaultValue = Optional.of("default");

    //when
    Optional<String> result = value.or(() -> defaultValue);

    //then
    assertThat(result.get()).isEqualTo(expected);
}
```


```java
@Test
public void givenOptional_whenPresent_thenShouldExecuteProperCallback() {
    // given
    Optional<String> value = Optional.of("properValue");
    AtomicInteger successCounter = new AtomicInteger(0);
    AtomicInteger onEmptyOptionalCounter = new AtomicInteger(0);

    // when
    value.ifPresentOrElse(
      v -> successCounter.incrementAndGet(), 
      onEmptyOptionalCounter::incrementAndGet);

    // then
    assertThat(successCounter.get()).isEqualTo(1);
    assertThat(onEmptyOptionalCounter.get()).isEqualTo(0);
}
```

Java version  9 introduces the _stream()_ method on the _Optional_ class that **allows us to treat the _Optional_ instance as a _Stream._**
```java
@Test
public void givenOptionalOfSome_whenToStream_thenShouldTreatItAsOneElementStream() {
    // given
    Optional<String> value = Optional.of("a");

    // when
    List<String> collect = value.stream().map(String::toUpperCase).collect(Collectors.toList());

    // then
    assertThat(collect).hasSameElementsAs(List.of("A"));
}
```

![[Pasted image 20260113225157.png]]
![[Pasted image 20260113225730.png]]