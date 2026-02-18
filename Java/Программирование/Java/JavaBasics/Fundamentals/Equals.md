[[Программирование/Java/JavaBasics/Fundamentals/Java]]
public boolean equals(Object otherObject)
{
// a quick test to see if the objects are identical
if (this == otherObject) return true;
// must return false if the explicit parameter is null
if (otherObject == null) return false;
// if the classes don't match, they can't be equal
if (getClass() != otherObject.getClass())
return false;
Employee other = (Employee) otherObject;
// test whether the fields have identical values
return name.equals(other.name)
&& salary == other.salary
&& hireDay.equals(other.hireDay);
}