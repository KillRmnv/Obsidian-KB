Отличный вопрос! Поведение `try-catch-finally` с `return` — одна из самых тонких тем в Java. Давайте разберем все случаи подробно.

## Основные правила

1. **`finally` выполняется ВСЕГДА** (кроме случаев `System.exit()` или сбоя JVM)
2. **Возвращаемое значение определяется в момент выполнения `return`**
3. **Значение может быть переопределено в `finally`**

## Примеры с пояснениями

### 1. `return` только в `try`
```java
public class Test {
    public static int test1() {
        try {
            System.out.println("try");
            return 1;  // Значение 1 "готовится" к возврату
        } finally {
            System.out.println("finally");
            // finally выполнится ДО фактического возврата из метода
        }
    }
    
    public static void main(String[] args) {
        System.out.println(test1());
        // Вывод:
        // try
        // finally
        // 1
    }
}
```

### 2. `return` в `try` и `finally` (ПЕРЕОПРЕДЕЛЕНИЕ)
```java
public class Test {
    public static int test2() {
        try {
            System.out.println("try");
            return 1;  // Значение 1 "запоминается"
        } finally {
            System.out.println("finally");
            return 2;  // ПЕРЕОПРЕДЕЛЯЕТ возвращаемое значение!
        }
    }
    
    public static void main(String[] args) {
        System.out.println(test2());
        // Вывод:
        // try
        // finally
        // 2  <- вернется 2, а не 1!
    }
}
```

### 3. Изменение переменной в `finally`
```java
public class Test {
    public static int test3() {
        int x = 0;
        try {
            System.out.println("try");
            x = 1;
            return x;  // Возвращается ТЕКУЩЕЕ значение x (1)
        } finally {
            System.out.println("finally");
            x = 100;  // Эта запись не влияет на возвращаемое значение!
                      // Потому что return уже "зафиксировал" значение 1
        }
    }
    
    public static void main(String[] args) {
        System.out.println(test3());
        // Вывод:
        // try
        // finally
        // 1  <- не 100!
    }
}
```

### 4. Возврат объекта и изменение его в `finally`
```java
public class Test {
    static class Container {
        int value;
        Container(int v) { this.value = v; }
    }
    
    public static Container test4() {
        Container c = new Container(1);
        try {
            System.out.println("try");
            return c;  // Возвращается ССЫЛКА на объект
        } finally {
            System.out.println("finally");
            c.value = 100;  // Меняется состояние объекта по ссылке!
            // Это изменение будет видно
        }
    }
    
    public static void main(String[] args) {
        Container result = test4();
        System.out.println(result.value);
        // Вывод:
        // try
        // finally
        // 100  <- значение изменилось!
    }
}
```

### 5. `return` в `try` и исключение в `finally`
```java
public class Test {
    public static int test5() {
        try {
            System.out.println("try");
            return 1;
        } finally {
            System.out.println("finally");
            throw new RuntimeException("Exception in finally");
            // Исключение из finally ЗАТМЕНИТ возврат из try!
        }
    }
    
    public static void main(String[] args) {
        try {
            System.out.println(test5());
        } catch (Exception e) {
            System.out.println("Caught: " + e.getMessage());
        }
        // Вывод:
        // try
        // finally
        // Caught: Exception in finally
        // Метод не вернет 1 - будет выброшено исключение
    }
}
```

### 6. Полный пример с `try-catch-finally`
```java
public class Test {
    public static int test6(int mode) {
        try {
            System.out.println("try");
            if (mode == 1) {
                throw new RuntimeException("Exception in try");
            }
            return 10;
        } catch (RuntimeException e) {
            System.out.println("catch: " + e.getMessage());
            return 20;  // Значение 20 "запоминается" для возврата
        } finally {
            System.out.println("finally");
            // Если раскомментировать, переопределит любой return выше
            // return 30;
        }
    }
    
    public static void main(String[] args) {
        System.out.println("=== Без исключения ===");
        System.out.println("Result: " + test6(0));
        
        System.out.println("\n=== С исключением ===");
        System.out.println("Result: " + test6(1));
        
        // Вывод:
        // === Без исключения ===
        // try
        // finally
        // Result: 10
        // 
        // === С исключением ===
        // try
        // catch: Exception in try
        // finally
        // Result: 20
    }
}
```

## Как это работает на уровне байт-кода

Java использует специальные инструкции для реализации этого поведения:
1. При выполнении `return` значение помещается в стек операндов
2. Блок `finally` копируется в конец `try` и каждого `catch`
3. Если в `finally` есть свой `return`, он перезаписывает значение в стеке

## Практические рекомендации

1. **Избегайте `return` в `finally` блоке** — это "подавляет" исключения из `try`/`catch` и может скрыть ошибки
   ```java
   // ПЛОХО: исключение в try будет потеряно
   try {
       throw new RuntimeException("Important error!");
   } finally {
       return "OK";  // Исключение потеряно!
   }
   ```

2. **Не изменяйте переменные для возврата в `finally`** — это запутывает код

3. **Используйте `finally` для очистки ресурсов**, а не для логики возврата
   ```java
   InputStream is = null;
   try {
       is = new FileInputStream("file.txt");
       return process(is);
   } finally {
       if (is != null) {
           try { is.close(); } catch (IOException e) { /* log */ }
       }
   }
   ```

4. **С Java 7+ используйте try-with-resources**
   ```java
   try (InputStream is = new FileInputStream("file.txt")) {
       return process(is);
   }
   // Автоматически вызывается close() в finally
   ```

## Исключения из правил

`finally` НЕ выполнится, если:
1. Вызван `System.exit(0)`
2. "Упала" JVM (системный сбой)
3. Поток прерван (`Thread.stop()`) — deprecated

## Тест на закрепление

Что выведет этот код?
```java
public static String test() {
    String s = "hello";
    try {
        s = s + " try";
        return s;
    } finally {
        s = s + " finally";
        System.out.println("Inside finally: " + s);
    }
}

public static void main(String[] args) {
    System.out.println("Result: " + test());
}
```

**Ответ:**
```
Inside finally: hello try finally
Result: hello try
```
Объект `String` неизменяем, а `return` уже "зафиксировал" значение `"hello try"`.

**Вывод:** Блок `finally` — мощный инструмент, но его взаимодействие с `return` требует понимания. Лучшая практика — не смешивать логику возврата значений и код очистки в `finally`.