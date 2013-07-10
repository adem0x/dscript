{计算裴波那契数列前46位，算10次}
i=10;
while i <> 0 do
	k=46;
	a=1;
	b=1;
	while k <> 0 do
		write a;
		c=b;
		b=a+b;
		a=c;
		k=k-1;
	end;
	i=i-1;
end;
