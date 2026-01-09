@isTest
public class TestUtil {
    
	@isTest
  	static void testTaskPriority() {
    	String sub = 'abcde'.substring(2);
		Assert.areEqual('cde', sub, 'Expected characters after first two'); // Succeeds
  	}
}