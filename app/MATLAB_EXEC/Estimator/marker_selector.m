function op = marker_selector(varargin) 

spread = 0; 

if nargin==1 
    [marker_array] = varargin{:}; 
elseif nargin==2 
    [marker_array,spread] = varargin{:}; 
end 

nomrkr = length(marker_array); 
op = [marker_array(1)*ones(1,spread+1),kron(marker_array(2:end-1),ones(1,2*spread+1)),...
    marker_array(end)*ones(1,spread+1)] ...
    + [0:spread,repmat(-spread:spread,1,nomrkr-2),-spread:0]; 

save cstm_marker_selection op 

end 