В Java `T` и `?` — это разные механизмы дженериков: **параметр типа** и **подстановочный (wildcard) тип** соответственно.stackoverflow+1​

## Что такое `<T>`

`T` — это **параметр типа**, который вы объявляете и потом используете внутри класса/интерфейса/метода.javarush+1​

java

`class Box<T> {     private T value;    void set(T v) { value = v; }    T get() { return value; } }`

Особенности:

- `T` **фиксируется** при использовании: `Box<String>`, `Box<Integer>` и т.д.[stackoverflow](https://ru.stackoverflow.com/questions/1128951/java-generics-%D0%92-%D1%87%D0%B5%D0%BC-%D1%80%D0%B0%D0%B7%D0%BD%D0%B8%D1%86%D0%B0-%D0%BC%D0%B5%D0%B6%D0%B4%D1%83-wildcard-%D0%B8-parameterized-typest)​
    
- Внутри `Box<T>` вы можете **и читать, и писать** значения типа `T` (параметр известен для этого экземпляра).[javarush](https://javarush.com/quests/lectures/questcollections.level05.lecture07)​
    
- Для метода с отдельным `<T>`:
    
    java
    
    `<T> void copy(List<T> src, List<T> dst) { ... }`
    
    Оба списка должны иметь **один и тот же конкретный тип** `T` (например, оба `List<String>`).[stackoverflow](https://ru.stackoverflow.com/questions/1128951/java-generics-%D0%92-%D1%87%D0%B5%D0%BC-%D1%80%D0%B0%D0%B7%D0%BD%D0%B8%D1%86%D0%B0-%D0%BC%D0%B5%D0%B6%D0%B4%D1%83-wildcard-%D0%B8-parameterized-typest)​
    

## Что такое `<?>`

`?` — это **wildcard**: «какой‑то тип, но неизвестно какой».javarush+1​

java

`List<?> list;      // список чего‑то, тип элементов неизвестен List<? extends N>  // список чего‑то, что является подтипом N List<? super N>    // список чего‑то, что является надтипом N`

Особенности:

- `?` **не объявляет нового параметра** типа, это просто заглушка «не знаю, что тут за тип».[stackoverflow](https://ru.stackoverflow.com/questions/1128951/java-generics-%D0%92-%D1%87%D0%B5%D0%BC-%D1%80%D0%B0%D0%B7%D0%BD%D0%B8%D1%86%D0%B0-%D0%BC%D0%B5%D0%B6%D0%B4%D1%83-wildcard-%D0%B8-parameterized-typest)​
    
- С `List<?>` вы **можете безопасно только читать** элементы как `Object`, но почти ничего не можете туда записывать (кроме `null`). Тип неизвестен, поэтому нельзя гарантировать безопасность записи.[javarush](https://javarush.com/quests/lectures/questcollections.level05.lecture07)​
    
- Wildcards часто используются **в сигнатурах методов**, когда параметр только читается или только пишется (PECS: Producer Extends, Consumer Super).[javarush](https://javarush.com/quests/lectures/questcollections.level05.lecture07)​
    

## Интуитивная разница

Пример из вопроса на RuSO:[stackoverflow](https://ru.stackoverflow.com/questions/1128951/java-generics-%D0%92-%D1%87%D0%B5%D0%BC-%D1%80%D0%B0%D0%B7%D0%BD%D0%B8%D1%86%D0%B0-%D0%BC%D0%B5%D0%B6%D0%B4%D1%83-wildcard-%D0%B8-parameterized-typest)​

java

`class Stats<T extends Number> {     T[] nums;     Stats(T[] nums) { this.nums = nums; }     double avg() { ... }     // Вариант 1: параметр T    boolean sameAvg(Stats<T> ob) { ... }     // Вариант 2: wildcard    boolean sameAvg(Stats<?> ob) { ... } }`

- Вариант с `Stats<T>`:  
    Если у вас `Stats<Integer> s1`, то `sameAvg` примет **только** `Stats<Integer>`, но не `Stats<Double>` — `T` должен быть тем же типом.[stackoverflow](https://ru.stackoverflow.com/questions/1128951/java-generics-%D0%92-%D1%87%D0%B5%D0%BC-%D1%80%D0%B0%D0%B7%D0%BD%D0%B8%D1%86%D0%B0-%D0%BC%D0%B5%D0%B6%D0%B4%D1%83-wildcard-%D0%B8-parameterized-typest)​
    
- Вариант с `Stats<?>`:  
    Метод может принять `Stats<Integer>`, `Stats<Double>`, `Stats<Long>` и т.д., потому что в сигнатуре «любой Stats с любым Number внутри».[stackoverflow](https://ru.stackoverflow.com/questions/1128951/java-generics-%D0%92-%D1%87%D0%B5%D0%BC-%D1%80%D0%B0%D0%B7%D0%BD%D0%B8%D1%86%D0%B0-%D0%BC%D0%B5%D0%B6%D0%B4%D1%83-wildcard-%D0%B8-parameterized-typest)​
    

То есть:

- `T` — «**конкретный, но неизвестный заранее тип**, который должен быть одним и тем же в нескольких местах».[stackoverflow](https://ru.stackoverflow.com/questions/1128951/java-generics-%D0%92-%D1%87%D0%B5%D0%BC-%D1%80%D0%B0%D0%B7%D0%BD%D0%B8%D1%86%D0%B0-%D0%BC%D0%B5%D0%B6%D0%B4%D1%83-wildcard-%D0%B8-parameterized-typest)​
    
- `?` — «**какой‑то тип, и мне не важно какой именно, я не собираюсь на него полагаться для записи**».javarush+1​
    

## В плане «можно/нельзя»

Для коллекций это часто формулируют так:

- `List<T>` (параметр типа) — **можно и читать, и писать** `T`.
    
- `List<? extends X>` — **читаем как `X`, писать нельзя** (кроме `null`). Producer.
    
- `List<? super X>` — **пишем `X`, читаем как `Object`**. Consumer.[javarush](https://javarush.com/quests/lectures/questcollections.level05.lecture07)​
    

Если кратко:

- Нужен **собственный тип-параметр**, связанный между несколькими аргументами/полями → используй `<T>`.
    
- Нужна **гибкая сигнатура метода**, где важен только факт «что‑то из иерархии X» → используй `?` (`? extends` / `? super`).
    

1. [https://udsau.ru/images/rio/Vestnik/2025_2/112-117.pdf](https://udsau.ru/images/rio/Vestnik/2025_2/112-117.pdf)
2. [https://elibrary.ru/item.asp?id=82824697](https://elibrary.ru/item.asp?id=82824697)
3. [https://www.elibrary.ru/item.asp?id=55081639](https://www.elibrary.ru/item.asp?id=55081639)
4. [https://ulsu.ru/ru/page/page_4693/](https://ulsu.ru/ru/page/page_4693/)
5. [https://zhurnal.vfanc.ru/wp-content/uploads/2024/01/13-4-2023.pdf](https://zhurnal.vfanc.ru/wp-content/uploads/2024/01/13-4-2023.pdf)
6. [https://archaeology.nsc.ru/izdatelstvo/jr-aeae-ru/24-52-2/annot-04/](https://archaeology.nsc.ru/izdatelstvo/jr-aeae-ru/24-52-2/annot-04/)
7. [https://journals.ioffe.ru/articles/53714](https://journals.ioffe.ru/articles/53714)
8. [https://sportedu.org.ua/index.php/PES/article/view/41](https://sportedu.org.ua/index.php/PES/article/view/41)
9. [http://potatoveg.ru/kartofelevodstvo/vliyanie-guminovyx-preparatov-na-produktivnost-i-kachestvo-urozhaya-sortov-kartofelya-s-fioletovoj-myakotyu-klubnej.html](http://potatoveg.ru/kartofelevodstvo/vliyanie-guminovyx-preparatov-na-produktivnost-i-kachestvo-urozhaya-sortov-kartofelya-s-fioletovoj-myakotyu-klubnej.html)
10. [http://ojs3.gpmu.org/index.php/medorg/article/view/4137](http://ojs3.gpmu.org/index.php/medorg/article/view/4137)
11. [https://arxiv.org/pdf/2010.05167.pdf](https://arxiv.org/pdf/2010.05167.pdf)
12. [https://arxiv.org/pdf/1906.03937.pdf](https://arxiv.org/pdf/1906.03937.pdf)
13. [http://arxiv.org/pdf/1906.11197.pdf](http://arxiv.org/pdf/1906.11197.pdf)
14. [http://arxiv.org/pdf/2412.03126.pdf](http://arxiv.org/pdf/2412.03126.pdf)
15. [https://arxiv.org/pdf/2307.08759.pdf](https://arxiv.org/pdf/2307.08759.pdf)
16. [https://www.qeios.com/read/4EJCAG/pdf](https://www.qeios.com/read/4EJCAG/pdf)
17. [http://arxiv.org/pdf/2209.07427.pdf](http://arxiv.org/pdf/2209.07427.pdf)
18. [https://arxiv.org/pdf/1407.8251.pdf](https://arxiv.org/pdf/1407.8251.pdf)
19. [https://ru.stackoverflow.com/questions/1128951/java-generics-%D0%92-%D1%87%D0%B5%D0%BC-%D1%80%D0%B0%D0%B7%D0%BD%D0%B8%D1%86%D0%B0-%D0%BC%D0%B5%D0%B6%D0%B4%D1%83-wildcard-%D0%B8-parameterized-typest](https://ru.stackoverflow.com/questions/1128951/java-generics-%D0%92-%D1%87%D0%B5%D0%BC-%D1%80%D0%B0%D0%B7%D0%BD%D0%B8%D1%86%D0%B0-%D0%BC%D0%B5%D0%B6%D0%B4%D1%83-wildcard-%D0%B8-parameterized-typest)
20. [https://javarush.com/quests/lectures/questcollections.level05.lecture07](https://javarush.com/quests/lectures/questcollections.level05.lecture07)