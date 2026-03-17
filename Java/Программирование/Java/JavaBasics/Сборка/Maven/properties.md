Секция `<properties>` в Maven отвечает за определение пользовательских переменных (ключ-значение), которые используются как placeholders в pom.xml для упрощения конфигурации и избежания дублирования. Они подставляются через `${имя_свойства}` в зависимостях, плагинах, профилях и других местах.skillbox+1

## Основные функции

Properties позволяют централизованно задавать версии библиотек, пути, флаги компиляции или URL, делая pom.xml DRY (Don't Repeat Yourself). Например, выносят `<maven.compiler.source>11</maven.compiler.source>` или `<spring.version>6.1.0</spring.version>` для переиспользования.javarush+1

## Типы свойств

- **Пользовательские**: Определяются в `<properties>` pom.xml или parent.
    
- **Встроенные проекта**: `${project.version}`, `${project.groupId}`, `${project.build.directory}` (target).[[javarush](https://javarush.com/quests/lectures/questservlets.level01.lecture06)]​
    
- **Системные**: `${java.home}`, `${env.PATH}` (переменные окружения).[[apache-maven.simplex-software](https://apache-maven.simplex-software.ru/advanced/property.html)]​
    
- **Из settings.xml**: `${settings.localRepository}`.[[stackoverflow](https://stackoverflow.com/questions/65696058/what-does-properties-tag-mean-in-pom-xml-maven)]​
    

## Пример использования

xml

`<properties>   <java.version>17</java.version>  <junit.version>5.10</junit.version> </properties> <properties>   <maven.compiler.source>${java.version}</maven.compiler.source> </properties> <dependencies>   <dependency>    <groupId>org.junit.jupiter</groupId>    <artifactId>junit-jupiter</artifactId>    <version>${junit.version}</version>  </dependency> </properties>`

Переопределение: `mvn clean install -Djava.version=21`.skillbox+1