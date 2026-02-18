`List<? extends Object>` ведёт себя как «список чего‑то, но точно не знаю чего», с единственным ограничением: все элементы — какие‑то подтипы `Object`. По факту это то же самое, что `List<?>`.habr+1​

## Что можно получить

java

`List<? extends Object> list = ...; Object o = list.get(0);   // это можно`

- Можно **читать элементы**, но тип возвращаемого значения — ровно `Object`.
    
- Нельзя безопасно считать, что там лежит `String`, `Number` и т.п. — только `Object` (и дальше самим кастовать при необходимости).[habr](https://habr.com/ru/companies/sberbank/articles/416413/)​
    

## Что можно положить

java

`list.add(new Object());   // НЕЛЬЗЯ 
list.add("str");          // НЕЛЬЗЯ 
list.add(null);           // МОЖНО`

- В `List<? extends X>` **нельзя добавлять ничего, кроме `null`**.
    
- Причина: реальный параметр типа может быть, например, `List<String>` или `List<Integer>`, и компилятор этого не знает. Если бы он позволил добавить `Object`, вы могли бы положить `Integer` в список, который на самом деле `List<String>`, и сломать типобезопасность.[habr](https://habr.com/ru/companies/sberbank/articles/416413/)​
    

PECS‑правило:

- `? extends T` — **Producer**: из него только **читать** (`get`), но **не писать** (`add`), исключая `null`.
    
- `? super T` — **Consumer**: в него **писать T**, а читаешь как `Object`.
    

Итого:

- У `List<? extends Object>`:
    
    - **читать** можно: да, тип `Object`.
        
    - **писать** нельзя: только `null`.
        
- В большинстве случаев удобнее писать просто `List<?>`, так как `?` и `? extends Object` практически эквивалентны по поведению.[stackoverflow](https://ru.stackoverflow.com/questions/722565/%D0%9A%D0%B0%D0%BA%D0%B0%D1%8F-%D1%80%D0%B0%D0%B7%D0%BD%D0%B8%D1%86%D0%B0-%D0%BC%D0%B5%D0%B6%D0%B4%D1%83-%D0%B8-extends-object)​
    
