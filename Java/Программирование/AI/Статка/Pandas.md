# Загрузка из различных форматов
df = pd.read_csv('data.csv')
df = pd.read_excel('data.xlsx')
df = pd.read_json('data.json')

---

## 📌 `df.info()`

Выводит **общее описание DataFrame**:

- количество строк и столбцов;
    
- названия колонок;
    
- количество **ненулевых (not-null)** значений;
    
- типы данных (`int64`, `float64`, `object`, `datetime64` и т. д.);
    
- сколько памяти занимает DataFrame.
    

Пример:

```
<class 'pandas.core.frame.DataFrame'>
RangeIndex: 100 entries, 0 to 99
Data columns (total 4 columns):
 #   Column  Non-Null Count  Dtype  
---  ------  --------------  -----  
 0   A       100 non-null    int64  
 1   B       100 non-null    float64
 2   C       100 non-null    object 
 3   D       95 non-null     float64
dtypes: float64(2), int64(1), object(1)
memory usage: 3.2 KB
```

👉 Это удобно для первичной диагностики структуры и "пробелов" в данных.

---

## 📌 `df.describe()`

Делает **статистическое описание числовых колонок**:

- количество значений (`count`),
    
- среднее (`mean`),
    
- стандартное отклонение (`std`),
    
- минимум, максимум,
    
- квартили (`25%`, `50%` — медиана, `75%`).
    

Пример:

```
              A           B
count  100.0000  100.000000
mean     50.5000    0.120123
std      29.0115    0.980789
min       1.0000   -2.890123
25%      25.7500   -0.520456
50%      50.5000    0.081234
75%      75.2500    0.743321
max     100.0000    2.812345
```

👉 Быстрое представление о распределении данных.  
Если указать `df.describe(include="all")`, то выводятся и **категориальные/строковые столбцы**.

---

## 📌 `df.head()`

Показывает **первые 5 строк** DataFrame (по умолчанию).  
Можно задать число строк:

```python
df.head(10)   # первые 10 строк
```

Пример:

```
   A     B     C     D
0  1  0.25   foo   2.5
1  2 -1.13   bar   3.1
2  3  0.88   foo   4.2
3  4 -0.55   baz   1.0
4  5  0.00   foo   2.3
```


    

# Проверка размерности
print(f"Размер датасета: {df.shape}")
# Типы данных
print(df.dtypes)

print(df.isnull().sum())
print(df.isnull().sum() / len(df) * 100) # в процентах
# Методы обработки пропусков
df_cleaned = df.dropna() # удаление строк с пропусками
df['column'] = df['column'].fillna(df['column'].mean()) # заполнение средним
df['column'] = df['column'].fillna(method='forward')

print(f"Количество дубликатов: {df.duplicated().sum()}")
df_unique = df.drop_duplicates()

# Метод межквартильного размаха (IQR)
Q1 = df['column'].quantile(0.25)
Q3 = df['column'].quantile(0.75)

# Фильтрация выбросов
df_filtered = df[(df['column'] >= lower_bound) & (df['column'] <= upper_bound)]

# Преобразование строк в даты
df['date_column'] = pd.to_datetime(df['date_column'])

# Преобразование категориальных переменных
df['category'] = df['category'].astype('category')

# Кодирование категориальных переменных
Эта строка кода делает **one-hot encoding** (кодирование категориальных признаков) в pandas:

```python
df_encoded = pd.get_dummies(df, columns=['category_column'])
```

---

### 📌 Что происходит:

1. **`df`** — исходный DataFrame.
    
2. **`columns=['category_column']`** — указываем, какие колонки нужно закодировать.
    
3. **`pd.get_dummies`**:
    
    - Каждое уникальное значение категориального столбца превращается в отдельную колонку.
        
    - В новой колонке **1**, если строка имела это значение, и **0** — иначе.
        

---

### 🔹 Пример

Исходный DataFrame:

|id|category_column|
|---|---|
|1|A|
|2|B|
|3|A|
|4|C|

После `pd.get_dummies(df, columns=['category_column'])`:

|id|category_column_A|category_column_B|category_column_C|
|---|---|---|---|
|1|1|0|0|
|2|0|1|0|
|3|1|0|0|
|4|0|0|1|



🔥 Отличный набор статистических методов для анализа данных в **pandas**. Давай разберём каждый:

---

```python
median = df['column'].median()
```

- **Медиана**: значение, делящее отсортированный ряд пополам.
    
- Устойчивее к выбросам, чем среднее.
    

---

```python
mode = df['column'].mode()[0]
```

- **Мода**: наиболее часто встречающееся значение.
    
- `mode()` возвращает **Series** (может быть несколько мод), поэтому `[0]` берёт первую.
    

---

```python
variance = df['column'].var()
```

- **Дисперсия**: среднее квадратов отклонений от среднего.
    
- Показывает разброс данных.
    
- Единицы измерения — **квадрат исходных единиц** (например, см², если данные в см).
    

---

```python
std_dev = df['column'].std()
```

- **Стандартное отклонение**: квадратный корень из дисперсии.
    
- Более интерпретируемо, т.к. в тех же единицах, что и данные.
    

---

```python
skewness = df['column'].skew()
```

- **Асимметрия распределения**:
    
    - > 0 → распределение смещено вправо (длинный правый хвост),
        
    - < 0 → распределение смещено влево (длинный левый хвост),
        
    - ≈ 0 → симметрично (похоже на нормальное).
        

---

```python
kurtosis = df['column'].kurtosis()
```

- **Эксцесс (kurtosis)**: "островершинность" распределения.
    
    - > 0 → более "острое", чем нормальное, с тяжёлыми хвостами,
        
    - < 0 → более "плоское", с лёгкими хвостами,
        
    - 0 → нормальное распределение.
        



---



# Матрица корреляций
correlation_matrix = df.corr()
# Корреляция между двумя переменными
correlation = df['var1'].corr(df['var2'])


group_stats = df.groupby('category').agg({
'numeric_column': ['mean', 'std', 'count'],
'another_column': 'sum'
})



# Установка индекса времени
Эта строка делает следующее:

```python
df.set_index('date_column', inplace=True)
```

---

### 📌 Пояснение:

1. **`'date_column'`** — название колонки, которую мы хотим использовать **в качестве индекса**.
    
    - Индекс — это метки строк DataFrame, по которым можно быстро выбирать и фильтровать данные.
        
2. **`inplace=True`** — изменение выполняется **на месте**, т.е. **исходный DataFrame `df` обновляется**, и новый объект создавать не нужно.
    
    - Если `inplace=False` (по умолчанию), возвращается новый DataFrame с новым индексом, а исходный не меняется.
        

---

### 🔹 Пример

Исходный DataFrame:

|date_column|A|B|
|---|---|---|
|2023-01-01|1|4|
|2023-01-02|2|5|
|2023-01-03|3|6|

После `df.set_index('date_column', inplace=True)`:

| A | B |  
|-------------|---|---|  
| 2023-01-01 | 1 | 4 |  
| 2023-01-02 | 2 | 5 |  
| 2023-01-03 | 3 | 6 |

- Колонка `'date_column'` теперь **индекс**.
    
- Можно обращаться к строкам по дате:
    

```python
df.loc['2023-01-02']
# Вывод: A    2
#        B    5
```

---

# Ресемплинг
Эта строка кода используется для **агрегации временного ряда по месяцам**:

```python
monthly_data = df.resample('M').mean()
```

---

### 📌 Пояснение:

1. **`df`** — DataFrame с **индексом типа `DatetimeIndex`** (например, после `df.set_index('date_column')`).
    
2. **`resample('M')`** — группирует данные по **месячным интервалам**:
    
    - `'M'` = конец месяца,
        
    - Можно использовать `'D'` (день), `'W'` (неделя), `'Q'` (квартал), `'Y'` (год) и др.
        
3. **`.mean()`** — берёт **среднее значение по каждой колонке** в каждом месяце.
    

---

### 🔹 Пример

Исходный DataFrame (с индексом дат):

|date|A|
|---|---|
|2023-01-01|1|
|2023-01-10|2|
|2023-01-20|3|
|2023-02-05|4|
|2023-02-15|5|

После `df.resample('M').mean()`:

|date|A|
|---|---|
|2023-01-31|2.0|
|2023-02-28|4.5|

---


# Скользящие средние
Эта строка кода используется для вычисления **скользящего среднего (rolling mean)** в pandas:

```python
df['rolling_mean'] = df['value'].rolling(window=7).mean()
```

---

### 📌 Разбор:

1. **`df['value']`** — колонка с данными, по которым считаем скользящее среднее.
    
2. **`.rolling(window=7)`** — создаёт "окно" размером 7 строк (например, 7 дней, если индекс — даты).
    
3. **`.mean()`** — вычисляет среднее **по каждому окну**.
    

- Для первой строки, где нет 7 предыдущих значений, результат будет `NaN`.
    
- Далее каждое значение — среднее последних 7 строк.
    

---

### 🔹 Пример

Исходные данные (`value`):

|date|value|
|---|---|
|2023-01-01|1|
|2023-01-02|2|
|2023-01-03|3|
|2023-01-04|4|
|2023-01-05|5|
|2023-01-06|6|
|2023-01-07|7|
|2023-01-08|8|

Скользящее среднее с окном 7 (`rolling_mean`):

|date|value|rolling_mean|
|---|---|---|
|2023-01-01|1|NaN|
|2023-01-02|2|NaN|
|2023-01-03|3|NaN|
|2023-01-04|4|NaN|
|2023-01-05|5|NaN|
|2023-01-06|6|NaN|
|2023-01-07|7|4.0|
|2023-01-08|8|5.0|

---




# Абсолютные частоты
Этот код создаёт **таблицу частот** для категориальной колонки в DataFrame:

```python
freq_table = df['category'].value_counts()
print("Таблица абсолютных частот:")
print(freq_table)
```

---

### 📌 Разбор:

1. **`df['category']`** — колонка, для которой считаем частоты.
    
2. **`.value_counts()`** — возвращает **Series**, где:
    
    - индекс = уникальные значения колонки,
        
    - значения = количество встреч каждого уникального значения (**абсолютная частота**).
        
3. `print(freq_table)` — выводим таблицу.
    

---

### 🔹 Пример

Исходные данные:

|category|
|---|
|A|
|B|
|A|
|C|
|A|
|B|

Результат `value_counts()`:

```
A    3
B    2
C    1
Name: category, dtype: int64
```

- `A` встречается 3 раза,
    
- `B` — 2 раза,
    
- `C` — 1 раз.
    

---



# Относительные частоты
rel_freq = df['category'].value_counts(normalize=True)
print("\nТаблица относительных частот:")
print(rel_freq)
# Сводная таблица
summary_table = pd.DataFrame({
'Частота': freq_table,
'Процент': rel_freq * 100
})
print(summary_table)


МАТРИЦА КОРРЕЛЯЦИЙ
corr_matrix = df.select_dtypes(include=[np.number]).corr()


numeric_cols = df.select_dtypes(include=[np.number]).columns



# Создание таблицы сопряженности
contingency_table = pd.crosstab(df['category1'], df['category2'])
print("Таблица сопряженности:")
print(contingency_table)
# Таблица с процентами
contingency_percent = pd.crosstab(df['category1'], df['category2'],
normalize='index') * 100
print("\nТаблица сопряженности (%):")
print(contingency_percent.round(1))


[`DataFrame.to_numpy()`](https://pandas.pydata.org/docs/reference/api/pandas.DataFrame.to_numpy.html#pandas.DataFrame.to_numpy "pandas.DataFrame.to_numpy")




`df.sort_values(by="Age", ascending=False, inplace=True)  # Sort by Age in descending order`
df.sort_values(by=["Age", "Glucose"], ascending=[False, True], inplace=True)
df.reset_index(drop=True, inplace=True)  # Resets index and removes old index column



[`DataFrame.at()`](https://pandas.pydata.org/docs/reference/api/pandas.DataFrame.at.html#pandas.DataFrame.at "pandas.DataFrame.at"), [`DataFrame.iat()`](https://pandas.pydata.org/docs/reference/api/pandas.DataFrame.iat.html#pandas.DataFrame.iat "pandas.DataFrame.iat"), [`DataFrame.loc()`](https://pandas.pydata.org/docs/reference/api/pandas.DataFrame.loc.html#pandas.DataFrame.loc "pandas.DataFrame.loc") and [`DataFrame.iloc()`](https://pandas.pydata.org/docs/reference/api/pandas.DataFrame.iloc.html#pandas.DataFrame.iloc "pandas.DataFrame.iloc").


For a [`DataFrame`](https://pandas.pydata.org/docs/reference/api/pandas.DataFrame.html#pandas.DataFrame "pandas.DataFrame"), passing a slice `:` selects matching rows: df[0:3]

df.loc[df['BloodPressure'] > 100, ['Pregnancies', 'Glucose', 'BloodPressure']]
df.loc[:, ["A", "B"]]
Out[28]: 
                   A         B
2013-01-01  0.469112 -0.282863
2013-01-02  1.212112 -0.173215
2013-01-03 -0.861849 -2.104569
2013-01-04  0.721555 -0.706771
2013-01-05 -0.424972  0.567020
2013-01-06 -0.673690  0.113648



df.loc["20130102":"20130104", ["A", "B"]]
Out[29]: 
                   A         B
2013-01-02  1.212112 -0.173215
2013-01-03 -0.861849 -2.104569
2013-01-04  0.721555 -0.706771


df.iloc[3:5, 0:2]
Out[33]: 
                   A         B
2013-01-04  0.721555 -0.706771
2013-01-05 -0.424972  0.567020

For getting fast access to a scalar (equivalent to the prior method):

In [38]:
df.iat[1, 1]
Out[38]: -0.17321464905330858

In [39]: df[df["A"] > 0]
Out[39]: 
                   A         B         C         D
2013-01-01  0.469112 -0.282863 -1.509059 -1.135632
2013-01-02  1.212112 -0.173215  0.119209 -1.044236
2013-01-04  0.721555 -0.706771 -1.039575  0.271860


In [41]: df2 = df.copy()

In [42]: df2["E"] = ["one", "one", "two", "three", "four", "three"]

In [43]: df2
Out[43]: 
            A                    B                   C                D              E
2013-01-01  0.469112 -0.282863 -1.509059 -1.135632    one
2013-01-02  1.212112 -0.173215  0.119209 -1.044236    one
2013-01-03 -0.861849 -2.104569 -0.494929  1.071804    two
2013-01-04  0.721555 -0.706771 -1.039575  0.271860  three
2013-01-05 -0.424972  0.567020  0.276232 -1.087401   four
2013-01-06 -0.673690  0.113648 -1.478427  0.524988  three




In [44]: df2[df2["E"].isin(["two", "four"])]
Out[44]: 
                   A         B         C         D     E
2013-01-03 -0.861849 -2.104569 -0.494929  1.071804   two
2013-01-05 -0.424972  0.567020  0.276232 -1.087401  four


### Setting[](https://pandas.pydata.org/docs/user_guide/10min.html#setting "Link to this heading")

Setting a new column automatically aligns the data by the indexes:

In [45]: s1 = pd.Series([1, 2, 3, 4, 5, 6], index=pd.date_range("20130102", periods=6))

In [46]: s1
Out[46]: 
2013-01-02    1
2013-01-03    2
2013-01-04    3
2013-01-05    4
2013-01-06    5
2013-01-07    6
Freq: D, dtype: int64

In [47]: df["F"] = s1


Разберём пошагово, что делает этот код:

---

```python
df1 = df.reindex(index=dates[0:4], columns=list(df.columns) + ["E"])
```

- Берётся DataFrame `df`, но создаётся его "перестроенная" версия:
    
    - Индекс ограничен только первыми 4 датами из `dates` (`dates[0:4]`);
        
    - К существующим колонкам добавляется новая колонка `"E"`, которая пока заполнена `NaN`.
        

---

```python
df1.loc[dates[0] : dates[1], "E"] = 1
```

- В колонке `"E"` для строк с индексами от `dates[0]` до `dates[1]` (т.е. первые две даты включительно) записывается значение `1`.
    

---

```python
df1
```

Вывод показывает обновлённый DataFrame:

```
                   A         B         C    D    F    E
2013-01-01  0.000000  0.000000 -1.509059  5.0  NaN  1.0
2013-01-02  1.212112 -0.173215  0.119209  5.0  1.0  1.0
2013-01-03 -0.861849 -2.104569 -0.494929  5.0  2.0  NaN
2013-01-04  0.721555 -0.706771 -1.039575  5.0  3.0  NaN
```

---

### Что произошло:

1. Из исходного `df` взяли первые 4 строки по датам.
    
2. Добавили новую колонку **E**.
    
3. Для первых двух дат (`2013-01-01`, `2013-01-02`) колонка **E** заполнилась `1`.
    
4. Для остальных остались `NaN`.
    

---




[`isna()`](https://pandas.pydata.org/docs/reference/api/pandas.isna.html#pandas.isna "pandas.isna") gets the boolean mask where values are `nan`:

In [60]: pd.isna(df1)
Out[60]: 
                A      B      C      D      F      E
2013-01-01  False  False  False  False   True  False
2013-01-02  False  False  False  False  False  False
2013-01-03  False  False  False  False  False   True
2013-01-04  False  False  False  False  False   True


[`DataFrame.agg()`](https://pandas.pydata.org/docs/reference/api/pandas.DataFrame.agg.html#pandas.DataFrame.agg "pandas.DataFrame.agg") and [`DataFrame.transform()`](https://pandas.pydata.org/docs/reference/api/pandas.DataFrame.transform.html#pandas.DataFrame.transform "pandas.DataFrame.transform") applies a user defined function that reduces or broadcasts its result respectively.

In [66]: df.agg(lambda x: np.mean(x) * 5.6)
Out[66]: 
A    -0.025054
B    -2.150294
C    -3.851445
D    28.000000
F    16.800000
dtype: float64

In [67]: df.transform(lambda x: x * 101.2)
Out[67]: 
                     A           B           C      D      F
2013-01-01    0.000000    0.000000 -152.716721  506.0    NaN
2013-01-02  122.665737  -17.529322   12.063922  506.0  101.2
2013-01-03  -87.219115 -212.982405  -50.086843  506.0  202.4
2013-01-04   73.021382  -71.525239 -105.204988  506.0  303.6
2013-01-05  -43.007200   57.382459   27.954680  506.0  404.8
2013-01-06  -68.177398   11.501219 -149.616767  506.0  506.0





pd.merge(left, right, on="key")
Out[81]: 
   key  lval  rval
0  foo     1     4
1  foo     1     5
2  foo     2     4
3  foo     2     5


Отличный пример группировки в **pandas** 👇

---

### 📌 Первая команда:

```python
df.groupby("A")[["C", "D"]].sum()
```

- Группируем строки по значению в колонке **"A"**;
    
- Для каждой группы берём только столбцы **"C"** и **"D"**;
    
- Считаем сумму.
    

👉 Результат: агрегированные суммы по колонкам `C` и `D` для каждой уникальной категории из `A` (`bar`, `foo`).

---

### 📌 Вторая команда:

```python
df.groupby(["A", "B"]).sum()
```

- Теперь группировка идёт сразу по двум колонкам: **"A"** и **"B"**;
    
- Для каждой уникальной комбинации значений (например, `("bar", "one")`, `("foo", "two")`) считаем суммы по всем числовым столбцам.
    

👉 На выходе **многомерный индекс (MultiIndex)**, где:

- Первый уровень — значения из `A` (`bar`, `foo`),
    
- Второй уровень — значения из `B` (`one`, `two`, `three`).
    

---


    





Отличный пример с **иерархическим индексом (MultiIndex)** 👇

---

### 📌 Что делает код:

```python
arrays = [
   ["bar", "bar", "baz", "baz", "foo", "foo", "qux", "qux"],
   ["one", "two", "one", "two", "one", "two", "one", "two"],
]
```

- Создаём два списка, которые будут уровнями индекса.
    
- Первый уровень (`first`): категории `"bar"`, `"baz"`, `"foo"`, `"qux"`.
    
- Второй уровень (`second`): `"one"`, `"two"` для каждой категории.
    

---

```python
index = pd.MultiIndex.from_arrays(arrays, names=["first", "second"])
```

- Формируем **MultiIndex** из двух уровней.
    
- Даем названия уровням индекса: `"first"` и `"second"`.
    

---

```python
df = pd.DataFrame(np.random.randn(8, 2), index=index, columns=["A", "B"])
```

- Создаём DataFrame размером `8×2`.
    
- Индекс — двухуровневый `MultiIndex`.
    
- Колонки называются `"A"` и `"B"`.
    
- Значения — случайные числа (из нормального распределения).
    

---

```python
df2 = df[:4]
```

- Берём первые 4 строки DataFrame.
    

---

```python
df2
```

Вывод:

```
                     A         B
first second                    
bar   one    -0.727965 -0.589346
      two     0.339969 -0.693205
baz   one    -0.339355  0.593616
      two     0.884345  1.591431
```

---


    

---

Хочешь, я покажу, как работать с таким индексом? Например:

- выбор по одному уровню (`df2.loc["bar"]`),
    
- или выбор по обоим уровням (`df2.loc[("baz", "two")]`),
    
- или даже свёртку (`df2.groupby("first").mean()`).




df = pd.DataFrame(
   .....:    {
   .....:        "A": ["one", "one", "two", "three"] * 3,
   .....:        "B": ["A", "B", "C"] * 4,
   .....:        "C": ["foo", "foo", "foo", "bar", "bar", "bar"] * 2,
   .....:        "D": np.random.randn(12),
   .....:        "E": np.random.randn(12),
   .....:    }
   .....: )
   .....: 

In [102]: df
Out[102]: 
        A  B    C         D         E
0     one  A  foo -1.202872  0.047609
1     one  B  foo -1.814470 -0.136473
2     two  C  foo  1.018601 -0.561757
3   three  A  bar -0.595447 -1.623033
4     one  B  bar  1.395433  0.029399
5     one  C  bar -0.392670 -0.542108
6     two  A  foo  0.007207  0.282696
7   three  B  foo  1.928123 -0.087302
8     one  C  foo -0.055224 -1.575170
9     one  A  bar  2.395985  1.771208
10    two  B  bar  1.552825  0.816482
11  three  C  bar  0.166599  1.100230
### Pivot tables 

pandas also enables you to calculate summary statistics as pivot tables. This makes it easy to draw conclusions based on a combination of variables. The below code picks the rows as unique values of `Pregnancies`, the column values are the unique values of `Outcome`, and the cells contain the average value of `BMI` in the corresponding group.

For example, for `Pregnancies = 5` and `Outcome = 0`, the average BMI turns out to be 31.1.

`pd.pivot_table(df, values="BMI", index='Pregnancies',                 columns=['Outcome'], aggfunc=np.mean)`
[`pivot_table()`](https://pandas.pydata.org/docs/reference/api/pandas.pivot_table.html#pandas.pivot_table "pandas.pivot_table") pivots a [`DataFrame`](https://pandas.pydata.org/docs/reference/api/pandas.DataFrame.html#pandas.DataFrame "pandas.DataFrame") specifying the `values`, `index` and `columns`

In [103]: pd.pivot_table(df, values="D", index=["A", "B"], columns=["C"])
Out[103]: 
C             bar       foo
A     B                    
one   A  2.395985 -1.202872
      B  1.395433 -1.814470
      C -0.392670 -0.055224
three A -0.595447       NaN
      B       NaN  1.928123
      C  0.166599       NaN
two   A       NaN  0.007207
      B  1.552825       NaN
      C       NaN  1.018601


Этот код — пример работы с временными рядами в **pandas**. Давай разберём его по шагам:

```python
rng = pd.date_range("1/1/2012", periods=100, freq="s")
```

- Создаёт временной индекс `rng` из **100 последовательных меток времени**, начиная с `2012-01-01 00:00:00`,
    
- `freq="s"` → шаг **1 секунда**.  
    То есть получится диапазон от `2012-01-01 00:00:00` до `2012-01-01 00:01:39`.
    

---

```python
ts = pd.Series(np.random.randint(0, 500, len(rng)), index=rng)
```

- Создаётся объект **Series**, где индекс — это даты/время (`rng`),
    
- значения — случайные числа от `0` до `499`.  
    Таким образом, мы получили **временной ряд** с данными каждую секунду.
    

---

```python
ts.resample("5Min").sum()
```

- `resample("5Min")` → группировка временного ряда по **5-минутным интервалам**.
    
- `.sum()` → берётся **сумма значений внутри каждого интервала**.
    

---

⚡ В результате:

- Все данные из диапазона времени (около 1 минуты 40 секунд) попадают в **один 5-минутный интервал** (`2012-01-01 00:00:00` → `2012-01-01 00:04:59`).
    
- Поэтому на выходе — всего **одно значение**: сумма всех 100 случайных чисел.
    

Пример вывода:

```
2012-01-01    24182
Freq: 5min, dtype: int64
```

---



In [116]: df["grade"] = df["raw_grade"].astype("category")

In [117]: df["grade"]
Out[117]: 
0    a
1    b
2    b
3    a
4    a
5    e
Name: grade, dtype: category
Categories (3, object): ['a', 'b', 'e']



RENAMING
In [118]: new_categories = ["very good", "good", "very bad"]

In [119]: df["grade"] = df["grade"].cat.rename_categories(new_categories)




In [120]: df["grade"] = df["grade"].cat.set_categories(
   .....:     ["very bad", "bad", "medium", "good", "very good"]
   .....: )
   .....: 

In [121]: df["grade"]
Out[121]: 
0    very good
1         good
2         good
3    very good
4    very good
5     very bad
Name: grade, dtype: category
Categories (5, object): ['very bad', 'bad', 'medium', 'good', 'very good']



df.to_csv("foo.csv")


Эта строка

```python
df.to_parquet("foo.parquet")
```

делает следующее:

- Берёт объект **DataFrame** `df`;
    
- Сохраняет его в файл **`foo.parquet`** в формате **Parquet**.
    

### Что такое Parquet?

- Это бинарный колоночный формат хранения данных (разработан Apache);
    
- Оптимизирован для быстрого чтения и эффективного сжатия;
    
- Удобен для больших данных и интегрируется с системами типа Spark, Hadoop, Dask и др.;
    
- В отличие от CSV, хранит типы данных (int, float, datetime и т. д.).
    





df.to_excel("foo.xlsx", sheet_name="Sheet1")

Reading from an excel file using [`read_excel()`](https://pandas.pydata.org/docs/reference/api/pandas.read_excel.html#pandas.read_excel "pandas.read_excel"):

In [140]: pd.read_excel("foo.xlsx", "Sheet1", index_col=None, na_values=["NA"])
Out[140]: 
   Unnamed: 0  0  1  2  3  4
0           0  4  3  1  1  2
1           1  1  0  2  3  2
2           2  1  4  2  1  2
3           3  0  4  0  2  2
4           4  4  2  2  3  4
5           5  4  0  4  3  1
6           6  2  1  2  0  3
7           7  4  0  4  4  4
8           8  4  4  1  0  1
9           9  0  4  3  0  3




Хороший вопрос 👍 В **pandas** DataFrame можно создать множеством способов.  
Я собрал основные группы приёмов с примерами:

---

## 1. 📋 Из словаря Python

### а) Списки или массивы одинаковой длины

```python
import pandas as pd

data = {"A": [1, 2, 3], "B": [4, 5, 6]}
df = pd.DataFrame(data)
```

### б) Словарь словарей (ключи → индексы)

```python
data = {"A": {0: 1, 1: 2}, "B": {0: 3, 1: 4}}
df = pd.DataFrame(data)
```

---

## 2. 📊 Из списка списков или кортежей

```python
data = [[1, 2], [3, 4], [5, 6]]
df = pd.DataFrame(data, columns=["A", "B"])
```

---

## 3. 📑 Из списка словарей

```python
data = [{"A": 1, "B": 2}, {"A": 3, "B": 4}]
df = pd.DataFrame(data)
```

---

## 4. 🧮 Из NumPy массива

```python
import numpy as np
df = pd.DataFrame(np.random.randn(4, 3), columns=["A", "B", "C"])
```

---

## 5. 📆 Из pandas Series

```python
s1 = pd.Series([1, 2, 3], name="A")
s2 = pd.Series([4, 5, 6], name="B")
df = pd.DataFrame({s1.name: s1, s2.name: s2})
```

---

## 6. 📌 Из pandas Index / MultiIndex

```python
index = pd.MultiIndex.from_product([["bar", "baz"], ["one", "two"]], names=["first", "second"])
df = pd.DataFrame(np.random.randn(4, 2), index=index, columns=["A", "B"])
```

---

## 7. 🗄️ Из внешних источников

- CSV:
    
    ```python
    df = pd.read_csv("file.csv")
    ```
    
- Excel:
    
    ```python
    df = pd.read_excel("file.xlsx")
    ```
    
- SQL:
    
    ```python
    import sqlite3
    conn = sqlite3.connect("mydb.db")
    df = pd.read_sql("SELECT * FROM mytable", conn)
    ```
    
- JSON:
    
    ```python
    df = pd.read_json("file.json")
    ```
    
- Parquet / Feather / HDF5 и другие форматы.
    

---

## 8. 🏗️ С помощью встроенных конструкторов pandas

- Пустой:
    
    ```python
    df = pd.DataFrame()
    ```
    
- Из `pd.date_range` (часто используют для индекса):
    
    ```python
    dates = pd.date_range("20230101", periods=6)
    df = pd.DataFrame(np.random.randn(6, 4), index=dates, columns=list("ABCD"))
    ```
    

---


### Get all columns and column names

Calling the `.columns` attribute of a DataFrame object returns the column names in the form of an `Index` object. As a reminder, a pandas index is the address/label of the row or column.
list(df.columns)


The `axis` argument lets you specify whether you are dropping rows, or [columns](https://www.datacamp.com/tutorial/pandas-drop-column), with missing values. The default `axis` removes the rows containing NaNs. Use `axis = 1` to remove the columns with one or more NaN values. Also, notice how we are using the argument `inplace=True` which lets you skip saving the output of `.dropna()` into a new DataFrame.  

`df3 = df2.copy() df3.dropna(inplace=True, axis=1) df3.head()`


You can also drop both rows and columns with missing values by setting the `how` argument to `'all'`

`df3 = df2.copy() df3.dropna(inplace=True, how='all')`

### Renaming columns
df3.rename(columns = {'DiabetesPedigreeFunction':'DPF'}, inplace = True)
df3.head()





Да 👍 ты тут считаешь **квартили** для столбца в DataFrame:

```python
Q1 = df[column_name].quantile(0.25)  # первый квартиль (25-й перцентиль)
Q3 = df[column_name].quantile(0.75)  # третий квартиль (75-й перцентиль)
```

---

### 📌 Что это значит:

- **Q1 (25%)** → значение, ниже которого лежит 25% данных.
    
- **Q3 (75%)** → значение, ниже которого лежит 75% данных.
    
- Вместе они ограничивают "серединные" 50% распределения (так называемый **межквартильный размах**, IQR).
    

---

### 📊 Межквартильный размах (IQR):

```python
IQR = Q3 - Q1
```

Используется, например, для поиска выбросов:

```python
lower_bound = Q1 - 1.5 * IQR
upper_bound = Q3 + 1.5 * IQR
outliers = df[(df[column_name] < lower_bound) | (df[column_name] > upper_bound)]
```

---

