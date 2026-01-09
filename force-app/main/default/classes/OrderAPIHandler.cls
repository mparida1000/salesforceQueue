public class OrderAPIHandler {
    // Callout method
    public static Response sendOrderToAPI(OrderData order) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:IMS/SendOrder'); // Using Named Credential
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(order));
        
        Http http = new Http();
        try {
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                return (Response)JSON.deserialize(res.getBody(), Response.class);
            } else {
                // Handle API errors
                ErrorResponse error = (ErrorResponse)JSON.deserialize(res.getBody(), ErrorResponse.class);
                throw new CalloutException(
                    'API Error: ' + error.message + 
                    ' (Code: ' + error.errorCode + ')'
                );
            }
        } catch (Exception e) {
            throw new CalloutException('Callout failed: ' + e.getMessage());
        }
    }
    
    // Wrapper classes
    public class OrderData {
        public String orderName;
        public String orderNumber;
        public String orderStartDate;
        public String status;
        public String customerId;
        public String orderAddress;
        public String shippingAddress;
        public Decimal amount;
        
        // Constructor for easy initialization
        public OrderData(String name, String ordernumber, String custId, Decimal amt) {
            this.orderName = name;
            this.orderNumber = ordernumber;
            this.customerId = custId;
            this.amount = amt;
            this.status = 'Draft';
            this.orderStartDate = System.today().format();
        }
    }
    
    public class Response {
        public Boolean success;
        public String message;
        public String orderNumber;
        public String status;
        public Decimal amount;
        public String timestamp;
    }
    
    public class ErrorResponse {
        public Boolean success;
        public String errorCode;
        public String message;
    }
}