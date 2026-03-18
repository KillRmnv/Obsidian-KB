###  Контроль времени выполнения: `setQueryTimeout()`

Метод `setQueryTimeout(int seconds)` устанавливает максимальное время в секундах, которое драйвер будет ждать выполнения запроса [](https://docs.faircom.com/doc/sqlops/41032.htm)[](https://docs.faircom.com/doc/jdbc/48580.htm)[](https://www.ibm.com/support/pages/timeout-properties-ibm-data-server-driver-jdbc-and-sqlj).

- **Как это работает**: Вы говорите: "Если запрос выполняется дольше N секунд, прерви его". Это критически важно для защиты от "зависших" или неоптимальных запросов, которые могут бесконечно потреблять ресурсы базы данных [](https://docs.faircom.com/doc/sqlops/41032.htm).
    
- **Что происходит при тайм-ауте**: По истечении установленного времени драйвер пытается отменить выполнение запроса и выбрасывает исключение `SQLException` (например, `SqlTimeoutException` в драйвере IBM DB2) [](https://www.ibm.com/support/pages/timeout-properties-ibm-data-server-driver-jdbc-and-sqlj).
    
- **Где применяется**: Метод доступен у объектов `Statement`, `PreparedStatement` и `CallableStatement` [](https://docs.faircom.com/doc/jdbc/48580.htm).
    
- **Нюансы реализации**:
    
    - Не все драйверы и базы данных поддерживают "мягкое" прерывание запроса с сохранением соединения. В некоторых случаях (например, для Db2 for z/OS) драйвер может просто принудительно закрыть сетевое соединение, чтобы прервать операцию [](https://www.ibm.com/support/pages/timeout-properties-ibm-data-server-driver-jdbc-and-sqlj).
        
    - Существуют и другие связанные таймауты, например, `blockingReadConnectionTimeout` в драйвере IBM, который контролирует ожидание данных от сервера уже после отправки запроса [](https://www.ibm.com/support/pages/timeout-properties-ibm-data-server-driver-jdbc-and-sqlj).