# Kotlin Interview Questions — Полный Сборник
## Специфичные вопросы для Kotlin разработчиков (300+ вопросов)

**Составлено:** Январь 2026  
**Версия:** 1.0  
**Всего вопросов:** 300+

---

## СОДЕРЖАНИЕ

1. [Kotlin Basics & Language Features](#kotlin-basics--language-features)
2. [Null Safety](#null-safety)
3. [Data Classes, Sealed Classes, Object](#data-classes-sealed-classes-object)
4. [Extension Functions & Higher-Order Functions](#extension-functions--higher-order-functions)
5. [Kotlin Coroutines](#kotlin-coroutines)
6. [Kotlin Flow & Channels](#kotlin-flow--channels)
7. [Kotlin Collections & Sequences](#kotlin-collections--sequences)
8. [Kotlin + Spring Boot](#kotlin--spring-boot)
9. [Kotlin + Hibernate/JPA](#kotlin--hibernatejpa)
10. [Kotlin Multiplatform](#kotlin-multiplatform)
11. [Kotlin DSL](#kotlin-dsl)
12. [Advanced Kotlin Topics](#advanced-kotlin-topics)
13. [Kotlin vs Java](#kotlin-vs-java)
14. [Практические задачи (Coding)](#практические-задачи-coding)

---

## KOTLIN BASICS & LANGUAGE FEATURES

### Основы языка (50 вопросов)

1. Что такое Kotlin и какие его основные преимущества перед Java?
2. В чем разница между `val` и `var`?
3. Может ли `val` быть mutable?
4. Что такое type inference в Kotlin?
5. Как работает String templates в Kotlin?
6. Что такое raw strings (triple-quoted strings)?
7. Что такое String interpolation?
8. Как выполнить multi-line строку в Kotlin?
9. Что такое expression vs statement в Kotlin?
10. Почему `if` является expression в Kotlin?
11. Что такое `when` expression?
12. Чем `when` отличается от `switch` в Java?
13. Можно ли использовать `when` без аргумента?
14. Что такое range в Kotlin?
15. Как создать range от 1 до 10?
16. Что такое progression в Kotlin?
17. Что делает оператор `..` (range)?
18. Что делает оператор `until`?
19. Что делает оператор `downTo`?
20. Что делает оператор `step`?
21. Что такое destructuring declaration?
22. Как работает destructuring в data classes?
23. Что такое component functions (componentN)?
24. Можно ли использовать destructuring с обычными классами?
25. Что такое type aliases?
26. Когда использовать type aliases?
27. Что такое visibility modifiers в Kotlin?
28. Чем отличается `internal` от других модификаторов?
29. Что такое `lateinit`?
30. Когда использовать `lateinit`?
31. Можно ли использовать `lateinit` с примитивами?
32. Что такое `lazy` initialization?
33. Как работает `by lazy`?
34. В чем разница между `lateinit` и `by lazy`?
35. Что такое `const val`?
36. В чем разница между `val` и `const val`?
37. Что такое backing field в Kotlin?
38. Что такое backing property?
39. Как работают custom getters/setters?
40. Что такое operator overloading?
41. Какие операторы можно перегрузить?
42. Что такое infix functions?
43. Когда использовать infix notation?
44. Что такое tailrec functions?
45. Как работает tail recursion optimization?
46. Что такое `Nothing` type?
47. Когда используется `Nothing`?
48. Что такое `Unit` type?
49. Чем `Unit` отличается от `void` в Java?
50. Что такое smart casting?

---

## NULL SAFETY

### Null Safety & Nullable Types (40 вопросов)

51. Что такое null safety в Kotlin?
52. Как объявить nullable переменную?
53. Что означает `?` после типа?
54. Что такое safe call operator `?.`?
55. Приведите пример использования safe call.
56. Что такое Elvis operator `?:`?
57. Приведите пример использования Elvis operator.
58. Что такое not-null assertion operator `!!`?
59. Когда нужно использовать `!!`?
60. Почему использование `!!` считается code smell?
61. Что такое safe cast operator `as?`?
62. В чем разница между `as` и `as?`?
63. Что такое platform types?
64. Почему platform types опасны?
65. Как аннотировать Java код для Kotlin null safety?
66. Что такое `@Nullable` и `@NotNull` аннотации?
67. Как работает `let` с nullable типами?
68. Что такое `?.let { }`?
69. Как использовать `?.let` для null проверок?
70. Что делает `takeIf`?
71. Что делает `takeUnless`?
72. Как работает `requireNotNull()`?
73. Как работает `checkNotNull()`?
74. В чем разница между `requireNotNull()` и `checkNotNull()`?
75. Что такое nullable receiver?
76. Можно ли создать extension function с nullable receiver?
77. Что такое contracts в Kotlin?
78. Как contracts помогают с null safety?
79. Что делает `@NotNull` в Java interop?
80. Как обрабатывать nullable collections?
81. Что такое `filterNotNull()`?
82. Как инициализировать nullable lateinit var?
83. Можно ли проверить, инициализирована ли `lateinit` переменная?
84. Что такое `::property.isInitialized`?
85. Как работает `?.run {}`?
86. Как работает `?.also {}`?
87. Как работает `?.apply {}`?
88. Чем отличаются `let`, `run`, `with`, `apply`, `also`?
89. Когда использовать каждую scope function?
90. Приведите примеры использования scope functions с nullable.

---

## DATA CLASSES, SEALED CLASSES, OBJECT

### Специальные типы классов (50 вопросов)

91. Что такое data class?
92. Какие методы автоматически генерируются для data class?
93. Какие требования для создания data class?
94. Можно ли создать data class без параметров?
95. Можно ли наследовать data class?
96. Что такое `copy()` метод в data class?
97. Как использовать `copy()` для создания modified копии?
98. Что такое component functions?
99. Как работает destructuring с data classes?
100. Можно ли добавить свои методы в data class?
101. Можно ли использовать data class с JPA?
102. Какие проблемы возникают с data class и Hibernate?
103. Что такое sealed class?
104. Когда использовать sealed class?
105. Какие ограничения у sealed class?
106. Можно ли создать subclass sealed class вне файла?
107. Как sealed class помогает с exhaustive `when`?
108. Что такое sealed interface?
109. В чем разница между sealed class и enum?
110. Когда использовать sealed class вместо enum?
111. Что такое `object` keyword?
112. Как создать singleton в Kotlin?
113. Что такое companion object?
114. Зачем нужен companion object?
115. Как объявить companion object?
116. Можно ли создать несколько companion objects?
117. Можно ли наследовать companion object?
118. Как вызвать метод companion object из Java?
119. Что такое `@JvmStatic` аннотация?
120. Зачем нужна `@JvmStatic`?
121. Что такое object expression?
122. Как создать anonymous object?
123. В чем разница между object declaration и object expression?
124. Можно ли создать anonymous inner class в Kotlin?
125. Что такое enum class в Kotlin?
126. Как добавить свойства и методы в enum?
127. Можно ли реализовать интерфейс в enum class?
128. Что такое inline class (value class)?
129. Когда использовать inline class?
130. Какие ограничения у inline class?
131. Что такое `@JvmInline` аннотация?
132. Как inline class помогает с performance?
133. Можно ли наследовать inline class?
134. Что такое type alias vs inline class?
135. Когда использовать type alias вместо inline class?
136. Что такое inner class в Kotlin?
137. Чем отличается inner class от nested class?
138. Как получить доступ к outer class из inner class?
139. Что такое `this@OuterClass`?
140. Можно ли создать static nested class в Kotlin?

---

## EXTENSION FUNCTIONS & HIGHER-ORDER FUNCTIONS

### Функциональное программирование (50 вопросов)

141. Что такое extension functions?
142. Как создать extension function?
143. Можно ли переопределить extension function?
144. Имеют ли extension functions доступ к private members?
145. Как работают extension functions под капотом?
146. Можно ли создать extension для nullable типа?
147. Что такое extension properties?
148. Можно ли создать extension property с backing field?
149. Что такое higher-order functions?
150. Приведите пример higher-order function.
151. Что такое lambda expression?
152. Как объявить lambda в Kotlin?
153. Что такое trailing lambda syntax?
154. Когда можно выносить lambda за скобки?
155. Что такое `it` в lambda?
156. Можно ли использовать несколько параметров в lambda?
157. Что такое function type?
158. Как объявить переменную типа function?
159. Что такое lambda with receiver?
160. Приведите пример lambda with receiver.
161. Что такое inline functions?
162. Зачем нужны inline functions?
163. Как inline functions влияют на performance?
164. Что такое `noinline` modifier?
165. Когда использовать `noinline`?
166. Что такое `crossinline` modifier?
167. Когда использовать `crossinline`?
168. Что такое reified type parameters?
169. Приведите пример использования `reified`.
170. Можно ли использовать `reified` без inline?
171. Что такое scope functions?
172. Сколько scope functions в Kotlin?
173. Что делает `let`?
174. Что делает `run`?
175. Что делает `with`?
176. Что делает `apply`?
177. Что делает `also`?
178. В чем разница между `let` и `run`?
179. В чем разница между `apply` и `also`?
180. Когда использовать `let` vs `run` vs `with`?
181. Что возвращает каждая scope function?
182. Что такое receiver в scope functions?
183. Что такое function reference?
184. Как создать reference на функцию?
185. Что такое bound reference?
186. Что такое unbound reference?
187. Что такое constructor reference?
188. Что такое member functions vs extension functions?
189. Можно ли создать extension на companion object?
190. Что такое SAM conversion?

---

## KOTLIN COROUTINES

### Асинхронность и Coroutines (80 вопросов)

191. Что такое coroutines?
192. Почему coroutines лучше, чем threads?
193. Что такое suspend function?
194. Как объявить suspend function?
195. Можно ли вызвать suspend function из обычной функции?
196. Что такое CoroutineScope?
197. Как создать CoroutineScope?
198. Что такое GlobalScope?
199. Почему не стоит использовать GlobalScope?
200. Что такое launch?
201. Что возвращает launch?
202. Что такое async?
203. Что возвращает async?
204. В чем разница между launch и async?
205. Когда использовать launch vs async?
206. Что такое Deferred?
207. Как получить результат из Deferred?
208. Что делает await()?
209. Что такое runBlocking?
210. Когда использовать runBlocking?
211. Почему runBlocking блокирует поток?
212. Что такое Job?
213. Как отменить Job?
214. Что делает job.cancel()?
215. Что делает job.join()?
216. Что такое cancelAndJoin()?
217. Как работает cancellation в coroutines?
218. Что такое CancellationException?
219. Нужно ли обрабатывать CancellationException?
220. Что такое isActive property?
221. Как проверить, отменена ли coroutine?
222. Что такое ensureActive()?
223. Что такое yield()?
224. Как сделать код cancellable?
225. Что такое NonCancellable context?
226. Когда использовать NonCancellable?
227. Что такое Dispatchers?
228. Какие Dispatchers есть в Kotlin?
229. Что такое Dispatchers.Default?
230. Что такое Dispatchers.IO?
231. Что такое Dispatchers.Main?
232. Что такое Dispatchers.Unconfined?
233. В чем разница между Default и IO?
234. Когда использовать каждый Dispatcher?
235. Что такое withContext?
236. Как переключиться на другой Dispatcher?
237. Что такое CoroutineContext?
238. Из чего состоит CoroutineContext?
239. Как объединить несколько CoroutineContext?
240. Что такое CoroutineContext.Element?
241. Что такое CoroutineName?
242. Как задать имя coroutine?
243. Что такое CoroutineExceptionHandler?
244. Как обрабатывать exceptions в coroutines?
245. В чем разница между exception handling в launch и async?
246. Что такое SupervisorJob?
247. В чем разница между Job и SupervisorJob?
248. Когда использовать SupervisorJob?
249. Что такое supervisorScope?
250. В чем разница между coroutineScope и supervisorScope?
251. Что такое structured concurrency?
252. Что такое parent-child relationship в coroutines?
253. Как работает cancellation propagation?
254. Что происходит при exception в child coroutine?
255. Что такое timeout?
256. Как использовать withTimeout?
257. Что такое withTimeoutOrNull?
258. В чем разница между withTimeout и withTimeoutOrNull?
259. Что такое delay()?
260. Чем delay() отличается от Thread.sleep()?
261. Что такое actor pattern в coroutines?
262. Что такое Channel?
263. Как использовать Channel для communication?
264. Что такое select expression?
265. Когда использовать select?
266. Что такое Mutex?
267. Как использовать Mutex для synchronization?
268. Что такое Semaphore в coroutines?
269. Как тестировать coroutines?
270. Что такое TestDispatcher?

---

## KOTLIN FLOW & CHANNELS

### Flow API (40 вопросов)

271. Что такое Flow?
272. В чем разница между Flow и Sequence?
273. Что такое cold flow?
274. Что такое hot flow?
275. Что такое StateFlow?
276. Что такое SharedFlow?
277. В чем разница между StateFlow и SharedFlow?
278. Когда использовать StateFlow?
279. Когда использовать SharedFlow?
280. Что такое MutableStateFlow?
281. Что такое MutableSharedFlow?
282. Как создать Flow?
283. Что делает flow { }?
284. Что делает flowOf()?
285. Что делает asFlow()?
286. Как собрать (collect) Flow?
287. Что делает collect()?
288. Что делает collectLatest()?
289. В чем разница между collect и collectLatest?
290. Что такое terminal operators в Flow?
291. Что такое intermediate operators в Flow?
292. Какие intermediate operators есть в Flow?
293. Что делает map в Flow?
294. Что делает filter в Flow?
295. Что делает transform?
296. Что делает flatMapConcat?
297. Что делает flatMapMerge?
298. Что делает flatMapLatest?
299. В чем разница между flatMapConcat, flatMapMerge, flatMapLatest?
300. Что делает zip operator?
301. Что делает combine operator?
302. В чем разница между zip и combine?
303. Что такое buffer в Flow?
304. Что такое conflate?
305. В чем разница между buffer и conflate?
306. Что такое backpressure в Flow?
307. Как Flow обрабатывает backpressure?
308. Что делает debounce?
309. Что делает sample (throttle)?
310. Что делает distinctUntilChanged?

---

## KOTLIN COLLECTIONS & SEQUENCES

### Collections API (30 вопросов)

311. В чем разница между List и MutableList?
312. В чем разница между Set и MutableSet?
313. В чем разница между Map и MutableMap?
314. Что такое immutable collections?
315. Как создать immutable list?
316. Что такое listOf vs mutableListOf?
317. Что такое Sequence?
318. В чем разница между Collection и Sequence?
319. Когда использовать Sequence вместо Collection?
320. Как работает lazy evaluation в Sequence?
321. Что делает asSequence()?
322. Что такое terminal operation в Sequence?
323. Что такое intermediate operation в Sequence?
324. Какие extension functions есть для collections?
325. Что делает filter?
326. Что делает map?
327. Что делает flatMap?
328. Что делает groupBy?
329. Что делает partition?
330. Что делает fold?
331. Что делает reduce?
332. В чем разница между fold и reduce?
333. Что делает associate?
334. Что делает associateBy?
335. Что делает associateWith?
336. Что делает windowed?
337. Что делает chunked?
338. Что делает zipWithNext?
339. Что делает takeWhile?
340. Что делает dropWhile?

---

## KOTLIN + SPRING BOOT

### Kotlin интеграция со Spring (40 вопросов)

341. Как Spring Boot поддерживает Kotlin?
342. Какие плагины нужны для Kotlin + Spring Boot?
343. Что такое kotlin-spring plugin?
344. Зачем нужен kotlin-spring plugin?
345. Что делает kotlin-allopen plugin?
346. Почему Spring требует open классы?
347. Как kotlin-allopen делает классы open?
348. Какие аннотации открывают классы автоматически?
349. Что такое kotlin-noarg plugin?
350. Зачем нужен kotlin-noarg plugin?
351. Как создать REST controller в Kotlin?
352. Как выглядит constructor injection в Kotlin?
353. Нужна ли @Autowired в Kotlin?
354. Почему constructor injection предпочтительнее в Kotlin?
355. Как использовать @ConfigurationProperties в Kotlin?
356. Что такое @ConstructorBinding?
357. Как работает @Value в Kotlin?
358. Можно ли использовать lateinit с @Autowired?
359. Что такое data class в контексте Spring?
360. Можно ли использовать data class как @Entity?
361. Какие проблемы с data class + Spring Boot?
362. Как создать Bean в Kotlin?
363. Что такое Kotlin DSL для Spring?
364. Как использовать Kotlin DSL в application configuration?
365. Что такое WebFlux + Kotlin?
366. Как использовать suspend functions в Spring WebFlux?
367. Можно ли использовать coroutines в Spring MVC?
368. Что такое @ResponseBody в Kotlin контроллере?
369. Как обрабатывать nullable параметры в REST endpoints?
370. Что такое default parameters в Kotlin контроллерах?
371. Как работает validation в Kotlin + Spring?
372. Можно ли использовать @Valid с data class?
373. Как создать custom validator в Kotlin?
374. Что такое Spring Security + Kotlin?
375. Как конфигурировать SecurityFilterChain в Kotlin?
376. Что такое Kotlin DSL для Spring Security?
377. Как тестировать Spring Boot приложение на Kotlin?
378. Что такое @SpringBootTest в Kotlin?
379. Как использовать MockMvc с Kotlin?
380. Что такое Kotest для Spring testing?

---

## KOTLIN + HIBERNATE/JPA

### Kotlin с JPA и Hibernate (30 вопросов)

381. Какие проблемы возникают с Kotlin + JPA?
382. Зачем нужен kotlin-jpa plugin?
383. Что делает kotlin-jpa plugin?
384. Какие аннотации обрабатывает kotlin-jpa?
385. Почему JPA требует no-arg constructor?
386. Как kotlin-jpa создает no-arg constructor?
387. Можно ли использовать data class как @Entity?
388. Почему data class проблематичны с JPA?
389. Какие проблемы с equals/hashCode в JPA entities?
390. Что такое lazy initialization в Hibernate?
391. Как работает lazy loading с Kotlin?
392. Можно ли использовать lateinit для @Id?
393. Что такое nullable types в JPA entities?
394. Как объявить nullable поле в entity?
395. Что делать с @ManyToOne nullable relationships?
396. Можно ли использовать val в entities?
397. Почему var предпочтительнее val в entities?
398. Что такое open classes в контексте Hibernate?
399. Почему Hibernate требует open classes?
400. Как kotlin-allopen делает entity классы open?
401. Что такое proxy в Hibernate?
402. Как Kotlin final classes влияют на proxies?
403. Можно ли использовать companion object в entity?
404. Как создать default values в entity?
405. Что такое @GeneratedValue в Kotlin?
406. Как работает @Id с nullable Long?
407. Что такое cascading в Kotlin entities?
408. Как обрабатывать bidirectional relationships?
409. Что такое @JsonIgnore в контексте Kotlin + JPA?
410. Как избежать lazy initialization exception?

---

## KOTLIN MULTIPLATFORM

### Kotlin Multiplatform (20 вопросов)

411. Что такое Kotlin Multiplatform (KMP)?
412. Какие платформы поддерживает KMP?
413. Что такое common code?
414. Что такое expect/actual declarations?
415. Как работает expect keyword?
416. Как работает actual keyword?
417. Приведите пример expect/actual.
418. Что такое Kotlin/Native?
419. Что такое Kotlin/JS?
420. Можно ли использовать coroutines в KMP?
421. Что такое KMM (Kotlin Multiplatform Mobile)?
422. Как структурировать KMP проект?
423. Что такое commonMain source set?
424. Что такое androidMain source set?
425. Что такое iosMain source set?
426. Как делить код между платформами?
427. Что такое platform-specific dependencies?
428. Можно ли использовать JVM libraries в KMP?
429. Что такое Ktor в контексте KMP?
430. Как тестировать KMP код?

---

## KOTLIN DSL

### Domain Specific Languages (20 вопросов)

431. Что такое DSL (Domain Specific Language)?
432. Как создать DSL в Kotlin?
433. Что такое lambda with receiver в DSL?
434. Приведите пример DSL.
435. Что такое @DslMarker?
436. Зачем нужен @DslMarker?
437. Как @DslMarker помогает с type safety?
438. Что такое builder pattern в Kotlin?
439. Как создать type-safe builder?
440. Что такое HTML DSL?
441. Приведите пример HTML builder.
442. Что такое Gradle Kotlin DSL?
443. В чем преимущество Kotlin DSL над Groovy?
444. Как использовать infix functions в DSL?
445. Что такое operator overloading в DSL?
446. Приведите пример DSL для конфигурации.
447. Что такое context receivers (experimental)?
448. Как context receivers помогают в DSL?
449. Что такое type-safe builders?
450. Какие библиотеки используют Kotlin DSL?

---

## ADVANCED KOTLIN TOPICS

### Продвинутые темы (30 вопросов)

451. Что такое delegation в Kotlin?
452. Что такое class delegation?
453. Как использовать `by` keyword для delegation?
454. Что такое property delegation?
455. Что такое delegated properties?
456. Приведите пример custom delegated property.
457. Что такое lazy delegation?
458. Что такое observable delegation?
459. Что такое vetoable delegation?
460. Что делает Delegates.notNull()?
461. Что такое annotation processing в Kotlin?
462. Что такое KAPT?
463. Чем KAPT отличается от KSP?
464. Что такое KSP (Kotlin Symbol Processing)?
465. Какие преимущества KSP над KAPT?
466. Что такое reflection в Kotlin?
467. Как использовать Kotlin reflection?
468. Что такое KClass?
469. Что такое KProperty?
470. Что такое KFunction?
471. Как получить reference на property?
472. Что такое reified generics?
473. Что такое variance в Kotlin?
474. Что такое covariance?
475. Что такое contravariance?
476. Что означает `out` keyword?
477. Что означает `in` keyword?
478. Что такое star projection `*`?
479. Что такое type erasure в Kotlin?
480. Как обойти type erasure с reified?

---

## KOTLIN VS JAVA

### Сравнение с Java (30 вопросов)

481. В чем главное преимущество Kotlin над Java?
482. Что такое null safety преимущество?
483. Как Kotlin решает NPE проблему?
484. Чем отличается создание класса в Kotlin и Java?
485. Как Kotlin упрощает data classes?
486. Что такое primary constructor в Kotlin?
487. Что такое secondary constructor?
488. Чем отличаются конструкторы от Java?
489. Как выглядит singleton в Kotlin vs Java?
490. Как выглядит static методы в Kotlin vs Java?
491. Что использовать вместо static в Kotlin?
492. Есть ли checked exceptions в Kotlin?
493. Почему Kotlin убрал checked exceptions?
494. Как это влияет на error handling?
495. Что такое extension functions преимущество над Java?
496. Можно ли вызвать Kotlin код из Java?
497. Можно ли вызвать Java код из Kotlin?
498. Что такое Java interoperability?
499. Что такое @JvmStatic аннотация?
500. Что такое @JvmField аннотация?
501. Что такое @JvmName аннотация?
502. Что такое @JvmOverloads аннотация?
503. Зачем нужна @JvmOverloads?
504. Что такое @Throws аннотация?
505. Зачем нужна @Throws при Java interop?
506. Как Kotlin обрабатывает SAM interfaces?
507. Что такое SAM conversion?
508. Как лямбды в Kotlin конвертируются в Java?
509. Можно ли использовать Kotlin default parameters из Java?
510. Как использовать named arguments при вызове из Java?

---

## ПРАКТИЧЕСКИЕ ЗАДАЧИ (CODING)

### Kotlin Coding Challenges (50 задач)

511. Напишите функцию для проверки, является ли строка палиндромом.
512. Напишите extension function для String, которая возвращает reversed строку.
513. Создайте data class для User с полями: id, name, email.
514. Напишите функцию, которая принимает nullable String и возвращает её длину или 0.
515. Используйте Elvis operator для возврата default значения.
516. Напишите функцию с использованием `when` expression для определения типа number.
517. Создайте sealed class для Result (Success, Error, Loading).
518. Напишите extension function для List<Int> для нахождения среднего значения.
519. Создайте singleton object для DatabaseConfig.
520. Напишите companion object метод для factory pattern.
521. Создайте inline function для измерения времени выполнения блока кода.
522. Используйте `reified` для generic type checking.
523. Напишите suspend function для асинхронной загрузки данных.
524. Используйте `withContext` для переключения Dispatcher.
525. Создайте Flow, который эмитит числа от 1 до 10.
526. Напишите функцию, которая использует `map` на Flow.
527. Создайте StateFlow для хранения UI state.
528. Напишите код для `collect` данных из Flow.
529. Используйте `launch` для запуска coroutine.
530. Используйте `async` и `await` для параллельных задач.
531. Создайте функцию с использованием `let` scope function.
532. Создайте функцию с использованием `apply` scope function.
533. Напишите code для destructuring data class.
534. Создайте range от 1 до 100 и отфильтруйте четные числа.
535. Напишите функцию для группировки списка по условию.
536. Используйте `groupBy` для группировки User по age.
537. Создайте Sequence для ленивого вычисления.
538. Напишите функцию с default parameters.
539. Создайте функцию с named arguments.
540. Используйте `filter` и `map` на списке.
541. Напишите code для обработки nullable list.
542. Используйте `filterNotNull()` на списке.
543. Создайте extension property для String.
544. Напишите infix function для математической операции.
545. Создайте delegated property с `by lazy`.
546. Используйте `lateinit` для инициализации переменной.
547. Напишите tail-recursive функцию для factorial.
548. Создайте higher-order function, которая принимает lambda.
549. Напишите lambda expression с несколькими параметрами.
550. Используйте trailing lambda syntax.
551. Создайте type alias для сложного типа.
552. Напишите функцию с vararg параметром.
553. Используйте spread operator `*` для vararg.
554. Создайте enum class с методами.
555. Напишите when expression для enum.
556. Создайте inline class для типобезопасного ID.
557. Используйте operator overloading для custom класса.
558. Создайте DSL для построения HTML.
559. Напишите builder pattern с lambda with receiver.
560. Используйте `@DslMarker` для type-safe DSL.

---

## ДОПОЛНИТЕЛЬНЫЕ ВОПРОСЫ

### Coroutines Advanced (20 вопросов)

561. Что такое coroutine context?
562. Как передать CoroutineContext в coroutine?
563. Что такое Job hierarchy?
564. Как связаны parent и child Jobs?
565. Что происходит при отмене parent Job?
566. Что такое exception propagation в coroutines?
567. Как обрабатывать exceptions в supervisorScope?
568. Что такое CoroutineStart?
569. Какие типы CoroutineStart есть?
570. Что делает CoroutineStart.LAZY?
571. Что такое coroutine builders?
572. Какие coroutine builders существуют?
573. Что такое produce builder?
574. Что такое actor builder?
575. Как работает Channel?
576. В чем разница между Channel и Flow?
577. Что такое buffered channel?
578. Что такое rendezvous channel?
579. Как закрыть Channel?
580. Что такое select expression для Channels?

### Flow Advanced (10 вопросов)

581. Как обрабатывать exceptions в Flow?
582. Что делает catch operator?
583. Что делает retry operator?
584. Что делает onCompletion?
585. Что такое exception transparency?
586. Как работает flowOn operator?
587. Что такое conflation в Flow?
588. Что делает stateIn operator?
589. Что делает shareIn operator?
590. В чем разница между stateIn и shareIn?

### Spring + Kotlin Advanced (10 вопросов)

591. Как использовать coroutines в Spring WebFlux?
592. Что такое RouterFunction DSL в Kotlin?
593. Как создать functional endpoints в Spring?
594. Что такое reactive streams в Kotlin?
595. Как использовать R2DBC с Kotlin?
596. Что такое Spring Data R2DBC + Kotlin?
597. Как тестировать WebFlux endpoints?
598. Что такое WebTestClient в Kotlin?
599. Как использовать @DataR2dbcTest?
600. Как интегрировать Kotlin Flow со Spring?

---

## ИТОГОВАЯ СТАТИСТИКА

**Всего вопросов:** 600+

### Распределение по категориям:

| Категория | Количество вопросов |
|-----------|---------------------|
| Kotlin Basics & Language Features | 50 |
| Null Safety | 40 |
| Data Classes, Sealed Classes, Object | 50 |
| Extension & Higher-Order Functions | 50 |
| Kotlin Coroutines | 80 |
| Kotlin Flow & Channels | 40 |
| Kotlin Collections & Sequences | 30 |
| Kotlin + Spring Boot | 40 |
| Kotlin + Hibernate/JPA | 30 |
| Kotlin Multiplatform | 20 |
| Kotlin DSL | 20 |
| Advanced Kotlin Topics | 30 |
| Kotlin vs Java | 30 |
| Практические задачи (Coding) | 50 |
| Дополнительные вопросы | 40 |
| **ИТОГО** | **600+** |

---

## РЕКОМЕНДАЦИИ ПО ПОДГОТОВКЕ

### Для Junior Kotlin Developer (6-12 месяцев опыта):

**Обязательные разделы:**
1. ✅ Kotlin Basics (все 50 вопросов)
2. ✅ Null Safety (все 40 вопросов)
3. ✅ Data Classes, Sealed Classes (40 вопросов)
4. ✅ Extension Functions (30 вопросов)
5. ✅ Coroutines Basics (40 вопросов)
6. ✅ Collections (все 30 вопросов)
7. ✅ Kotlin vs Java (20 вопросов)

**Практика:**
- 20-30 coding задач
- Простые coroutines примеры
- Extension functions упражнения

**Время подготовки:** 2-3 месяца

---

### Для Middle Kotlin Developer (1-3 года опыта):

**Обязательные разделы:**
1. ✅ Все вопросы Junior уровня
2. ✅ Coroutines Advanced (все 80 вопросов)
3. ✅ Flow & Channels (все 40 вопросов)
4. ✅ Higher-Order Functions (все 50 вопросов)
5. ✅ Kotlin + Spring Boot (все 40 вопросов)
6. ✅ Kotlin + JPA (все 30 вопросов)
7. ✅ Advanced Topics (20 вопросов)

**Практика:**
- 40-50 coding задач
- Сложные coroutines сценарии
- Flow операторы
- Spring Boot + Kotlin проекты

**Время подготовки:** 1-2 месяца

---

### Для Senior Kotlin Developer (3+ года опыта):

**Обязательные разделы:**
1. ✅ Все 600+ вопросов
2. ✅ Kotlin Multiplatform (все 20 вопросов)
3. ✅ Kotlin DSL (все 20 вопросов)
4. ✅ Advanced Topics (все 30 вопросов)
5. ✅ Архитектурные решения
6. ✅ Performance optimization

**Практика:**
- Все 50 coding задач
- Архитектурные сценарии
- DSL design
- KMP проекты

**Время подготовки:** 2-3 недели

---

## ДОПОЛНИТЕЛЬНЫЕ РЕСУРСЫ

### Официальная документация:
- Kotlin Documentation: https://kotlinlang.org/docs/
- Kotlin Coroutines Guide: https://kotlinlang.org/docs/coroutines-guide.html
- Kotlin Flow: https://kotlinlang.org/docs/flow.html

### Практика:
- Kotlin Koans: https://kotlinlang.org/docs/koans.html
- Exercism Kotlin Track: https://exercism.org/tracks/kotlin
- LeetCode (Kotlin solutions)

### Книги:
- "Kotlin in Action" by Dmitry Jemerov
- "Kotlin Coroutines" by Marcin Moskała
- "Effective Kotlin" by Marcin Moskała

---

## СОВЕТЫ ПО СОБЕСЕДОВАНИЮ

### ✅ DO:
- Объясняйте, почему выбрали Kotlin-specific решение
- Сравнивайте с Java подходом
- Обсуждайте null safety преимущества
- Демонстрируйте знание coroutines
- Показывайте практические примеры
- Упоминайте best practices

### ❌ DON'T:
- Не пишите Java-style Kotlin код
- Не игнорируйте null safety
- Не злоупотребляйте `!!` operator
- Не используйте GlobalScope
- Не забывайте про cancellation
- Не игнорируйте structured concurrency

---

**Версия:** 1.0  
**Дата:** Январь 2026  
**Статус:** Актуально для Kotlin 1.9+, Coroutines 1.7+

**Удачи на Kotlin собеседованиях! 🚀**