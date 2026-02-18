[[Программирование/Java/JavaBasics/Fundamentals/Java]]
1. Field.
```
	class Employee
{
private static int nextId = 1;
private int id;
. . .
}
```
Every Employee object now has its own id field, but there is only one nextId field
that is shared among all instances of the class. Let’s put it another way. If
there are 1,000 objects of the Employee class, then there are 1,000 instance fields
id, one for each object. But there is a single static field nextId. Even if there
are no Employee objects, the static field nextId is present. It belongs to the class,
not to any individual object.
2. Method.
	A static method  does not operate on an object. However, a static method can access a
static field.