% input
switch choice 
    case 1 
        addpath('DMM_mex/')
        load input_pig_dynamics
        
        load input_main.mat
        [new_agb_j,epsilon,indices,g_all,w_all,~,~,C_nb] = varargin{2:end}; 
        downsampling = 1000; start_gps = [23.9336 72.3604 87]; 
        best_initial_orientation = [3.2135,1.2805,-0.0458,-0.0137]'; 
        earth_gravity = 9.81; 
    case 2 
        load input_main2.mat
        [new_agb_j,indices,g_all,w_all,downsampling,start_gps,...
            best_initial_orientation] = inputs{:}; 
end 