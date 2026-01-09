@isTest
public class GameCoinTest {

    @isTest
    public static void testAbsorbCoin() {
        // Create an instance of the BlueCoin
        BlueCoin blueCoin = new BlueCoin();

        // Call the absorbCoin method and pass an existing point
        Integer existingPoints = 100;
        Integer newPoints = blueCoin.absorbCoin(existingPoints);

        // Verify that the newPoints are updated correctly
        Integer expectedPoints = existingPoints + blueCoin.coinValue();
        System.assertEquals(expectedPoints, newPoints, 'AbsorbCoin method did not update points correctly.');
    }
}