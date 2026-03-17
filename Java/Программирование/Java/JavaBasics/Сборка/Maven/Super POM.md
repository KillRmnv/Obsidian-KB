Super POM в Apache Maven — это базовый шаблонный POM-файл, встроенный в Maven по умолчанию, от которого наследуется каждый проектный pom.xml. Он содержит стандартные настройки плагинов, репозиториев (включая Maven Central), жизненные циклы и конфигурации сборки, которые применяются автоматически, если не переопределены в вашем проекте.geeksforgeeks+1

## Назначение

Super POM упрощает создание проектов, предоставляя готовые дефолтные значения — например, версии плагинов вроде compiler-plugin (3.8.1+), репозитории и привязки goals к фазам lifecycle. Без него каждый pom.xml пришлось бы дублировать эти настройки.baeldung+1

## Как просмотреть

Выполните `mvn help:effective-pom`, чтобы увидеть полную Effective POM вашего проекта (Super POM + ваш pom.xml + parent, если есть). Или скачайте Super POM напрямую: `mvn help:read -Dgoal=super-pom` или с официального сайта Maven.stackoverflow+1

## Ключевые элементы Super POM

- **modelVersion**: 4.0.0.
    
- **repositories**: Central ([https://repo.maven.apache.org/maven2](https://repo.maven.apache.org/maven2)).
    
- **pluginRepositories**: Аналогично для плагинов.
    
- **build**: Настройки compiler, surefire, jar, resources плагинов с дефолтными версиями и фазами.deepwiki+1