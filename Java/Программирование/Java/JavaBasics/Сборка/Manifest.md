[[Программирование/Java/JavaBasics/Fundamentals/Java]]  [[JAR Files]]
In addition to class files, images, and other resources, each JAR file contains
a manifest file that describes special features of the archive.
The manifest file is called MANIFEST.MF and is located in a special META-INF sub-
directory of the JAR file.

The manifest entries are
grouped into sections. The first section in the manifest is called the main sec-
tion. It applies to the whole JAR file. Subsequent entries can specify properties
of named entities such as individual files, packages, or URLs. Those entries
must begin with a Name entry. Sections are separated by blank lines. For
example:
Manifest-Version: 1.0
lines describing this archive
Name: Woozle.class
lines describing this file
Name: com/mycompany/mypkg/
lines describing this package
To edit the manifest, place the lines that you want to add to the manifest
into a text file. Then run
jar cfm jarFileName manifestFileName . . .