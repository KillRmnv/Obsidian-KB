****1. ByteStream****:

Byte streams in Java are used to perform input and output of 8-bit bytes. They are suitable for handling raw binary data such as images, audio, and video, using classes like InputStream and OutputStream.

Here is the list of various ByteStream Classes:

| Stream class                                                                                        | Description                                                |
| --------------------------------------------------------------------------------------------------- | ---------------------------------------------------------- |
| [BufferedInputStream](https://www.geeksforgeeks.org/java/java-io-bufferedinputstream-class-java/)   | Used to read data more efficiently with buffering.         |
| [DataInputStream](https://www.geeksforgeeks.org/java/java-io-datainputstream-class-java-set-1/)     | Provides methods to read Java primitive data types.        |
| [FileInputStream](https://www.geeksforgeeks.org/java/java-io-fileinputstream-class-java/)           | This is used to read from a file.                          |
| [InputStream](https://www.geeksforgeeks.org/java/java-io-inputstream-class-in-java/)                | This is an abstract class that describes stream input.     |
| [PrintStream](https://www.geeksforgeeks.org/java/java-io-printstream-class-java-set-1/)             | This contains the most used print() and println() method   |
| [BufferedOutputStream](https://www.geeksforgeeks.org/java/java-io-bufferedoutputstream-class-java/) | This is used for Buffered Output Stream.                   |
| [DataOutputStream](https://www.geeksforgeeks.org/java/dataoutputstream-in-java/)                    | This contains method for writing java standard data types. |
| [FileOutputStream](https://www.geeksforgeeks.org/java/creating-a-file-using-fileoutputstream/)      | This is used to write to a file.                           |
| [OutputStream](https://www.geeksforgeeks.org/java/java-io-outputstream-class-java/)                 | This is an abstract class that describes stream output.    |
|                                                                                                     |                                                            |
|                                                                                                     |                                                            |
****2. CharacterStream:****

Character streams in Java are used to perform input and output of 16-bit Unicode characters. They are best suited for handling text data, using classes like Reader and Writer which automatically handle character encoding and decoding.

Here is the list of various CharacterStream Classes:

| Stream class                                                                                     | Description                                                    |
| ------------------------------------------------------------------------------------------------ | -------------------------------------------------------------- |
| [BufferedReader](https://www.geeksforgeeks.org/java/java-io-bufferedreader-class-java/)          | It is used to handle buffered input stream.                    |
| [FileReader](https://www.geeksforgeeks.org/java/file-handling-java-using-filewriter-filereader/) | This is an input stream that reads from file.                  |
| [InputStreamReader](https://www.geeksforgeeks.org/java/inputstreamreader-class-in-java/)         | This input stream is used to translate byte to character.      |
| OutputStreamWriter                                                                               | Converts character stream to byte stream.                      |
| [Reader](https://www.geeksforgeeks.org/java/java-io-reader-class-java/)                          | This is an abstract class that define character stream input.  |
| [PrintWriter](https://www.geeksforgeeks.org/java/java-io-printwriter-class-java-set-1/)          | This contains the most used print() and println() method       |
| [Writer](https://www.geeksforgeeks.org/java/java-io-writer-class-java/)                          | This is an abstract class that define character stream output. |
| [BufferedWriter](https://www.geeksforgeeks.org/java/io-bufferedwriter-class-methods-java/)       | This is used to handle buffered output stream.                 |
| [FileWriter](https://www.geeksforgeeks.org/java/file-handling-java-using-filewriter-filereader/) | This is used to output stream that writes to file.             |