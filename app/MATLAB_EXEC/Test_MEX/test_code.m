function c = test_code()
% to mex 

n = 4; 
c = zeros(n);
d = [1,2,3,4;2,3,4,1;3,4,1,2;4,1,2,3]; 
e = d/sum(d(:,1))^2; 
for i=1:100000
    c = c + e^i; 
end 

end