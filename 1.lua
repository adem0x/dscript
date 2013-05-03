f = nil;
for j = 1, 10 do
	f = {i = j; next = f};
end;
for j = 1, 10 do
	print(f.i);
f = f.next;
end;
