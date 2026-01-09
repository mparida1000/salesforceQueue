public class DataWrapper {
    public List<String> month { get; set; }
    public List<Integer> sales { get; set; }
    public List<Integer> redemption { get; set; }

    // Constructor
    public DataWrapper() {
        this.month = new List<String>();
        this.sales = new List<Integer>();
        this.redemption = new List<Integer>();
    }

    // Deserialize method to parse JSON string into DataWrapper instance
   

    // Method to serialize DataWrapper instance back to JSON
    public String toJson() {
        return JSON.serialize(this);
    }
}