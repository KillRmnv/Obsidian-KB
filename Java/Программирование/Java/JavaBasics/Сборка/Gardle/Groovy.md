Groovy — это динамический, объектно-ориентированный язык программирования, полностью совместимый с Java, который компилируется в байт-код JVM и позволяет использовать Java-библиотеки без ограничений. Он сочетает синтаксис Java с возможностями Python, Ruby и Smalltalk, упрощая код за счёт опциональной типизации, замыканий и метапрограммирования.app-android+1

## Основные особенности

Groovy поддерживает **статическую и динамическую типизацию**: `def x = 5` (динамическая) или `int x = 5` (статическая). Всё — объект, даже примитивы автоматически упаковываются (autoboxing). Синтаксис упрощён: без точек с запятой, с `safe navigation` (?.) для null-безопасности и `Elvis operator` ?: для значений по умолчанию.appfox+1

Расширенная работа с коллекциями: списки `[1,2,3]`, карты `[a:1, b:2]`, ranges `0..9`. Встроенная поддержка regex (`~'abc'`) и GStrings ("${var}").[[blog.skillfactory](https://blog.skillfactory.ru/glossary/groovy/)]​

## Синтаксис и примеры

Простая программа:

groovy

`println "Hello, ${name ?: 'World'}!" list = [1,2,3] println list.collect { it * 2 }  // [2,4,6]`

Классы с property-синтаксисом:

groovy

`class Person {     String name    int age } p = new Person(name: 'Alice', age: 30) println p.name  // Alice (getter/auto)`

Перегрузка операторов и MOP (Meta Object Protocol) позволяют динамически добавлять методы.seo-kompaniya+1

## Установка и запуск

Установите через SDKMAN: `sdk install groovy`. Команды: `groovy script.groovy` или `groovysh` (REPL). В проектах — через Gradle (build.gradle на Groovy DSL) или Maven.[[app-android](https://app-android.ru/blog/yazyik-programmirovaniya-groovy)]​

## Применение

- **Gradle скрипты** (build.gradle) — основной use-case для Java/ML-разработчиков [предыдущий контекст].
    
- Jenkins pipelines, Grails (MVC-фреймворк), Spock (тесты).
    
- Data processing: GPars для параллелизма, ETL-скрипты.
    
- В вашем стеке (Java, Linux, AI-агенты): идеален для автоматизации в tmux/wezterm, скриптинга datasets.wikipedia+1
    

## Сравнение с Java

|Аспект|Java|Groovy|
|---|---|---|
|Типизация|Только статическая|Стат+дин (def) [[blog.skillfactory](https://blog.skillfactory.ru/glossary/groovy/)]​|
|Синтаксис|Verbose (getters/setters)|Краткий (properties) [[habr](https://habr.com/ru/articles/122127/)]​|
|Коллекции|Streams (Java 8+)|each/collect/spread [[appfox](https://appfox.ru/blog/yazyk-programmirovaniya-groovy/)]​|
|Null-safety|Ручная|?. , ?: [[app-android](https://app-android.ru/blog/yazyik-programmirovaniya-groovy)]​|
|Производительность|Выше (статическая)|Ниже, но @CompileStatic ускоряет [[seo-kompaniya](https://seo-kompaniya.ru/blog/apache-groovy/)]​|

Groovy ускоряет прототипирование Java-проектов, особенно в сборке (как в Gradle vs Maven).[[ru.wikipedia](https://ru.wikipedia.org/wiki/Groovy)]​