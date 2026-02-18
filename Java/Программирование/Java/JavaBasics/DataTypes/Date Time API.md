[[Программирование/Java/JavaBasics/Fundamentals/Java]]
![[Pasted image 20260112000142.png]]
![[Pasted image 20260112000240.png]]
![[Pasted image 20260111235650.png]]
![[Pasted image 20260111235944.png]]
![[Pasted image 20260111235627.png]]

```
`import java.time.*;`

`public class CalendarTest`
`{`
`public static void main(String[] args)`
`{`
`LocalDate date = LocalDate.now();`
`int month = date.getMonthValue();`
`int today = date.getDayOfMonth();`
`date = date.minusDays(today - 1); // set to start of month`
`DayOfWeek weekday = date.getDayOfWeek();`
`int value = weekday.getValue(); // 1 = Monday, . . . , 7 = Sunday`
`System.out.println("Mon Tue Wed Thu Fri Sat Sun");`
`for (int i = 1; i < value; i++)`
`System.out.print("`
`");`
`while (date.getMonthValue() == month)`
`{`
`System.out.printf("%3d", date.getDayOfMonth());`
`if (date.getDayOfMonth() == today)`
`System.out.print("*");`
`else`
`System.out.print(" ");`
`date = date.plusDays(1);`
`if (date.getDayOfWeek().getValue() == 1) System.out.println();`
`}`
`if (date.getDayOfWeek().getValue() != 1) System.out.println();`
`}`
`}`

• static LocalDate now()
constructs an object that represents the current date.
• static LocalDate of(int year, int month, int day)
constructs an object that represents the given date.
• int getYear()
• int getMonthValue()
• int getDayOfMonth()
gets the year, month, and day of this date.
• DayOfWeek getDayOfWeek
gets the weekday of this date as an instance of the DayOfWeek class. Call getValue
to get a weekday between 1 (Monday) and 7 (Sunday).
• LocalDate plusDays(int n)
• LocalDate minusDays(int n)
yields the date that is n days after or before this date.

