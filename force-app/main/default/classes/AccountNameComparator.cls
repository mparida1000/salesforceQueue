public class AccountNameComparator extends Comparator {
    public override Integer compare(Object a, Object b) {
System.debug('tiger1122');
        return ((Account)a).NaicsDesc.compareTo(((Account)b).NaicsDesc);
    }
}
