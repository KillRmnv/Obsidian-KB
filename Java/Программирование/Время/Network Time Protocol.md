# **Network Time Protocol (NTP)**

## **Что такое NTP?**

**NTP** — это протокол прикладного уровня для **синхронизации времени** в компьютерных системах через сеть с точностью до **миллисекунд** (а в последних версиях — до **микросекунд**).

## **Архитектура и иерархия**

### **Страты (уровни) NTP:**

```
Stratum 0: Атомные часы, GPS приемники
      ↓
Stratum 1: Серверы, напрямую подключенные к Stratum 0
      ↓
Stratum 2: Серверы, синхронизирующиеся с Stratum 1
      ↓
Stratum 3: Серверы, синхронизирующиеся с Stratum 2
      ↓
... (до Stratum 15)
      ↓
Stratum 16: Несинхронизированные устройства
```

### **Пример иерархии:**
```
[Атомные часы/GPS] (Stratum 0)
         |
   [NTP-сервер 1] (Stratum 1) - точность ±1 мс
         |
   [NTP-сервер 2] (Stratum 2) - ±10 мс
         |
[Локальный сервер] (Stratum 3) - ±100 мс
         |
  [Рабочие станции] (Stratum 4) - ±1 с
```

## **Как работает NTP**

### **Основной алгоритм:**
```
Клиент                           Сервер
   |                                |
   |------ Запрос (T1) ------------>|
   |                                |
   |<---- Ответ (T2, T3, T4) -------|
   | T2 = время получения запроса   |
   | T3 = время отправки ответа     |
```

### **Расчет задержки и коррекции:**
```python
# Временные метки:
T1 = время отправки запроса (клиент)
T2 = время получения запроса (сервер)
T3 = время отправки ответа (сервер)
T4 = время получения ответа (клиент)

# Задержка передачи:
delay = (T4 - T1) - (T3 - T2)

# Смещение часов:
offset = ((T2 - T1) + (T3 - T4)) / 2

# Корректировка времени:
correct_time = current_time + offset
```

### **Пример расчета:**
```
T1 = 100.0 (клиент отправил)
T2 = 105.0 (сервер получил)  ← серверные часы идут быстрее
T3 = 106.0 (сервер отправил)
T4 = 108.0 (клиент получил)

delay = (108.0 - 100.0) - (106.0 - 105.0) = 7.0
offset = ((105.0 - 100.0) + (106.0 - 108.0)) / 2 = (5.0 - 2.0)/2 = 1.5

Клиент должен добавить 1.5 к своим часам
```

## **Конфигурация NTP**

### **Файл конфигурации `/etc/ntp.conf` (Linux):**
```conf
# Стратум 1 серверы (публичные)
server 0.pool.ntp.org iburst
server 1.pool.ntp.org iburst
server 2.pool.ntp.org iburst
server 3.pool.ntp.org iburst

# Локальные часы как fallback
server 127.127.1.0   # локальные часы
fudge 127.127.1.0 stratum 10

# Ограничения доступа
restrict default nomodify notrap nopeer noquery
restrict 127.0.0.1    # доступ localhost
restrict 192.168.1.0 mask 255.255.255.0 # локальная сеть

# Статистика
driftfile /var/lib/ntp/ntp.drift
statistics loopstats peerstats clockstats
filegen loopstats file loopstats type day enable
```

### **Windows NTP конфигурация:**
```powershell
# Показать текущую конфигурацию
w32tm /query /configuration

# Синхронизировать время
w32tm /resync

# Указать NTP сервер
w32tm /config /manualpeerlist:"pool.ntp.org" /syncfromflags:manual /reliable:yes
net stop w32time && net start w32time
```

## **Точность и источники времени**

### **Точность разных источников:**
| Источник | Точность | Стратум | Задержка |
|----------|----------|---------|----------|
| **GPS** | ±100 нс | 0 | Несколько метров/километров |
| **Атомные часы** | ±1 нс | 0 | Локально |
| **Радиосигналы** (DCF77, WWVB) | ±10 мс | 1 | Регионально |
| **Интернет NTP** | ±10-100 мс | 2-3 | Глобально |
| **Локальные часы** | ±500 мс/день | 16 | Локально |

### **Частоты NTP-серверов:**
- **pool.ntp.org** — ротация серверов
- **time.google.com** — Google Public NTP
- **time.windows.com** — Microsoft
- **time.apple.com** — Apple
- **ntp.nasa.gov** — NASA

## **Алгоритмы NTP**

### **Clock Filter Algorithm:**
```python
# Сохраняет последние 8 измерений
measurements = [(offset1, delay1), (offset2, delay2), ...]

# Отбрасывает выбросы
filtered = reject_outliers(measurements)

# Выбирает лучший offset
best_offset = select_best(filtered)
```

### **Clock Discipline Algorithm:**
```c
// PLL (Phase-Locked Loop) алгоритм
void ntp_adjust_clock(double offset, double frequency_error) {
    // Пропорционально-интегральный регулятор
    double proportional = offset * P_GAIN;
    double integral = frequency_error * I_GAIN;
    
    // Плавная корректировка
    double adjustment = proportional + integral;
    
    // Применяем корректировку к системным часам
    adjtime(adjustment);
}
```

## **Безопасность NTP**

### **Угрозы:**
1. **NTP Amplification DDoS**
2. **Time spoofing**
3. **Man-in-the-middle атаки**

### **Защита:**
```conf
# В ntp.conf
# Аутентификация
keys /etc/ntp.keys
trustedkey 1 2 3 4 5
requestkey 1
controlkey 1

# Ограничение запросов
restrict default kod limited nomodify notrap nopeer noquery
restrict -6 default kod limited nomodify notrap nopeer noquery

# NTPsec (безопасная версия)
server ntp.isc.org iburst autokey
```

## **NTP vs PTP vs SNTP**

### **Сравнение:**
| Протокол | Точность | Сложность | Использование |
|----------|----------|-----------|---------------|
| **SNTP** | ±100 мс | Простая | Встроенные устройства |
| **NTPv4** | ±1-10 мс | Средняя | Корпоративные сети |
| **PTP** | ±1 мкс | Сложная | Финансовые системы, медиа |

## **Практическое использование**

### **Linux команды:**
```bash
# Установка и запуск
sudo apt install ntp  # Debian/Ubuntu
sudo systemctl enable ntp
sudo systemctl start ntp

# Проверка статуса
ntpq -p  # Список пиров
ntpstat  # Статус синхронизации

# Ручная синхронизация
sudo ntpdate -s pool.ntp.org
sudo hwclock --systohc  # Системное время -> аппаратные часы
```

### **Мониторинг:**
```bash
# Проверка смещения
ntpdate -q pool.ntp.org

# Детальная информация
ntpq -c "rv 0 offset"
ntpq -c as  # Ассоциации

# Логи
tail -f /var/log/syslog | grep ntp
```

### **Docker контейнер:**
```dockerfile
FROM alpine:latest
RUN apk add --no-cache ntp
COPY ntp.conf /etc/ntp.conf
CMD ["ntpd", "-n", "-g"]
```

## **Проблемы и отладка**

### **Распространенные проблемы:**

1. **Большое смещение:**
```bash
# Принудительная синхронизация
sudo service ntp stop
sudo ntpdate -b pool.ntp.org
sudo service ntp start
```

2. **Нет синхронизации:**
```bash
# Проверка доступа
ntpdate -d pool.ntp.org

# Проверка портов
netstat -tuln | grep 123
```

3. **Дрейф времени:**
```bash
# Проверка drift файла
cat /var/lib/ntp/ntp.drift
# Значение в ppm (частей на миллион)
```

## **NTP в распределенных системах**

### **Пример для Kubernetes:**
```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: ntp-client
spec:
  template:
    spec:
      hostPID: true  # Для доступа к системным часам
      containers:
      - name: ntp
        image: cturra/ntp
        securityContext:
          privileged: true
```

### **Пример для AWS:**
```bash
# Использование Amazon Time Sync Service
# На EC2 инстансах
sudo yum install chrony  # Amazon Linux
sudo systemctl enable chronyd
sudo systemctl start chronyd

# Chrony конфигурация
server 169.254.169.123 prefer iburst  # Amazon Time
```

## **Chrony vs NTPd**

### **Chrony (современная альтернатива):**
```conf
# /etc/chrony.conf
server pool.ntp.org iburst
driftfile /var/lib/chrony/drift
makestep 1.0 3  # Агрессивная коррекция при большом смещении
rtcsync  # Синхронизация с аппаратными часами
```

**Преимущества Chrony:**
- Лучше работает в мобильных средах
- Быстрее синхронизация
- Меньше ресурсов

## **NTP в микросервисах**

```java
// Spring Boot пример
@Configuration
public class TimeConfig {
    
    @Bean
    public NtpClient ntpClient() {
        NtpClient ntpClient = new NtpClient();
        ntpClient.setDefaultTimeout(5000);
        ntpClient.setPoolName("pool.ntp.org");
        return ntpClient;
    }
    
    @Scheduled(fixedRate = 60000)  // Каждую минуту
    public void syncTime() {
        try {
            TimeInfo timeInfo = ntpClient.getTime();
            long serverTime = timeInfo.getMessage().getTransmitTimeStamp().getTime();
            // Коррекция логических часов приложения
        } catch (IOException e) {
            // Fallback на системное время
        }
    }
}
```

## **Итог**

**NTP** — критически важный протокол для:
- ✅ **Синхронизации** времени между системами
- ✅ **Аудита и логирования** с точными временными метками
- ✅ **Финансовых операций** с временными штампами
- ✅ **Распределенных систем** с согласованным временем

**Лучшие практики:**
1. Используйте **несколько источников** времени
2. Настройте **локальный NTP сервер** в корпоративной сети
3. Регулярно **мониторьте** точность синхронизации
4. Используйте **аутентификацию** для важных систем
5. Для высокой точности рассмотрите **PTP** или локальные GPS