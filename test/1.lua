
for j = 1, 10 do f[j]= j; end;
function quicksort(m,n)
if n<=m then return; end;
i = m-1;
j = n;
v = a[n];
while 1=1 do
 while a[i] < v do i = i + 1; end;
 while a[j] > v do j = j - 1; end;
 if i>= j then break; end;
 x = a[i];
 a[i] = a[j];
 a[j] = x;
 end;
 x = a[i];
 a[i] = a[n]
 a[n] = x;
 quicksort(m,j);
 quicksort(i + 1, n)
end;
end;
