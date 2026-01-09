public class Util 
{
    public void changeNumber(Decimal d)
    {
        d += 10;
        system.debug('decimal in method:'+d);
    }
     
    public void changeString(String s) 
    {
        s = s + 'Hello';  
        system.debug('String in method:'+s);
    }
     
    public void changeObject(Commodity__c c)
    {
        c.price__c += 20;
    }
}