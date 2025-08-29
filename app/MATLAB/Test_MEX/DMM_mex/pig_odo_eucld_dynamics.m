function x_next = pig_odo_eucld_dynamics(t,x,u,params)

    earth_gravity = 9.81; 
    east_radius_of_earth = 6378100; % equatorial (Wikipedia) 
    north_radius_of_earth = 6356800; % polar (Wikipedia) 
    manifld_factr_en = 1; % manifold is default 
    rotn_factr_en = 1; % earth rotation is default value 
    rot_rate_of_earth = 7.292115e-5; % radians per second [=7.292115e-5*180/pi*86400 = 360.9856] 
    odo_sel = 3; 
    
    % o <--x(1) | p <--x(2:4) | q <--x(5:8) | v <--x(9:11) | bs <--x(12:17) [+] imu_a <--u(1:3) | imu_w <--u(4:6)  
    prms = params; 
    dT = prms(7); 
    s = x(1); p = x(2:4); q = x(5:8); v_odo_inertial_prev = x(9:11); 
    bs = x(12:17); 
    v_odos = u(1:3); imu_w = u(4:6); 
    
    C_nb = quat2rotm(q'); 
    % C_nb = [-0.999487613146384,0.029287284528011,-0.011579364117620;-0.029993627022430,-0.771198451711062,0.635845821441784;0.009692736486792,0.635867574759681,0.771681529525928]; 
    % disp(quat2rotm(q_gen')-C_nb)
    gl = [0;0;-9.81]; 
    
    v_odo_current = prms(8)*v_odos(odo_sel); 
    v_odo_inertial = C_nb*[v_odo_current;0;0]; % 
    G_func = [180*v_odo_inertial(1)/(pi*(north_radius_of_earth+p(3)));...
        -180*v_odo_inertial(2)/(pi*(east_radius_of_earth+p(3))*cosd(p(1)));v_odo_inertial(3)]; 
    w_b = prms(4:6).*imu_w + bs(4:6); 
    Qx = 0.5*[0,      -w_b(1), -w_b(2), -w_b(3);...
              w_b(1),  0,       w_b(3), -w_b(2);...
              w_b(2), -w_b(3),  0,       w_b(1);...
              w_b(3),  w_b(2), -w_b(1),  0]; 
    q_gen = expm(Qx*dT)*q; 
    
    f_s = s + dT*v_odo_current; 
    f_p = p + dT*G_func;
    f_q = q_gen; % [not needed] /norm(q_gen(q,bs,imu_w)); 
    f_v = v_odo_inertial; 
    
    f = [zeros(11,1);x(12:17,1)]; 
    g = [f_s;f_p;f_q;f_v;zeros(6,1)]; 
    x_next = f + g;
    
    end 