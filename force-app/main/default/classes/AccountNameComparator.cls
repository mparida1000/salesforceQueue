public class AccountNameComparator extends Comparator {
    public override Integer compare(Object a, Object b) {
System.debug('Test der12');
        return ((Account)a).NaicsDesc.compareTo(((Account)b).NaicsDesc);
    }
}
