# Java Interview Questions — Полный Сборник
## Trainee → Junior → Middle → Senior (1800+ вопросов)

**Составлено:** Январь 2026  
**Версия:** 2.0 (Расширенная)  
**Всего вопросов:** 1800+

---

## ДОПОЛНИТЕЛЬНЫЕ РАЗДЕЛЫ (500+ вопросов)

### Advanced Java Core (30 вопросов)

1001. Что такое SPI (Service Provider Interface)?
1002. Как работают модули (modules) в Java 9+?
1003. Что такое JPMS (Java Platform Module System)?
1004. Какие нововведения в Java 10 (Local-Variable Type Inference)?
1005. Что такое records в Java 14+?
1006. Как работают sealed classes в Java 15+?
1007. Что такое pattern matching в Java 16+?
1008. Какие improvements в virtual threads (Project Loom)?
1009. Что такое Project Panama и зачем оно нужно?
1010. Как работает Java Flight Recorder (JFR)?
1011. Что такое Compact Strings в Java 9?
1012. Как работает String deduplication в G1GC?
1013. Что такое ZGC (Z Garbage Collector)?
1014. Как работает Shenandoah GC?
1015. Что такое metaspace в Java 8+?
1016. Как оптимизировать работу с примитивами в Java?
1017. Что такое escape analysis в JIT компиляторе?
1018. Как работает scalar replacement?
1019. Что такое profile-guided optimization?
1020. Как использовать jmap для анализа памяти?
1021. Как использовать jstat для мониторинга GC?
1022. Как использовать jstack для анализа deadlock?
1023. Что такое TLAB (Thread Local Allocation Buffer)?
1024. Как работает write barrier в GC?
1025. Что такое card marking?
1026. Как работает concurrent mark-sweep?
1027. Что такое G1GC (Garbage First)?
1028. Как настроить GC параметры?
1029. Что такое GC pauses и как их минимизировать?
1030. Как профилировать Java приложение?

### Advanced Collections & Data Structures (50 вопросов)

1031. Как реализовать собственный LinkedList?
1032. Как реализовать собственный HashMap?
1033. Как реализовать собственный HashSet?
1034. Как работает TreeMap внутри (Red-Black Tree)?
1035. Как работает ConcurrentSkipListMap?
1036. Что такое skip list и как она работает?
1037. Как работает CopyOnWriteArrayList?
1038. Когда использовать CopyOnWriteArrayList вместо Collections.synchronizedList()?
1039. Что такое ConcurrentLinkedQueue?
1040. Как работает LinkedBlockingQueue?
1041. Что такое ArrayBlockingQueue?
1042. Когда использовать SynchronousQueue?
1043. Что такое PriorityBlockingQueue?
1044. Как работает DelayQueue?
1045. Что такое TransferQueue и как работает LinkedTransferQueue?
1046. Как реализовать свой BlockingQueue?
1047. Что такое ConcurrentHashMap bucket (сегмент)?
1048. Как работает ConcurrentHashMap.putIfAbsent()?
1049. Что такое LRU cache и как его реализовать?
1050. Как реализовать LRU cache используя LinkedHashMap?

### Advanced Multithreading & Concurrency (50 вопросов)

1051. Что такое happens-before relationship в Java Memory Model?
1052. Какие действия создают happens-before edges?
1053. Что такое visibility в памяти?
1054. Что такое instruction reordering?
1055. Почему компилятор переупорядочивает инструкции?
1056. Как volatile гарантирует visibility?
1057. Как synchronized влияет на memory ordering?
1058. Что такое memory barrier / fence?
1059. Какие типы memory barriers есть?
1060. Как использовать Unsafe для low-level операций?
1061. Что такое Double-Checked Locking?
1062. Почему Double-Checked Locking был broken до Java 5?
1063. Как исправить Double-Checked Locking с помощью volatile?
1064. Что такое CountDownLatch и как его использовать?
1065. Что такое CyclicBarrier?
1066. В чем разница между CountDownLatch и CyclicBarrier?
1067. Что такое Semaphore и когда его использовать?
1068. Что такое Exchanger?
1069. Что такое Phaser?
1070. Что такое ReentrantLock?
1071. Как работает ReentrantReadWriteLock?
1072. Когда использовать ReadWriteLock?
1073. Что такое StampedLock?
1074. В чем преимущество StampedLock над ReadWriteLock?
1075. Что такое Condition в Java concurrency?
1076. Как использовать Condition.await() и signal()?
1077. Что такое LockSupport?
1078. Как работают методы park() и unpark()?
1079. Что такое ForkJoinPool?
1080. Как работает work-stealing algorithm в ForkJoinPool?
1081. Что такое RecursiveTask и RecursiveAction?
1082. Когда использовать ForkJoinPool вместо ThreadPoolExecutor?
1083. Что такое CompletableFuture?
1084. Как использовать CompletableFuture.supplyAsync()?
1085. Как использовать CompletableFuture.thenApply()?
1086. Как использовать CompletableFuture.thenAccept()?
1087. Как использовать CompletableFuture.thenCombine()?
1088. Как использовать CompletableFuture.thenCompose()?
1089. Что такое exception handling в CompletableFuture?
1090. Как использовать CompletableFuture.handle()?
1091. Что такое CompletableFuture.allOf()?
1092. Что такое CompletableFuture.anyOf()?

### Advanced Stream API (40 вопросов)

1093. Что такое stream intermediate operations?
1094. Что такое stream terminal operations?
1095. Что такое short-circuiting operations?
1096. Какие операции являются short-circuiting?
1097. Что такое stateful и stateless stream operations?
1098. Какие операции являются stateful?
1099. Как работает parallel stream?
1100. Когда использовать parallel stream?
1101. Когда НЕ использовать parallel stream?
1102. Что такое spliterator?
1103. Как создать собственный spliterator?
1104. Что такое stream collector?
1105. Как работает Collector.collect()?
1106. Как создать собственный Collector?
1107. Что такое Stream.reduce()?
1108. В чем разница между reduce() и collect()?
1109. Что такое Optional.flatMap()?
1110. Когда использовать flatMap() вместо map()?
1111. Что такое Stream.peek()?
1112. Как использовать Stream.peek() для отладки?
1113. Что такое Stream.generate()?
1114. Что такое Stream.iterate()?
1115. Как создать бесконечный stream?
1116. Что такое Stream.takeWhile() и Stream.dropWhile()?
1117. Как работает Collectors.groupingBy()?
1118. Как работает Collectors.partitioningBy()?
1119. Как работает Collectors.toMap()?
1120. Как работает Collectors.joining()?

### Advanced Spring Framework (50 вопросов)

1121. Как работает Spring context инициализация?
1122. Что такое BeanFactory vs ApplicationContext?
1123. Как работает BeanPostProcessor?
1124. Что такое BeanFactoryPostProcessor?
1125. Когда использовать BeanPostProcessor vs BeanFactoryPostProcessor?
1126. Что такое FactoryBean?
1127. Как использовать ObjectProvider для опциональных зависимостей?
1128. Что такое Aware интерфейсы в Spring?
1129. Какие Aware интерфейсы есть?
1130. Что такое InitializingBean и DisposableBean?
1131. Как использовать @PostConstruct и @PreDestroy?
1132. Что такое Spring profiles?
1133. Как использовать @Profile аннотацию?
1134. Что такое Spring properties?
1135. Как использовать @Value для injection properties?
1136. Как использовать @PropertySource?
1137. Что такое Spring Environment?
1138. Как использовать Environment для доступа к properties?
1139. Что такое application.properties vs application.yml?
1140. Как конфигурировать logging в Spring Boot?
1141. Что такое Spring Boot auto-configuration?
1142. Как переопределить auto-configuration?
1143. Что такое @ConditionalOnProperty?
1144. Какие @Conditional аннотации есть?
1145. Как создать собственную Condition?
1146. Что такое Spring Boot Actuator?
1147. Какие endpoints предоставляет Actuator?
1148. Как создать собственный Actuator endpoint?
1149. Что такое @ConfigurationProperties?
1150. Как использовать @ConfigurationProperties для типобезопасной конфигурации?
1151. Что такое @ConstructorBinding?
1152. Как работает Spring Boot embedded servers?
1153. Что такое Spring BeanDefinition?
1154. Как программно регистрировать beans?
1155. Что такое bean lifecycle?
1156. Как контролировать bean lifecycle?
1157. Что такое ObjectProvider?
1158. Как использовать ObjectProvider?
1159. Что такое @Lazy?
1160. Когда использовать @Lazy?
1161. Что такое event-driven architecture в Spring?
1162. Как использовать ApplicationEventPublisher?
1163. Как слушать события в Spring?
1164. Какие встроенные события есть в Spring?
1165. Как создать собственное событие?
1166. Что такое Spring AOP?
1167. Как работает AOP?
1168. Что такое Aspect, Join Point, Pointcut?
1169. Какие типы Advice есть?
1170. Как создать собственный aspect?

### Advanced Microservices (50 вопросов)

1171. Что такое microservices architecture?
1172. Какие advantages/disadvantages microservices?
1173. Когда использовать microservices?
1174. Что такое monolithic architecture?
1175. Когда использовать monolithic?
1176. Как перейти с monolith на microservices?
1177. Что такое service mesh?
1178. Как работает Istio?
1179. Как работает Consul?
1180. Что такое service discovery?
1181. Как использовать Eureka для service discovery?
1182. Что такое client-side service discovery?
1183. Что такое server-side service discovery?
1184. Как использовать Ribbon для load balancing?
1185. Что такое LoadBalancer в Spring Cloud?
1186. Как использовать Spring Cloud LoadBalancer?
1187. Что такое API gateway?
1188. Как использовать Spring Cloud Gateway?
1189. Что такое path predicates в gateway?
1190. Что такое filters в gateway?
1191. Как создать собственный filter в gateway?
1192. Что такое rate limiting в gateway?
1193. Что такое authentication в gateway?
1194. Что такое distributed transactions?
1195. Как обрабатывать distributed transactions?
1196. Что такое compensation-based transactions?
1197. Как использовать saga pattern?
1198. Что такое choreography-based saga?
1199. Что такое orchestration-based saga?
1200. Когда использовать choreography vs orchestration?
1201. Как обрабатывать distributed tracing в microservices?
1202. Как обрабатывать logging в microservices?
1203. Как обрабатывать configuration в microservices?
1204. Что такое Spring Cloud Config?
1205. Как использовать Spring Cloud Config Server?# Java Interview Questions — Полный Сборник
## Trainee → Junior → Middle → Senior (1800+ вопросов)

**Составлено:** Январь 2026  
**Версия:** 2.0 (Расширенная)  
**Всего вопросов:** 1800+

---

## ДОПОЛНИТЕЛЬНЫЕ РАЗДЕЛЫ (500+ вопросов)

### Advanced Java Core (30 вопросов)

1001. Что такое SPI (Service Provider Interface)?
1002. Как работают модули (modules) в Java 9+?
1003. Что такое JPMS (Java Platform Module System)?
1004. Какие нововведения в Java 10 (Local-Variable Type Inference)?
1005. Что такое records в Java 14+?
1006. Как работают sealed classes в Java 15+?
1007. Что такое pattern matching в Java 16+?
1008. Какие improvements в virtual threads (Project Loom)?
1009. Что такое Project Panama и зачем оно нужно?
1010. Как работает Java Flight Recorder (JFR)?
1011. Что такое Compact Strings в Java 9?
1012. Как работает String deduplication в G1GC?
1013. Что такое ZGC (Z Garbage Collector)?
1014. Как работает Shenandoah GC?
1015. Что такое metaspace в Java 8+?
1016. Как оптимизировать работу с примитивами в Java?
1017. Что такое escape analysis в JIT компиляторе?
1018. Как работает scalar replacement?
1019. Что такое profile-guided optimization?
1020. Как использовать jmap для анализа памяти?
1021. Как использовать jstat для мониторинга GC?
1022. Как использовать jstack для анализа deadlock?
1023. Что такое TLAB (Thread Local Allocation Buffer)?
1024. Как работает write barrier в GC?
1025. Что такое card marking?
1026. Как работает concurrent mark-sweep?
1027. Что такое G1GC (Garbage First)?
1028. Как настроить GC параметры?
1029. Что такое GC pauses и как их минимизировать?
1030. Как профилировать Java приложение?

### Advanced Collections & Data Structures (50 вопросов)

1031. Как реализовать собственный LinkedList?
1032. Как реализовать собственный HashMap?
1033. Как реализовать собственный HashSet?
1034. Как работает TreeMap внутри (Red-Black Tree)?
1035. Как работает ConcurrentSkipListMap?
1036. Что такое skip list и как она работает?
1037. Как работает CopyOnWriteArrayList?
1038. Когда использовать CopyOnWriteArrayList вместо Collections.synchronizedList()?
1039. Что такое ConcurrentLinkedQueue?
1040. Как работает LinkedBlockingQueue?
1041. Что такое ArrayBlockingQueue?
1042. Когда использовать SynchronousQueue?
1043. Что такое PriorityBlockingQueue?
1044. Как работает DelayQueue?
1045. Что такое TransferQueue и как работает LinkedTransferQueue?
1046. Как реализовать свой BlockingQueue?
1047. Что такое ConcurrentHashMap bucket (сегмент)?
1048. Как работает ConcurrentHashMap.putIfAbsent()?
1049. Что такое LRU cache и как его реализовать?
1050. Как реализовать LRU cache используя LinkedHashMap?

### Advanced Multithreading & Concurrency (50 вопросов)

1051. Что такое happens-before relationship в Java Memory Model?
1052. Какие действия создают happens-before edges?
1053. Что такое visibility в памяти?
1054. Что такое instruction reordering?
1055. Почему компилятор переупорядочивает инструкции?
1056. Как volatile гарантирует visibility?
1057. Как synchronized влияет на memory ordering?
1058. Что такое memory barrier / fence?
1059. Какие типы memory barriers есть?
1060. Как использовать Unsafe для low-level операций?
1061. Что такое Double-Checked Locking?
1062. Почему Double-Checked Locking был broken до Java 5?
1063. Как исправить Double-Checked Locking с помощью volatile?
1064. Что такое CountDownLatch и как его использовать?
1065. Что такое CyclicBarrier?
1066. В чем разница между CountDownLatch и CyclicBarrier?
1067. Что такое Semaphore и когда его использовать?
1068. Что такое Exchanger?
1069. Что такое Phaser?
1070. Что такое ReentrantLock?
1071. Как работает ReentrantReadWriteLock?
1072. Когда использовать ReadWriteLock?
1073. Что такое StampedLock?
1074. В чем преимущество StampedLock над ReadWriteLock?
1075. Что такое Condition в Java concurrency?
1076. Как использовать Condition.await() и signal()?
1077. Что такое LockSupport?
1078. Как работают методы park() и unpark()?
1079. Что такое ForkJoinPool?
1080. Как работает work-stealing algorithm в ForkJoinPool?
1081. Что такое RecursiveTask и RecursiveAction?
1082. Когда использовать ForkJoinPool вместо ThreadPoolExecutor?
1083. Что такое CompletableFuture?
1084. Как использовать CompletableFuture.supplyAsync()?
1085. Как использовать CompletableFuture.thenApply()?
1086. Как использовать CompletableFuture.thenAccept()?
1087. Как использовать CompletableFuture.thenCombine()?
1088. Как использовать CompletableFuture.thenCompose()?
1089. Что такое exception handling в CompletableFuture?
1090. Как использовать CompletableFuture.handle()?
1091. Что такое CompletableFuture.allOf()?
1092. Что такое CompletableFuture.anyOf()?

### Advanced Stream API (40 вопросов)

1093. Что такое stream intermediate operations?
1094. Что такое stream terminal operations?
1095. Что такое short-circuiting operations?
1096. Какие операции являются short-circuiting?
1097. Что такое stateful и stateless stream operations?
1098. Какие операции являются stateful?
1099. Как работает parallel stream?
1100. Когда использовать parallel stream?
1101. Когда НЕ использовать parallel stream?
1102. Что такое spliterator?
1103. Как создать собственный spliterator?
1104. Что такое stream collector?
1105. Как работает Collector.collect()?
1106. Как создать собственный Collector?
1107. Что такое Stream.reduce()?
1108. В чем разница между reduce() и collect()?
1109. Что такое Optional.flatMap()?
1110. Когда использовать flatMap() вместо map()?
1111. Что такое Stream.peek()?
1112. Как использовать Stream.peek() для отладки?
1113. Что такое Stream.generate()?
1114. Что такое Stream.iterate()?
1115. Как создать бесконечный stream?
1116. Что такое Stream.takeWhile() и Stream.dropWhile()?
1117. Как работает Collectors.groupingBy()?
1118. Как работает Collectors.partitioningBy()?
1119. Как работает Collectors.toMap()?
1120. Как работает Collectors.joining()?

### Advanced Spring Framework (50 вопросов)

1121. Как работает Spring context инициализация?
1122. Что такое BeanFactory vs ApplicationContext?
1123. Как работает BeanPostProcessor?
1124. Что такое BeanFactoryPostProcessor?
1125. Когда использовать BeanPostProcessor vs BeanFactoryPostProcessor?
1126. Что такое FactoryBean?
1127. Как использовать ObjectProvider для опциональных зависимостей?
1128. Что такое Aware интерфейсы в Spring?
1129. Какие Aware интерфейсы есть?
1130. Что такое InitializingBean и DisposableBean?
1131. Как использовать @PostConstruct и @PreDestroy?
1132. Что такое Spring profiles?
1133. Как использовать @Profile аннотацию?
1134. Что такое Spring properties?
1135. Как использовать @Value для injection properties?
1136. Как использовать @PropertySource?
1137. Что такое Spring Environment?
1138. Как использовать Environment для доступа к properties?
1139. Что такое application.properties vs application.yml?
1140. Как конфигурировать logging в Spring Boot?
1141. Что такое Spring Boot auto-configuration?
1142. Как переопределить auto-configuration?
1143. Что такое @ConditionalOnProperty?
1144. Какие @Conditional аннотации есть?
1145. Как создать собственную Condition?
1146. Что такое Spring Boot Actuator?
1147. Какие endpoints предоставляет Actuator?
1148. Как создать собственный Actuator endpoint?
1149. Что такое @ConfigurationProperties?
1150. Как использовать @ConfigurationProperties для типобезопасной конфигурации?
1151. Что такое @ConstructorBinding?
1152. Как работает Spring Boot embedded servers?
1153. Что такое Spring BeanDefinition?
1154. Как программно регистрировать beans?
1155. Что такое bean lifecycle?
1156. Как контролировать bean lifecycle?
1157. Что такое ObjectProvider?
1158. Как использовать ObjectProvider?
1159. Что такое @Lazy?
1160. Когда использовать @Lazy?
1161. Что такое event-driven architecture в Spring?
1162. Как использовать ApplicationEventPublisher?
1163. Как слушать события в Spring?
1164. Какие встроенные события есть в Spring?
1165. Как создать собственное событие?
1166. Что такое Spring AOP?
1167. Как работает AOP?
1168. Что такое Aspect, Join Point, Pointcut?
1169. Какие типы Advice есть?
1170. Как создать собственный aspect?

### Advanced Microservices (50 вопросов)

1171. Что такое microservices architecture?
1172. Какие advantages/disadvantages microservices?
1173. Когда использовать microservices?
1174. Что такое monolithic architecture?
1175. Когда использовать monolithic?
1176. Как перейти с monolith на microservices?
1177. Что такое service mesh?
1178. Как работает Istio?
1179. Как работает Consul?
1180. Что такое service discovery?
1181. Как использовать Eureka для service discovery?
1182. Что такое client-side service discovery?
1183. Что такое server-side service discovery?
1184. Как использовать Ribbon для load balancing?
1185. Что такое LoadBalancer в Spring Cloud?
1186. Как использовать Spring Cloud LoadBalancer?
1187. Что такое API gateway?
1188. Как использовать Spring Cloud Gateway?
1189. Что такое path predicates в gateway?
1190. Что такое filters в gateway?
1191. Как создать собственный filter в gateway?
1192. Что такое rate limiting в gateway?
1193. Что такое authentication в gateway?
1194. Что такое distributed transactions?
1195. Как обрабатывать distributed transactions?
1196. Что такое compensation-based transactions?
1197. Как использовать saga pattern?
1198. Что такое choreography-based saga?
1199. Что такое orchestration-based saga?
1200. Когда использовать choreography vs orchestration?
1201. Как обрабатывать distributed tracing в microservices?
1202. Как обрабатывать logging в microservices?
1203. Как обрабатывать configuration в microservices?
1204. Что такое Spring Cloud Config?
1205. Как использовать Spring Cloud Config Server?
1206. Что такое configuration refresh?
1207. Как использовать @RefreshScope?
1208. Что такое resilience4j?
1209. Как использовать resilience4j?
1210. Что такое event-driven microservices?
1211. Как организовать communication между microservices?
1212. Что такое eventual consistency?
1213. Как обрабатывать eventual consistency?
1214. Что такое API versioning?
1215. Какие стратегии API versioning есть?
1216. Что такое backward compatibility?
1217. Как обеспечить backward compatibility?
1218. Что такое blue-green deployment?
1219. Что такое canary deployment?
1220. Как реализовать blue-green deployment?

### Advanced Kafka (50 вопросов)

1221. Что такое Kafka?
1222. Как работает Kafka?
1223. Что такое Kafka topic?
1224. Что такое Kafka partition?
1225. Что такое Kafka broker?
1226. Что такое Kafka producer?
1227. Как конфигурировать Kafka producer?
1228. Что такое producer batch?
1229. Как работает message buffering?
1230. Что такое acks в producer?
1231. Какие значения acks есть?
1232. Что такое idempotent producer?
1233. Как использовать transactional producer?
1234. Что такое exactly-once semantics?
1235. Как обеспечить exactly-once delivery?
1236. Что такое Kafka consumer?
1237. Как конфигурировать Kafka consumer?
1238. Что такое consumer group?
1239. Как работает consumer group?
1240. Что такое consumer lag?
1241. Как мониторить consumer lag?
1242. Что такое auto-commit?
1243. Когда использовать manual commit?
1244. Что такое offset?
1245. Как управлять offsets?
1246. Что такое rebalancing?
1247. Когда происходит rebalancing?
1248. Как обрабатывать rebalancing?
1249. Что такое listener container?
1250. Как использовать KafkaListener?
1251. Что такое dead letter queue?
1252. Как использовать dead letter queue?
1253. Что такое Kafka Streams?
1254. Как использовать Kafka Streams?
1255. Что такое KStream?
1256. Что такое KTable?
1257. Что такое GlobalKTable?
1258. Что такое stateful operations?
1259. Как использовать aggregation?
1260. Как использовать joins в Kafka Streams?
1261. Что такое windowing?
1262. Как использовать tumbling window?
1263. Как использовать hopping window?
1264. Как использовать sliding window?
1265. Что такое session window?
1266. Как использовать session window?
1267. Что такое topology в Kafka Streams?
1268. Как создать собственную topology?
1269. Что такое interactive queries?
1270. Как использовать interactive queries?

### Advanced Testing (50 вопросов)

1271. Что такое test pyramid?
1272. Как структурировать тесты?
1273. Что такое unit test vs integration test?
1274. Что такое end-to-end (E2E) test?
1275. Что такое performance test?
1276. Что такое load test?
1277. Что такое stress test?
1278. Что такое spike test?
1279. Что такое soak test?
1280. Как использовать JUnit 5?
1281. Какие differences между JUnit 4 и JUnit 5?
1282. Что такое @Test аннотация?
1283. Что такое @BeforeEach vs @BeforeClass?
1284. Что такое @Nested?
1285. Что такое @ParameterizedTest?
1286. Как использовать @CsvSource?
1287. Как использовать @MethodSource?
1288. Что такое Mockito?
1289. Как использовать @Mock?
1290. Как использовать @InjectMocks?
1291. Как использовать when().thenReturn()?
1292. Как использовать verify()?
1293. Что такое argument captor?
1294. Как использовать ArgumentCaptor?
1295. Что такое spy vs mock?
1296. Когда использовать spy?
1297. Что такое TestContainers?
1298. Как использовать TestContainers для database testing?
1299. Что такое @SpringBootTest?
1300. Как использовать @WebMvcTest?
1301. Что такое @DataJpaTest?
1302. Как использовать @DataMongoTest?
1303. Что такое MockMvc?
1304. Как использовать MockMvc.perform()?
1305. Что такое RestAssured?
1306. Как использовать RestAssured для REST API testing?
1307. Что такое contract testing?
1308. Как использовать Pact для contract testing?
1309. Что такое mutation testing?
1310. Как использовать PIT для mutation testing?
1311. Что такое code coverage?
1312. Когда 100% code coverage это плохо?
1313. Как использовать JaCoCo для code coverage?
1314. Что такое BDD (Behavior Driven Development)?
1315. Как использовать Cucumber для BDD?
1316. Что такое Gherkin?
1317. Как писать Gherkin сценарии?
1318. Что такое TestFixture?
1319. Как использовать TestFixture?
1320. Что такое test data builder?

### Advanced Docker & Kubernetes (50 вопросов)

1321. Как создать Dockerfile для Java приложения?
1322. Какие best practices для Java Dockerfiles?
1323. Что такое multi-stage build?
1324. Как использовать multi-stage build?
1325. Что такое Java container limitations?
1326. Как установить JVM heap limits?
1327. Что такое image layers?
1328. Как оптимизировать image layers?
1329. Что такое Docker registry?
1330. Как использовать Docker registry?
1331. Что такое Docker Compose?
1332. Как использовать Docker Compose для многоконтейнерных приложений?
1333. Что такое Kubernetes?
1334. Как работает Kubernetes?
1335. Что такое Pod?
1336. Как создать Pod в Kubernetes?
1337. Что такое Deployment?
1338. Как создать Deployment?
1339. Что такое Service?
1340. Какие типы Service есть?
1341. Что такое ClusterIP?
1342. Что такое NodePort?
1343. Что такое LoadBalancer?
1344. Что такое Ingress?
1345. Как конфигурировать Ingress?
1346. Что такое ConfigMap?
1347. Как использовать ConfigMap?
1348. Что такое Secret?
1349. Как управлять Secrets?
1350. Что такое PersistentVolume?
1351. Что такое PersistentVolumeClaim?
1352. Как использовать persistent storage?
1353. Что такое StatefulSet?
1354. Когда использовать StatefulSet?
1355. Что такое DaemonSet?
1356. Когда использовать DaemonSet?
1357. Что такое Job?
1358. Когда использовать Job?
1359. Что такое CronJob?
1360. Как использовать CronJob?
1361. Что такое namespace?
1362. Как использовать namespace?
1363. Что такое RBAC (Role-Based Access Control)?
1364. Как конфигурировать RBAC?
1365. Что такое NetworkPolicy?
1366. Как конфигурировать NetworkPolicy?
1367. Что такое resource limits?
1368. Как установить resource limits?
1369. Что такое health checks?
1370. Как конфигурировать health checks?

### Scenario-Based Questions (20 вопросов)

1371. У вас есть slow query. Как вы оптимизируете её?
1372. У вас есть memory leak. Как вы её найдёте?
1373. У вас есть deadlock. Как вы её разрешите?
1374. Ваше приложение потребляет слишком много CPU. Что вы сделаете?
1375. Ваше приложение потребляет слишком много памяти. Как вы оптимизируете?
1376. Ваше приложение часто выбрасывает OutOfMemoryError. Что делать?
1377. Вы заметили, что потребление памяти растёт со временем. Как это диагностировать?
1378. Вы хотите улучшить response time приложения. С чего начать?
1379. Вы хотите масштабировать приложение горизонтально. Что нужно учесть?
1380. Вы вводите feature flag. Как это реализовать?
1381. У вас есть несинхронизированный доступ к shared mutable state. Как это исправить?
1382. Вы хотите добавить caching. Какую стратегию выбрать?
1383. Ваш cache становится inconsistent. Как это решить?
1384. Вы нужно обработать миллионы сообщений в день. Как архитектурировать систему?
1385. Вы нужно обеспечить high availability. Что нужно сделать?
1386. Вы нужно обеспечить disaster recovery. Как это спланировать?
1387. Вы нужно мигрировать данные между базами данных. Как это сделать без downtime?
1388. Вы нужно roll back production deployment. Как это сделать?
1389. Вы нужно добавить authentication в существующее приложение. Как это сделать?
1390. Вы нужно логировать sensitive data. Как это сделать безопасно?

### LeetCode-Style Coding Problems (50 задач)

1391. Two Sum (Easy)
1392. Add Two Numbers (Medium)
1393. Longest Substring Without Repeating Characters (Medium)
1394. Median of Two Sorted Arrays (Hard)
1395. Longest Palindromic Substring (Medium)
1396. ZigZag Conversion (Medium)
1397. Reverse Integer (Medium)
1398. String to Integer (Medium)
1399. Palindrome Number (Easy)
1400. Container With Most Water (Medium)
1401. Integer to Roman (Medium)
1402. Roman to Integer (Easy)
1403. Longest Common Prefix (Easy)
1404. 3Sum (Medium)
1405. 3Sum Closest (Medium)
1406. Letter Combinations of a Phone Number (Medium)
1407. 4Sum (Medium)
1408. Remove Nth Node From End of List (Medium)
1409. Valid Parentheses (Easy)
1410. Merge Two Sorted Lists (Easy)
1411. Generate Parentheses (Medium)
1412. Merge k Sorted Lists (Hard)
1413. Swap Nodes in Pairs (Medium)
1414. Reverse Nodes in k-Group (Hard)
1415. Remove Duplicates from Sorted Array (Easy)
1416. Remove Element (Easy)
1417. Implement strStr() (Easy)
1418. Divide Two Integers (Medium)
1419. Substring with Concatenation of All Words (Hard)
1420. Next Permutation (Medium)
1421. Longest Valid Parentheses (Hard)
1422. Search in Rotated Sorted Array (Medium)
1423. Search for a Range (Medium)
1424. Search Insert Position (Easy)
1425. Wildcard Matching (Hard)
1426. Regular Expression Matching (Hard)
1427. Trapping Rain Water (Hard)
1428. Jump Game II (Medium)
1429. Maximum Product Subarray (Medium)
1430. Rotate Image (Medium)
1431. Word Search (Medium)
1432. Minimum Window Substring (Hard)
1433. Largest Rectangle in Histogram (Hard)
1434. Maximal Rectangle (Hard)
1435. Partition List (Medium)
1436. Linked List Cycle (Easy)
1437. Linked List Cycle II (Medium)
1438. Reorder List (Medium)
1439. Binary Tree Level Order Traversal (Easy)
1440. Binary Tree Zigzag Level Order Traversal (Medium)

---

## ИТОГОВАЯ СТАТИСТИКА (Расширенная версия)

**Всего вопросов:** 1800+  
**Количество разделов:** 100+  
**Средняя сложность:** от Trainee до Senior

### Распределение по категориям:

| Категория | Кол-во вопросов |
|-----------|-----------------|
| Java Core | 280 |
| Collections | 120 |
| String/Enum/Lambda | 140 |
| Exceptions | 40 |
| Multithreading | 130 |
| Memory/GC | 70 |
| Spring | 200 |
| Hibernate/JPA | 80 |
| Databases | 100 |
| JDBC | 40 |
| Design Patterns | 80 |
| Microservices | 100 |
| Kafka | 100 |
| Docker/Kubernetes | 100 |
| Testing | 80 |
| AWS/Cloud | 50 |
| Scenario-based | 20 |
| Coding Problems | 100 |
| **ИТОГО** | **1800+** |

---

## РЕКОМЕНДАЦИИ ПО ИСПОЛЬЗОВАНИЮ

### Для Trainee (0-6 месяцев):
1. Раздел "Java Core — Базовый уровень" (250 вопросов)
2. Раздел "ООП" (40 вопросов)
3. Раздел "Collections Framework" (70 вопросов)
4. Раздел "Exceptions" (30 вопросов)
5. 20-30 простых LeetCode задач

**Время подготовки:** 2-3 месяца

### Для Junior (6-18 месяцев):
1. Все вопросы Trainee (базовый уровень)
2. Раздел "Java Core — Продвинутый уровень" (100 вопросов)
3. Раздел "Multithreading" (100+ вопросов)
4. Раздел "Spring Framework" (100+ вопросов)
5. Раздел "Databases & SQL" (100+ вопросов)
6. 30-50 средних LeetCode задач
7. Выборочно: Design Patterns, JDBC

**Время подготовки:** 3-4 месяца

### Для Middle (1.5-3 года):
1. Все вопросы Junior
2. Весь "Advanced Java Core" раздел (30 вопросов)
3. "Advanced Collections & Data Structures" (50 вопросов)
4. "Advanced Multithreading" (50 вопросов)
5. "Advanced Spring Framework" (50 вопросов)
6. "Advanced Microservices" (50 вопросов)
7. "Advanced Kafka" (50 вопросов)
8. "Advanced Testing" (50 вопросов)
9. 50+ LeetCode задач (Medium/Hard)
10. Scenario-based questions
11. System Design questions

**Время подготовки:** 4-6 недель перед собеседованием

### Для Senior (3+ года):
1. Все 1800+ вопросов
2. Глубокий анализ архитектурных решений
3. Real-world project scenarios
4. Performance optimization challenges
5. Leadership & mentoring questions

**Время подготовки:** 2-3 недели перед собеседованием

---

## СТРАТЕГИЯ ПОДГОТОВКИ

### За 1 месяц до интервью:
- [ ] Пройти все базовые вопросы (500+)
- [ ] Решить 20 LeetCode задач
- [ ] Повторить main concepts 3 раза
- [ ] Записать трудные темы

### За 2 недели до интервью:
- [ ] Пройти Advanced вопросы вашего уровня
- [ ] Решить 30 LeetCode задач
- [ ] Практиковать verbal explanation
- [ ] Изучить документацию последних версий

### За 1 неделю до интервью:
- [ ] Повторить наиболее сложные темы
- [ ] Решить 40+ LeetCode задач
- [ ] Practice с другом/коллегой
- [ ] Спать хорошо каждую ночь

### За 1 день до интервью:
- [ ] Повторить 10 главных концепций
- [ ] Выспаться хорошо
- [ ] Подготовить примеры из реальных проектов
- [ ] Избежать "последней минуты" паники

---

## СОВЕТЫ ПО ОТВЕТАМ НА СОБЕСЕДОВАНИИ

✅ **DO:**
- Думайте вслух
- Структурируйте ответ: что это, зачем, как использовать, примеры
- Приводите примеры кода
- Обсуждайте advantages/disadvantages
- Связывайте вопросы с реальными проектами
- Признавайте, если чего-то не знаете
- Уточняйте вопрос, если не понимаете

❌ **DON'T:**
- Не давайте слишком короткие ответы
- Не придумывайте информацию
- Не перебивайте интервьюера
- Не отвлекайтесь от вопроса
- Не паникуйте, если не знаете ответ
- Не забывайте о soft skills

---

**Версия:** 2.0 (Расширенная)  
**Дата обновления:** Январь 2026  
**Статус:** Полный и актуальный для 2025-2026 года

**Удачи на собеседованиях! 🚀**
1171. Что такое configuration refresh?
1172. Как использовать @RefreshScope?
1173. Что такое resilience4j?
1174. Как использовать resilience4j?
1175. Что такое event-driven microservices?
1176. Как организовать communication между microservices?
1177. Что такое eventual consistency?
1178. Как обрабатывать eventual consistency?
1179. Что такое API versioning?
1180. Какие стратегии API versioning есть?
1181. Что такое backward compatibility?
1182. Как обеспечить backward compatibility?
1183. Что такое blue-green deployment?
1184. Что такое canary deployment?
1185. Как реализовать blue-green deployment?

### Advanced Kafka (50 вопросов)

1221. Что такое Kafka?
1222. Как работает Kafka?
1223. Что такое Kafka topic?
1224. Что такое Kafka partition?
1225. Что такое Kafka broker?
1226. Что такое Kafka producer?
1227. Как конфигурировать Kafka producer?
1228. Что такое producer batch?
1229. Как работает message buffering?
1230. Что такое acks в producer?
1231. Какие значения acks есть?
1232. Что такое idempotent producer?
1233. Как использовать transactional producer?
1234. Что такое exactly-once semantics?
1235. Как обеспечить exactly-once delivery?
1236. Что такое Kafka consumer?
1237. Как конфигурировать Kafka consumer?
1238. Что такое consumer group?
1239. Как работает consumer group?
1240. Что такое consumer lag?
1241. Как мониторить consumer lag?
1242. Что такое auto-commit?
1243. Когда использовать manual commit?
1244. Что такое offset?
1245. Как управлять offsets?
1246. Что такое rebalancing?
1247. Когда происходит rebalancing?
1248. Как обрабатывать rebalancing?
1249. Что такое listener container?
1250. Как использовать KafkaListener?
1251. Что такое dead letter queue?
1252. Как использовать dead letter queue?
1253. Что такое Kafka Streams?
1254. Как использовать Kafka Streams?
1255. Что такое KStream?
1256. Что такое KTable?
1257. Что такое GlobalKTable?
1258. Что такое stateful operations?
1259. Как использовать aggregation?
1260. Как использовать joins в Kafka Streams?
1261. Что такое windowing?
1262. Как использовать tumbling window?
1263. Как использовать hopping window?
1264. Как использовать sliding window?
1265. Что такое session window?
1266. Как использовать session window?
1267. Что такое topology в Kafka Streams?
1268. Как создать собственную topology?
1269. Что такое interactive queries?
1270. Как использовать interactive queries?

### Advanced Testing (50 вопросов)

1271. Что такое test pyramid?
1272. Как структурировать тесты?
1273. Что такое unit test vs integration test?
1274. Что такое end-to-end (E2E) test?
1275. Что такое performance test?
1276. Что такое load test?
1277. Что такое stress test?
1278. Что такое spike test?
1279. Что такое soak test?
1280. Как использовать JUnit 5?
1281. Какие differences между JUnit 4 и JUnit 5?
1282. Что такое @Test аннотация?
1283. Что такое @BeforeEach vs @BeforeClass?
1284. Что такое @Nested?
1285. Что такое @ParameterizedTest?
1286. Как использовать @CsvSource?
1287. Как использовать @MethodSource?
1288. Что такое Mockito?
1289. Как использовать @Mock?
1290. Как использовать @InjectMocks?
1291. Как использовать when().thenReturn()?
1292. Как использовать verify()?
1293. Что такое argument captor?
1294. Как использовать ArgumentCaptor?
1295. Что такое spy vs mock?
1296. Когда использовать spy?
1297. Что такое TestContainers?
1298. Как использовать TestContainers для database testing?
1299. Что такое @SpringBootTest?
1300. Как использовать @WebMvcTest?
1301. Что такое @DataJpaTest?
1302. Как использовать @DataMongoTest?
1303. Что такое MockMvc?
1304. Как использовать MockMvc.perform()?
1305. Что такое RestAssured?
1306. Как использовать RestAssured для REST API testing?
1307. Что такое contract testing?
1308. Как использовать Pact для contract testing?
1309. Что такое mutation testing?
1310. Как использовать PIT для mutation testing?
1311. Что такое code coverage?
1312. Когда 100% code coverage это плохо?
1313. Как использовать JaCoCo для code coverage?
1314. Что такое BDD (Behavior Driven Development)?
1315. Как использовать Cucumber для BDD?
1316. Что такое Gherkin?
1317. Как писать Gherkin сценарии?
1318. Что такое TestFixture?
1319. Как использовать TestFixture?
1320. Что такое test data builder?

### Advanced Docker & Kubernetes (50 вопросов)

1321. Как создать Dockerfile для Java приложения?
1322. Какие best practices для Java Dockerfiles?
1323. Что такое multi-stage build?
1324. Как использовать multi-stage build?
1325. Что такое Java container limitations?
1326. Как установить JVM heap limits?
1327. Что такое image layers?
1328. Как оптимизировать image layers?
1329. Что такое Docker registry?
1330. Как использовать Docker registry?
1331. Что такое Docker Compose?
1332. Как использовать Docker Compose для многоконтейнерных приложений?
1333. Что такое Kubernetes?
1334. Как работает Kubernetes?
1335. Что такое Pod?
1336. Как создать Pod в Kubernetes?
1337. Что такое Deployment?
1338. Как создать Deployment?
1339. Что такое Service?
1340. Какие типы Service есть?
1341. Что такое ClusterIP?
1342. Что такое NodePort?
1343. Что такое LoadBalancer?
1344. Что такое Ingress?
1345. Как конфигурировать Ingress?
1346. Что такое ConfigMap?
1347. Как использовать ConfigMap?
1348. Что такое Secret?
1349. Как управлять Secrets?
1350. Что такое PersistentVolume?
1351. Что такое PersistentVolumeClaim?
1352. Как использовать persistent storage?
1353. Что такое StatefulSet?
1354. Когда использовать StatefulSet?
1355. Что такое DaemonSet?
1356. Когда использовать DaemonSet?
1357. Что такое Job?
1358. Когда использовать Job?
1359. Что такое CronJob?
1360. Как использовать CronJob?
1361. Что такое namespace?
1362. Как использовать namespace?
1363. Что такое RBAC (Role-Based Access Control)?
1364. Как конфигурировать RBAC?
1365. Что такое NetworkPolicy?
1366. Как конфигурировать NetworkPolicy?
1367. Что такое resource limits?
1368. Как установить resource limits?
1369. Что такое health checks?
1370. Как конфигурировать health checks?

### Scenario-Based Questions (20 вопросов)

1371. У вас есть slow query. Как вы оптимизируете её?
1372. У вас есть memory leak. Как вы её найдёте?
1373. У вас есть deadlock. Как вы её разрешите?
1374. Ваше приложение потребляет слишком много CPU. Что вы сделаете?
1375. Ваше приложение потребляет слишком много памяти. Как вы оптимизируете?
1376. Ваше приложение часто выбрасывает OutOfMemoryError. Что делать?
1377. Вы заметили, что потребление памяти растёт со временем. Как это диагностировать?
1378. Вы хотите улучшить response time приложения. С чего начать?
1379. Вы хотите масштабировать приложение горизонтально. Что нужно учесть?
1380. Вы вводите feature flag. Как это реализовать?
1381. У вас есть несинхронизированный доступ к shared mutable state. Как это исправить?
1382. Вы хотите добавить caching. Какую стратегию выбрать?
1383. Ваш cache становится inconsistent. Как это решить?
1384. Вы нужно обработать миллионы сообщений в день. Как архитектурировать систему?
1385. Вы нужно обеспечить high availability. Что нужно сделать?
1386. Вы нужно обеспечить disaster recovery. Как это спланировать?
1387. Вы нужно мигрировать данные между базами данных. Как это сделать без downtime?
1388. Вы нужно roll back production deployment. Как это сделать?
1389. Вы нужно добавить authentication в существующее приложение. Как это сделать?
1390. Вы нужно логировать sensitive data. Как это сделать безопасно?

### LeetCode-Style Coding Problems (50 задач)

1391. Two Sum (Easy)
1392. Add Two Numbers (Medium)
1393. Longest Substring Without Repeating Characters (Medium)
1394. Median of Two Sorted Arrays (Hard)
1395. Longest Palindromic Substring (Medium)
1396. ZigZag Conversion (Medium)
1397. Reverse Integer (Medium)
1398. String to Integer (Medium)
1399. Palindrome Number (Easy)
1400. Container With Most Water (Medium)
1401. Integer to Roman (Medium)
1402. Roman to Integer (Easy)
1403. Longest Common Prefix (Easy)
1404. 3Sum (Medium)
1405. 3Sum Closest (Medium)
1406. Letter Combinations of a Phone Number (Medium)
1407. 4Sum (Medium)
1408. Remove Nth Node From End of List (Medium)
1409. Valid Parentheses (Easy)
1410. Merge Two Sorted Lists (Easy)
1411. Generate Parentheses (Medium)
1412. Merge k Sorted Lists (Hard)
1413. Swap Nodes in Pairs (Medium)
1414. Reverse Nodes in k-Group (Hard)
1415. Remove Duplicates from Sorted Array (Easy)
1416. Remove Element (Easy)
1417. Implement strStr() (Easy)
1418. Divide Two Integers (Medium)
1419. Substring with Concatenation of All Words (Hard)
1420. Next Permutation (Medium)
1421. Longest Valid Parentheses (Hard)
1422. Search in Rotated Sorted Array (Medium)
1423. Search for a Range (Medium)
1424. Search Insert Position (Easy)
1425. Wildcard Matching (Hard)
1426. Regular Expression Matching (Hard)
1427. Trapping Rain Water (Hard)
1428. Jump Game II (Medium)
1429. Maximum Product Subarray (Medium)
1430. Rotate Image (Medium)
1431. Word Search (Medium)
1432. Minimum Window Substring (Hard)
1433. Largest Rectangle in Histogram (Hard)
1434. Maximal Rectangle (Hard)
1435. Partition List (Medium)
1436. Linked List Cycle (Easy)
1437. Linked List Cycle II (Medium)
1438. Reorder List (Medium)
1439. Binary Tree Level Order Traversal (Easy)
1440. Binary Tree Zigzag Level Order Traversal (Medium)

---

## ИТОГОВАЯ СТАТИСТИКА (Расширенная версия)

**Всего вопросов:** 1800+  
**Количество разделов:** 100+  
**Средняя сложность:** от Trainee до Senior

### Распределение по категориям:

| Категория | Кол-во вопросов |
|-----------|-----------------|
| Java Core | 280 |
| Collections | 120 |
| String/Enum/Lambda | 140 |
| Exceptions | 40 |
| Multithreading | 130 |
| Memory/GC | 70 |
| Spring | 200 |
| Hibernate/JPA | 80 |
| Databases | 100 |
| JDBC | 40 |
| Design Patterns | 80 |
| Microservices | 100 |
| Kafka | 100 |
| Docker/Kubernetes | 100 |
| Testing | 80 |
| AWS/Cloud | 50 |
| Scenario-based | 20 |
| Coding Problems | 100 |
| **ИТОГО** | **1800+** |

---

## РЕКОМЕНДАЦИИ ПО ИСПОЛЬЗОВАНИЮ

### Для Trainee (0-6 месяцев):
1. Раздел "Java Core — Базовый уровень" (250 вопросов)
2. Раздел "ООП" (40 вопросов)
3. Раздел "Collections Framework" (70 вопросов)
4. Раздел "Exceptions" (30 вопросов)
5. 20-30 простых LeetCode задач

**Время подготовки:** 2-3 месяца

### Для Junior (6-18 месяцев):
1. Все вопросы Trainee (базовый уровень)
2. Раздел "Java Core — Продвинутый уровень" (100 вопросов)
3. Раздел "Multithreading" (100+ вопросов)
4. Раздел "Spring Framework" (100+ вопросов)
5. Раздел "Databases & SQL" (100+ вопросов)
6. 30-50 средних LeetCode задач
7. Выборочно: Design Patterns, JDBC

**Время подготовки:** 3-4 месяца

### Для Middle (1.5-3 года):
1. Все вопросы Junior
2. Весь "Advanced Java Core" раздел (30 вопросов)
3. "Advanced Collections & Data Structures" (50 вопросов)
4. "Advanced Multithreading" (50 вопросов)
5. "Advanced Spring Framework" (50 вопросов)
6. "Advanced Microservices" (50 вопросов)
7. "Advanced Kafka" (50 вопросов)
8. "Advanced Testing" (50 вопросов)
9. 50+ LeetCode задач (Medium/Hard)
10. Scenario-based questions
11. System Design questions

**Время подготовки:** 4-6 недель перед собеседованием

### Для Senior (3+ года):
1. Все 1800+ вопросов
2. Глубокий анализ архитектурных решений
3. Real-world project scenarios
4. Performance optimization challenges
5. Leadership & mentoring questions

**Время подготовки:** 2-3 недели перед собеседованием

---

## СТРАТЕГИЯ ПОДГОТОВКИ

### За 1 месяц до интервью:
- [ ] Пройти все базовые вопросы (500+)
- [ ] Решить 20 LeetCode задач
- [ ] Повторить main concepts 3 раза
- [ ] Записать трудные темы

### За 2 недели до интервью:
- [ ] Пройти Advanced вопросы вашего уровня
- [ ] Решить 30 LeetCode задач
- [ ] Практиковать verbal explanation
- [ ] Изучить документацию последних версий

### За 1 неделю до интервью:
- [ ] Повторить наиболее сложные темы
- [ ] Решить 40+ LeetCode задач
- [ ] Practice с другом/коллегой
- [ ] Спать хорошо каждую ночь

### За 1 день до интервью:
- [ ] Повторить 10 главных концепций
- [ ] Выспаться хорошо
- [ ] Подготовить примеры из реальных проектов
- [ ] Избежать "последней минуты" паники

---

## СОВЕТЫ ПО ОТВЕТАМ НА СОБЕСЕДОВАНИИ

✅ **DO:**
- Думайте вслух
- Структурируйте ответ: что это, зачем, как использовать, примеры
- Приводите примеры кода
- Обсуждайте advantages/disadvantages
- Связывайте вопросы с реальными проектами
- Признавайте, если чего-то не знаете
- Уточняйте вопрос, если не понимаете

❌ **DON'T:**
- Не давайте слишком короткие ответы
- Не придумывайте информацию
- Не перебивайте интервьюера
- Не отвлекайтесь от вопроса
- Не паникуйте, если не знаете ответ
- Не забывайте о soft skills

---

**Версия:** 2.0 (Расширенная)  
**Дата обновления:** Январь 2026  
**Статус:** Полный и актуальный для 2025-2026 года

**Удачи на собеседованиях! 🚀**