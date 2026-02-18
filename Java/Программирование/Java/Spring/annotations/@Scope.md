@Component
@Scope("prototype") // новый объект каждый раз
public class MyPrototypeBean {}
Singleton (по умолчанию) — один объект на контейнер.

Prototype — новый объект при каждом вызове.

Есть и request/session для web-приложений.