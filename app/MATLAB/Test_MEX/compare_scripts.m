%% test_code
tic 
test_code(); 
time_for_m_code = toc; 
disp(['Time taken for m-script: ', num2str(time_for_m_code)])

tic 
test_code_mex();
time_for_mex_code = toc; 
disp(['Time for mex-code: ', num2str(time_for_mex_code)])

%% get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld
choice = 1; dmm_inputs_etc

disp(' '); disp(' ')
disp('Function: pig_dynamics(t,x,u,params)')
tic 
% test_code(); 
out1 = pig_dynamics(t,x,u,params); 
out2 = pig_dynamics_benchmark(t,x,u,params); 
disp(['Error check - difference in output vs benchmark: ', num2str(norm(out1-out2))])
tic 
out1 = pig_dynamics(t,x,u,params); 
time_for_m_code = toc; 
disp(['Time taken for m-script: ', num2str(time_for_m_code)])
tic 
out2 = pig_dynamics_mex(t,x,u,params); 
time_for_mex_code = toc; 
disp(['Time for mex-code: ', num2str(time_for_mex_code)])
disp(['Error check - difference in output: ', num2str(norm(out1-out2))])

disp(' '); disp(' ')
disp('Function: get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld(t,x,u,params)')
tic 
test_code(); 
[q_dot,q,v_dot,v,p_gen,odo_gen,acc_ef] = ...
    get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld(new_agb_j,...
    indices,g_all,w_all,downsampling,start_gps,...
    best_initial_orientation); 
time_for_m_code = toc; 
disp(['Time taken for m-script: ', num2str(time_for_m_code)])
tic 
[q_dot_mex,q_mex,v_dot_mex,v_mex,p_gen_mex,odo_gen_mex,acc_ef_mex] = ...
    get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld_mex(new_agb_j,...
    indices,g_all,w_all,downsampling,start_gps,...
    best_initial_orientation);
time_for_mex_code = toc; 
disp(['Time for mex-code: ', num2str(time_for_mex_code)])
disp(['Error check - difference in output: ', num2str(norm(q_dot-q_dot_mex)+...
    norm(v_dot-v_dot_mex)+norm(v-v_mex)+norm(p_gen-p_gen_mex)+...
    norm(odo_gen-odo_gen_mex)+norm(acc_ef-acc_ef_mex))])

choice = 2; dmm_inputs_etc

disp(' '); disp(' ')
disp('Function: get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld(t,x,u,params)')
tic 
test_code(); 
[q_dot,q,v_dot,v,p_gen,odo_gen,acc_ef] = ...
    get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld(new_agb_j,...
    indices,g_all,w_all,downsampling,start_gps,...
    best_initial_orientation); 
time_for_m_code = toc; 
disp(['Time taken for m-script: ', num2str(time_for_m_code)])
tic 
[q_dot_mex,q_mex,v_dot_mex,v_mex,p_gen_mex,odo_gen_mex,acc_ef_mex] = ...
    get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld_mex(new_agb_j,...
    indices,g_all,w_all,downsampling,start_gps,...
    best_initial_orientation);
time_for_mex_code = toc; 
disp(['Time for mex-code: ', num2str(time_for_mex_code)])
disp(['Error check - difference in output: ', num2str(norm(q_dot-q_dot_mex)+...
    norm(v_dot-v_dot_mex)+norm(v-v_mex)+norm(p_gen-p_gen_mex)+...
    norm(odo_gen-odo_gen_mex)+norm(acc_ef-acc_ef_mex))])

