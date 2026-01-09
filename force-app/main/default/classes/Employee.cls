public class Employee implements Comparable {
    public String name { get; set; }
    public Integer age { get; set; }
    public Date DOJ { get; set; }
    public Decimal salary { get; set; }
    
    // Constructor to initialize the Employee object
    public Employee(String name, Integer age, Date DOJ, Decimal salary) {
        this.name = name;
        this.age = age;
        this.DOJ = DOJ;
        this.salary = salary;
    }
    
    // Implementing the compareTo method from the Comparable interface
    public Integer compareTo(Object obj) {
        Employee other = (Employee) obj;
        
        // First compare by name
        Integer nameResult = this.name.compareTo(other.name);
        if (nameResult != 0) {
            return nameResult;
        }
        
        // If names are the same, compare by age
        Integer ageResult = this.age - other.age; // Using subtraction for integer comparison
        if (ageResult != 0) {
            return ageResult;
        }
        
        // If ages are the same, compare by date of joining using daysBetween
        Integer dojResult = this.DOJ.daysBetween(other.DOJ);
        if (dojResult != 0) {
            return dojResult;
        }
        
        // If all else is equal, consider them equal
        return 0;
    }
}