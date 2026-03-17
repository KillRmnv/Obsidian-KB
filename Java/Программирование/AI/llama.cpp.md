##  Основные флаги llama.cpp (llama-cli / llama-server)

## **Обязательные (всегда)**

text

`-m PATH        путь к .gguf модели`

## **Скорость + производительность**

text

`-t N           CPU потоки (6 для Ryzen 5500U) 
-c N           размер контекста (2048-8192) 
--mlock        заблокировать в RAM (быстрее) 
--no-mmap      полностью в RAM (без дискового кэша)`

## **Генерация текста**

text

`-p TEXT        промпт для CLI 
-n N           макс. токенов ответа (128, 512, 0=бесконечно) 
--temp 0.7     температура (0.1-1.0) 
--top-p 0.9    nucleus sampling`

## **Сервер (WebUI + API)**

text

`--host 0.0.0.0 --port 8080   открыть для всех (localhost:8080) --jinja         шаблоны промптов`

## 💨 Твои оптимальные команды

**CLI чат (30 t/s):**

text

`./llama-cli -m LFM2-8B-Q4_K_M.gguf -t 6 -c 4096`

**Сервер WebUI + агент (рекомендую):**

text

`./llama-server -m LFM2-8B-Q4_K_M.gguf -t 6 -c 8192 --host 0.0.0.0 --port 8080`

**Максимальная скорость:**

text

`./llama-server -m LFM2-8B-Q4_K_M.gguf -t 4 -c 2048 --mlock --no-mmap --host 0.0.0.0 --port 8080`

## 📊 Таблица по ситуациям

|Сценарий|Команда|
|---|---|
|**Тест скорости**|`-t 6 -c 2048 -n 128`|
|**Длинные ответы**|`-c 8192` (без `-n`)|
|**mini-swe-agent**|`-c 8192 -t 6 --host 0.0.0.0`|
|**Минимум RAM**|`--no-mmap -c 2048`|

**WebUI: [http://localhost:8080](http://localhost:8080)**  
**API: [http://localhost:8080/v1](http://localhost:8080/v1)**  


## Готовые команды

``` bash
llamacpp-cli -m ~/.lmstudio/models/LiquidAI/LFM2-8B-A1B-GGUF/LFM2-8B-A1B-Q4_K_M.gguf -t 6 --no-mmap --temp 0.5
```

```bash
llamacpp-server -m ~/.lmstudio/models/LiquidAI/LFM2-8B-A1B-GGUF/LFM2-8B-A1B-Q4_K_M.gguf -t 6 --no-mmap --temp 0.5 --host 0.0.0.0 --port 8080  --jinja
```