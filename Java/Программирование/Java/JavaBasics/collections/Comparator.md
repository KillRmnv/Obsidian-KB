![[Pasted image 20260113140420.png]]

The Comparator interface in Java is used to sort the objects of user-defined classes.
class SortbyRoll implements Comparator<Student> 
{    
  	// Compare by roll number in ascending order
    public int compare(Student a, Student b) {
        return a.rollno - b.rollno;
    }
}
