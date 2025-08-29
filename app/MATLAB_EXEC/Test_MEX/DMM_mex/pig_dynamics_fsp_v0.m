function x_next = pig_dynamics(t,x,u,params)

earth_gravity = 9.81; 
east_radius_of_earth = 6378100; % equatorial (Wikipedia) 
north_radius_of_earth = 6356800; % polar (Wikipedia) 
manifld_factr_en = 1; % manifold is default 
rotn_factr_en = 1; % earth rotation is default value 
rot_rate_of_earth = 7.292115e-5; % radians per second [=7.292115e-5*180/pi*86400 = 360.9856] 

% o <--x(1) | p <--x(2:4) | q <--x(5:8) | v <--x(9:11) | bs <--x(12:17) [+] imu_a <--u(1:3) | imu_w <--u(4:6)  
prms = params; 
dT = prms(7); 
s = x(1); p = x(2:4); q = x(5:8); v = x(9:11); 
bs = x(12:17); 
imu_a = u(1:3); imu_w = u(4:6); 
v_scl = prms(8)*v; 

G_func = [180*v_scl(1)/(pi*(north_radius_of_earth+p(3)));...
    -180*v_scl(2)/(pi*(east_radius_of_earth+p(3))*cosd(p(1)));v_scl(3)]; 
w_b = prms(4:6).*imu_w + bs(4:6); 
Qx = 0.5*[0,-w_b(1),-w_b(2),-w_b(3);w_b(1),0,w_b(3),-w_b(2);w_b(2),-w_b(3),0,w_b(1);w_b(3),w_b(2),-w_b(1),0]; 
q_gen = expm(Qx*dT)*q; 

n_omega_ie = rotn_factr_en*[rot_rate_of_earth*cosd(p(1));0;rot_rate_of_earth*sind(p(1))]; 
n_omega_en = manifld_factr_en*[-v(2)/((east_radius_of_earth+p(3)));v(1)/(north_radius_of_earth+p(3));-v(2)*tand(p(1))/(east_radius_of_earth+p(3))]; 
w = 2*n_omega_ie+n_omega_en; 
Sx_w = [0,-w(3),w(2);w(3),0,-w(1);-w(2),w(1),0]; 
Sx_n_omega_ie = [0,-n_omega_ie(3),n_omega_ie(2);n_omega_ie(3),0,-n_omega_ie(1);...
    -n_omega_ie(2),n_omega_ie(1),0]; 
gl = -Sx_n_omega_ie*Sx_n_omega_ie*[0;0;(east_radius_of_earth+p(3))]+[0;0;-earth_gravity]; 
C_nb = roty(-p(1))*rotx(-p(2))...
    *rotx(-t*rot_rate_of_earth*180/pi)*quat2rotm(q'); % eul2rotm(flip(omega_ie(p)')*t)
f_s = s + dT*norm(v_scl); 
f_p = p + dT*G_func;
f_q = q_gen; % [not needed] /norm(q_gen(q,bs,imu_w)); 
f_v = v + dT*(C_nb*(prms(1:3).*imu_a + bs(1:3))...
    -Sx_w*v+gl); 

f = [zeros(11,1);x(12:17,1)]; 
g = [f_s;f_p;f_q;f_v;zeros(6,1)]; 
x_next = f + g;

end 
