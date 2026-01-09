public class CustomObject implements Comparable{

    public Integer field1;
    public Integer field2;

    public CustomObject(Integer field1, Integer field2) {
        this.field1 = field1;
        this.field2 = field2;
    }

    // Implement the compareTo method to define sorting logic
    public Integer compareTo(Object other) {
        CustomObject otherObject = (CustomObject)other;

        // Sort first by field1
        if (this.field1 != otherObject.field1) {
            return this.field1 - otherObject.field1;
        }

        // If field1 is equal, sort by field2
        return this.field2 - otherObject.field2;
    }
}