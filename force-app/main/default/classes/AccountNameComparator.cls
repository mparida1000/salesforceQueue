public class AccountNameComparator extends Comparator {
    public override Integer compare(Object a, Object b) {
System.debug('Test der142SSSd4AAA');
        return ((Account)a).NaicsDesc.compareTo(((Account)b).NaicsDesc);
    }
}
