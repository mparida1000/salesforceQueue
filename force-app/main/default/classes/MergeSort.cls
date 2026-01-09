public class MergeSort {
    
    public static integer [] b;

    public void mergeSort(integer l, integer r, integer [] arr){
        if(l < r){
            integer mid = (l+r)/2;
            mergeSort(l, mid, arr);
            mergeSort(mid+1, r, arr);
            mergeArr(l, r, mid, arr);
        }
    }

    public void mergeArr (integer l, integer r, integer mid, integer [] arr){
        integer k = l;
        integer i = l;
        integer j = mid+1;

        while(i <= mid && j <= r){
            if(arr[i] < arr[j]){
                b[k++] = arr[i++];
            }else{
                b[k++] = arr[j++];
            }
        }
        if(i > mid){
            while(j<=r) b[k++] = arr[j++];
        }else{
            while(i<=mid) b[k++] = arr[i++];
        }
        for(k = l ; k <=r ; k++){
            arr[k] = b[k];
        }
    }
}