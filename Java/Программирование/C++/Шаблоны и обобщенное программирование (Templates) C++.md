### 1. Основы шаблонов и специализация

Шаблоны в C++ — это механизм обобщенного программирования (метапрограммирования), генерирующий конкретный код во время компиляции (**инстанцирование**).

  

#### Шаблоны функций и классов

C++

```
template <typename T>
T max(T a, T b) { return (a > b) ? a : b; }

template <typename T, size_t N> // Non-type template parameter (NTTP)
class Array {
    T data[N];
};
```

#### Специализация шаблонов

Позволяет задать специфическую реализацию для конкретного типа:

  

- **Полная специализация (Full Specialization):**
    
      
    
    C++
    
    ```
    template <>
    class Array<bool, 8> { /* Оптимизированная упаковка битов */ };
    ```
    
- **Частичная специализация (Partial Specialization):** Доступна **только для классов** (функции не поддерживают частичную специализацию, для них используется перегрузка).
    
      
    
    C++
    
    ```
    template <typename T>
    class PointerHolder<T*> { /* Специализация для любых указателей */ };
    ```
    

### 2. SFINAE и `<type_traits>`

**SFINAE** (_Substitution Failure Is Not An Error_) — если при подстановке шаблонных параметров в сигнатуру функции возникает ошибка, компилятор не останавливает сборку, а просто исключает эту перегрузку из кандидатов.

  

#### `std::enable_if` и метафункции

Используется для ограничения вызова функций по типу параметров до C++20:

  

C++

```
#include <type_traits>

// Функция скомпилируется ТОЛЬКО для целочисленных типов
template <typename T>
typename std::enable_if<std::is_integral<T>::value, bool>::type
is_even(T val) {
    return val % 2 == 0;
}
```

Модуль `<type_traits>` предоставляет интроспекцию типов в compile-time (`std::is_same`, `std::is_pointer`, `std::remove_reference` и др.).

  

### 3. Variadic Templates и Fold Expressions

**Variadic Templates** (C++11) позволяют принимать произвольное количество шаблонных аргументов (_parameter pack_).

  

#### Пакеты аргументов и раскрытие

C++

```
// Рекурсивный базовый случай
void print() {}

// Шаблон с переменным числом аргументов
template <typename T, typename... Args>
void print(T first, Args... args) {
    std::cout << first << " ";
    print(args...); // Распаковка пакета
}
```

#### Fold Expressions (C++17)

Упрощают работу с пакетами аргументов без использования рекурсии:

  

C++

```
template <typename... Args>
auto sum(Args... args) {
    return (... + args); // Unary left fold: (((arg1 + arg2) + arg3) ... )
}
```

### 4. Concepts и Constraints (C++20)

**Concepts (Концепты)** — это современный, синтаксически чистый замена SFINAE. Они определяют требования к шаблонным параметрам во время компиляции и дают понятные сообщения об ошибках.

#### Обширный пример использования Концептов

C++

```
#include <concepts>
#include <iostream>

// 1. Определение собственного концепта
template <typename T>
concept Numeric = std::is_arithmetic_v<T> && !std::is_same_v<T, bool>;

// 2. Использование концепта с ключевым словом requires
template <Numeric T>
T multiply(T a, T b) {
    return a * b;
}

// 3. Альтернативный краткий синтаксис (Terse notation)
void printNumeric(Numeric auto val) {
    std::cout << val << '\n';
}

int main() {
    multiply(10, 20);      // OK
    // multiply("a", "b"); // Понятная ошибка компиляции: constraints not satisfied
}
```

### SFINAE vs Concepts (Сравнение)

|**Характеристика**|**SFINAE (std::enable_if)**|**Concepts (C++20)**|
|---|---|---|
|**Синтаксис**|Перегружен шаблонным шумом|Четкий, декларативный (`requires`)|
|**Ошибки компиляции**|Метры непрочитаемого вывода|1-2 понятные строки|
|**Время компиляции**|Медленное (тяжелая инстанциация)|Быстрое (нативная поддержка компилятором)|