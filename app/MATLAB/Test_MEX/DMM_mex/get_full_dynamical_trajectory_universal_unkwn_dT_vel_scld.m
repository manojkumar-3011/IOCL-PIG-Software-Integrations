function [q_dot,q,v_dot,v,p_gen,odo_gen,acc_ef] = ...
    get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld(...
    new_agb_j,indices,g_all,w_all,downsampling,start_gps,...
    best_initial_orientation) 

    earth_gravity = 9.81; 
%     east_radius_of_earth = 6378100; % equatorial (Wikipedia) 
%     north_radius_of_earth = 6356800; % polar (Wikipedia) 
%     manifld_factr_en = 1; % manifold is default 
%     rotn_factr_en = 1; % earth rotation is default value 
    rot_rate_of_earth = 7.292115e-5; % radians per second [=7.292115e-5*180/pi*86400 = 360.9856] 

    % 
    % vel_odo_gain = new_agb_j(1);
    vel_odo_gain = 1.0; % nov 6 change 
    % acc_gain_mat = diag(agb_now(2:4)); 
    acc_bias = new_agb_j(5:7); 
    % gyro_gain_mat = diag(agb_now(8:10)); 
    gyro_bias = new_agb_j(11:13); 
    params = [new_agb_j([2:4,8:10]);new_agb_j(21)*downsampling/10;vel_odo_gain]; 
    q0 = best_initial_orientation + new_agb_j(14:17); 
    % q0 = rotm2quat(rotx(start_gps(2))*roty(start_gps(1))*quat2rotm(best_initial_orientation'))'...
    %      + new_agb_j(14:17); 
    v0 = new_agb_j(18:20); 
    dT = new_agb_j(21)*(indices(2)-indices(1))*downsampling/10; 
    % 
    noindices = length(indices); 
    % 
    q_dot = zeros(4,noindices); 
    q = zeros(4,noindices); 
    v_dot = zeros(3,noindices); 
    v = zeros(3,noindices); 
    p_gen = zeros(3,noindices); 
    odo_gen = zeros(1,noindices); 
    acc_ef = zeros(3,noindices); 
    q(:,1) = q0; % <-- normalized later 
    v(:,1) = v0; % 
    p_gen(:,1) = start_gps'; 
    % 
    acc_ef(:,1) = quat2rotm(q0')*[0;0;9.81];  
    for ix=2:noindices 
        new_q = q(:,ix-1); 
        new_q = new_q/norm(new_q); 
        % dT = obj.downsampling*(indices(ix)-indices(ix-1))/obj.sampling_frequency; 
        t = dT*(ix-2); 
        % 
        x = [odo_gen(:,ix-1);p_gen(:,ix-1);new_q;v(:,ix-1);acc_bias;gyro_bias]; 
        u = [g_all(:,ix-1);w_all(:,ix-1)]; 
        x = pig_odo_eucld_dynamics(t,x,u,params); 
        odo_gen(:,ix) = x(1); p_gen(:,ix) = x(2:4); q(:,ix) = x(5:8); v(:,ix) = x(9:11); 
        % 
        q_dot(:,ix) = (q(:,ix) - q(:,ix-1))/dT; 
        v_dot(:,ix) = (v(:,ix) - v(:,ix-1))/dT; 
        t_now = dT*(ix-1); p_now = p_gen(:,ix); q_now = q(:,ix); %v_now = v(:,ix); 
        % C_nb = roty(-p_now(1))*rotx(-p_now(2))...
        %     *rotx(-t_now*rot_rate_of_earth*180/pi)*quat2rotm(q_now'); % eul2rotm(flip(omega_ie(p)')*t)
        % acc_ef(:,ix) = transpose(C_nb)...
        %     *[0;0;earth_gravity]; 
        acc_ef(:,ix) = quat2rotm(q(:,ix)')'*[0;0;9.81]; 
    end 
    % odo_gen = odo_gain*dT*cumsum(sqrt(sum(v.*v,1))); 
end 