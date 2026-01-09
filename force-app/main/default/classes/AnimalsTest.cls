@isTest
public class AnimalsTest {
	@isTest
    static void testAnimals(){
        Test.setMock(HttpCalloutMock.class, new AnimalsCalloutMock());
        
        HttpResponse res = Animals.animals();
        String expected = '{"Animals":["Horse","Dog","Tiger","Lion","Cat","Mouse"]}' ;
        
        System.assertEquals(200,res.getStatusCode());
        System.assertEquals(res.getBody(), expected);
    }
}