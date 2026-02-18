[[Программирование/Java/JavaBasics/Fundamentals/Java]]

![[Pasted image 20260113204123.png]]
/**
* A {@code Card} object represents a playing card, such
* as "Queen of Hearts". A card has a suit (Diamond, Heart,
* Spade or Club) and a value (1 = Ace, 2 . . . 10, 11 = Jack,
* 12 = Queen, 13 = King)
*/
public class Card
{
. . .
}


/**
* Raises the salary of an employee.
* @param byPercent the percentage by which to raise the salary (e.g., 10 means 10%)
* @return the amount of the raise
*/
public double raiseSalary(double byPercent)
{
double raise = salary * byPercent / 100;
salary += raise;
return raise;
}

@throws class description

@author name

@since *Text*
The text can be any description of
the version that introduced this feature. For example, @since 1.7.1.\

The tag @see reference adds a hyperlink in the “see also” section.



[[Package documentation]]
1. Supply a Java file named package-info.java. The file must contain an initial
Javadoc comment, delimited with /** and */, followed by a package
statement. It should contain no further code or comments.
2. Supply an HTML file named package.html. All text between the tags
<body>. . .</body> is extracted.


1.Change to the directory that contains the source files you want to docu-
ment. If you have nested packages to document, such as com.horstmann
.corejava, you must be working in the directory that contains the subdirec-
tory com. (This is the directory that contains the overview.html file, if you
supplied one.)
2.Run the command
javadoc -d docDirectory nameOfPackage
for a single package. Or, run
javadoc -d docDirectory nameOfPackage1 nameOfPackage2. . .