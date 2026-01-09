public with sharing class SortLinkedList {
    public Node sortList(Node A){
        if(A == null || A.next == null) return A;
        Node middle = findMiddle(A);
        Node nextOfMiddle = middle.next;
        middle.next = null;
        Node left = sortList(middle);
        Node right = sortList(nextOfMiddle);
        return mergeNodes(left, right);
    }

    public Node findMiddle(Node A){
        if(A == null) return null;
        Node sp = A;
        Node fp = A;
        while(fp.next != null && fp.next.next != null){
            sp = sp.next;
            fp = fp.next;
        }
        return sp;
    }

    public Node mergeNodes (Node l, Node r){
        return null;
    }
}