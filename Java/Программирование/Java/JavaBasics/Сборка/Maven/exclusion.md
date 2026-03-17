В Apache Maven секция `<exclusions>` в зависимостях исключает нежелательные **транзитивные зависимости** (зависимости зависимостей), которые Maven автоматически подтягивает, но могут вызывать конфликты версий, устаревшие библиотеки или проблемы безопасности.maven.apache+1

## Зачем нужны exclusions

Maven разрешает зависимости рекурсивно: если A → B → C, то C попадает в classpath автоматически. Exclusions блокируют конкретные C по `groupId` и `artifactId`, не затрагивая прямые зависимости.maven.apache+1

## Синтаксис в pom.xml

xml

`<dependency>   <groupId>com.example</groupId>  <artifactId>library-with-bad-dep</artifactId>  <version>1.0</version>  <exclusions>    <exclusion>  <!-- Исключить одну зависимость -->      <groupId>org.old</groupId>      <artifactId>old-lib</artifactId>    </exclusion>    <exclusion>  <!-- Несколько -->      <groupId>commons</groupId>      <artifactId>logging</artifactId>    </exclusion>  </exclusions> </dependency>`

## Диагностика зависимостей

- `mvn dependency:tree` — дерево зависимостей (видно, где подтягивается проблема).
    
- `mvn dependency:analyze` — неиспользуемые/недостающие зависимости.[[maven.apache](https://maven.apache.org/guides/introduction/introduction-to-optional-and-excludes-dependencies.html)]​
    

## Особенности

- Exclusion действует **только на эту ветку графа** — если та же зависимость приходит из другого пути, она останется.
    
- Wildcard `*` работает для полного исключения всех транзитивных: `<groupId>*</groupId><artifactId>*</artifactId>` (с Maven 2.0.9+).[[smartjava](http://www.smartjava.org/content/maven-and-wildcard-exclusions/)]​
    
- Для плагинов exclusions настраиваются аналогично в `<plugin><dependencies>`.