[[Программирование/Java/JavaBasics/Fundamentals/Java]]
When you package your application, you want to give your users a single
file, not a directory structure filled with class files. Java Archive (JAR) files
were designed for this purpose. A JAR file can contain both class files and
other file types such as image and sound files. Moreover, JAR files are
compressed, using the familiar ZIP compression format.

jar cvf *jarFileName*  *options*  file1 file2 . . .