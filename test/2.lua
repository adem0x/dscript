add2 = function()
var i = 100;
function add(c)
i = c+ i;
return i;
end;
return add;
end;
c= add2();
write c(1);
write c(1);
