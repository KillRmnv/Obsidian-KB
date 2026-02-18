File file=new File("adsafs.txt");
file.createNewFile():bool
file.delete()
### 1. Byte Streams

In Java, Byte Streams are used to handle raw binary data such as images, audio files, videos or any non-text file. They work with data in the form of 8-bit bytes.
The two main abstract classes for byte streams are:

- ****InputStream:**** for reading data (input)
- ****OutputStream:**** for writing data (output)

Since abstract classes cannot be used directly, we use their implementation classes to perform actual I/O operations.

- ****FileInputStream:**** reads raw bytes from a file.
- ****FileOutputStream:**** writes raw bytes to a file.
- ****BufferedInputStream / BufferedOutputStream:**** use buffering for faster performance.
- ****ByteArrayInputStream:**** reads data from a byte array as if it were an input stream.
- ****ByteArrayOutputStream:**** writes data into a byte array, which grows automatically.
### 2. Character Streams

In Java, Character Streams are used to handle text data. They work with 16-bit Unicode characters, making them suitable for international text and language support.
The two main abstract classes for character streams are:

- Reader: Base class for all character-based input streams (reading).
- Writer: Base class for all character-based output streams (writing).

Since abstract classes cannot be used directly, we use their implementation classes to perform actual I/O operations.

- ****FileReader:**** reads characters from a file.
- ****FileWriter:**** writes characters to a file.
- ****BufferedReader:**** reads text efficiently using buffering; also provides readLine() for reading lines.
- ****BufferedWriter:**** writes text efficiently using buffering.
- ****StringReader:**** reads characters from a string.
- ****StringWriter:**** writes characters into a string buffer.