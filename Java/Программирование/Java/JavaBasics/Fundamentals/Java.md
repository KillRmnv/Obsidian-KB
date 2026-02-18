 строго типизированный объектно-ориентированный язык программирования
 ## [[JDK]] vs [[JRE]] vs [[JVM]]

|Aspect|JDK|JRE|JVM|
|---|---|---|---|
|Purpose|Used to develop Java applications|Used to run Java applications|Executes Java bytecode|
|Platform Dependency|Platform-dependent (OS specific)|Platform-dependent (OS specific)|JVM is OS-specific, but bytecode is platform-independent|
|Includes|JRE + Development tools (javac, debugger, etc.)|JVM + Libraries (e.g., rt.jar)|ClassLoader, JIT Compiler, Garbage Collector|
|Use Case|Writing and compiling Java code|Running a Java application on a system|Convert bytecode into native machine code|