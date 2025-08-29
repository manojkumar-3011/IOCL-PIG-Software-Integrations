classdef to_tools < handle % run: >> to_tools([]) %&OBJ
    properties (Access=protected) 
        data1_to_tools = [1,2]; 
        muLB = []; 
        muUB = []; 
    end 
    properties 
        to_tools_TITLE_1 = '<<<<< to_tools Settings >>>>>'; 
        max_iter = 100; % <-- Maximum iteration for TO loop 
        sigma = 0.1; % <-- Measurement noise variance 
        weight = 1; % <-- Lagrangian weights 
        alpha = 1; % <-- acceleration 
        to_tools_TITLE_2 = '<<<<< to_tools Parameters >>>>>'; 
        sys_data = struct(); 
        adjsys_data = struct(); 
        linzd_data = struct(); 
        slackfcn_data = struct(); 
        to_tools_TITLE_3 = '<<<<< to_tools Data >>>>>'; 
        sys_params = struct(); 
        input_data = []; 
        C_switch_data = []; 
        noise_data = struct(); 
        lqr_data = struct(); 
        traj_data = struct(); 
        ekf_data = struct(); 
        kalman_gain = []; 
        to_tools_TITLE_4 = '<<<<< to_tools Results >>>>>'; 
        to_sys_pred_results = struct(); 
        efk_traj_results = struct(); 
        estimated_states = []; 
    end 
    methods 
        %% Core 
        function obj = to_tools(varargin) 
            % Pack inputs: inputs = {pb.data1_to_tools, pb.data2_to_tools, pb.data3_to_tools}; 
            % Unpack inputs and call: some_func(inputs{:}) 
            % Bulk set: [abc, def, ghi] = inputs{:}; 
            if nargin>0 
                % test case execution 
                if isempty(varargin{1}) 
                    obj = obj.tests(); 
                    return 
                end 
                % get new data 
                if nargin>1 && nargin<=2 
                    [obj.data1_to_tools, obj.input_data] ...
                        = varargin{:}; 
                    obj.sys_data = false; 
                end 
                if nargin>2 
                    [obj.data1_to_tools, obj.input_data, ...
                        obj.sys_data] ...
                        = varargin{:}; 
                end 
            else 
                % change default data 
            end 
            obj.init_to(); 
            obj.about(); 
        end 
        function new_obj = tests(~) 
            clc 

%             new_obj = test_to_tools_how_to(); 
            new_obj = test_to_tools_gain_bias_init();  
%             new_obj = test_ekf_tools_gain_bias_init(); 
            test_gap_in_to_tools_gain_bias_init(); 

        end 
        function about(~) 
            disp('This is a framework for classes defining functionalities! '); 
            disp('Class name: to_tools') 
        end 
        %% Useful methods 
        %$ Get methods: get_ 
        %% Computations: eval_ + {update_, reset_, clean_, record_, etc.}  
        function eval_trajopt_main(obj) 
            if ~isfield(obj.to_sys_pred_results.sys_data,'guess_sys_data') 
                obj.to_sys_pred_results.sys_data.f = obj.sys_data.f_guess; 
                obj.to_sys_pred_results.sys_data.g = obj.sys_data.g_guess; 
                obj.to_sys_pred_results.sys_data.h = obj.sys_data.h_guess; 
                obj.to_sys_pred_results.sys_data.h_ext = obj.sys_data.h_ext_guess; 
                obj.to_sys_pred_results.sys_data.x0_guess = obj.sys_data.x0_guess; 
            end 
            N = obj.sys_params.N; 
            obj.alpha = 0.3/N^2; 
            guess_sys_data = obj.to_sys_pred_results.sys_data; 
            x0_guess = obj.sys_data.x0_guess; 
            obj.weight = eye(obj.sys_params.m); 
            % x0_guess = obj.sys_data.x0; 
            for iter=1:obj.max_iter 
                % S1. Fwd sim 
                [x_traj,y_traj] = obj.get_fwdsim_guess(guess_sys_data,x0_guess); 
                % S2. Bckwd sim 
                del_y = obj.traj_data.mesrd_noisy - y_traj; 
                lam_traj = obj.get_bwdsim_adjoint(del_y,x_traj); 
                % S3. Grads 
                dLdg = sum(obj.input_data'*lam_traj(2:end,:),1)'; 
                u_0 = obj.input_data(1,:)'; 
                x_0 = x_traj(1,:)'; 
                if obj.C_switch_data(1)==0 % y_traj[0] <-- h/h_ext 
                    dLdx0 = obj.adjsys_data.A_T(x_0,u_0)*lam_traj(2,:)' ...
                        - obj.adjsys_data.C_ext_T(x_0)*obj.weight*del_y(1,:)'; 
                else 
                    dLdx0 = obj.adjsys_data.A_T(x_0,u_0)*lam_traj(2,:)' ...
                        - obj.adjsys_data.C_T(x_0)*obj.weight*del_y(1,:)'; 
                end 
                % S4. Update 
                guess_sys_data.g = @(x,u) (guess_sys_data.g([],[],1) - obj.alpha*dLdg)*u; 
                x0_guess = x0_guess - obj.alpha*N*dLdx0; 
            end 
            obj.to_sys_pred_results.sys_data = guess_sys_data; 
            obj.to_sys_pred_results.sys_data.x0_guess = x0_guess; 
        end 
    end 
    methods % Used in ILI 
        %% Useful methods 
        %$ Get methods: get_ 
        function [x_traj,y_traj,y_fulltraj] = get_fwdsim_guess(varargin) 
            obj = varargin{1}; 
            if nargin>1 
                guess_sys_data = varargin{2}; 
            else 
                guess_sys_data = []; 
            end 
            if nargin>2 
                x_i = varargin{3}; 
            else 
                x_i = []; 
            end 
            if isempty(guess_sys_data) 
                guess_sys_data.f = obj.sys_data.f_guess; 
                guess_sys_data.g = obj.sys_data.g_guess; 
                guess_sys_data.h = obj.sys_data.h_guess; 
                guess_sys_data.h_ext = obj.sys_data.h_ext_guess; 
            end 
            if isempty(x_i) 
                x_i = obj.sys_data.x0_guess; 
            end 
            x_traj = x_i'; 
            if obj.C_switch_data(1)==0 % y_traj[0] <-- h/h_ext 
                y_traj = transpose(obj.sys_data.h_ext(x_i)); 
                y_fulltraj = y_traj; 
            else 
                y_traj = transpose(obj.sys_data.h(x_i)); 
            end 
            for i=1:obj.sys_params.N 
                t = obj.sys_params.dT*(i-1); 
                u_i = obj.input_data(i,:)'; 
                x_i = guess_sys_data.f(x_i) + guess_sys_data.g(t,x_i,u_i); 
                if sum(i==obj.C_switch_data)>0 
                    y_i = guess_sys_data.h_ext(x_i); 
                else 
                    y_i = guess_sys_data.h(x_i); 
                end 
                x_traj = [x_traj; x_i']; 
                y_traj = [y_traj; transpose(y_i)]; 
                y_fulltraj = [y_fulltraj; transpose(guess_sys_data.h_ext(x_i))]; 
            end 
        end 
        function [x_traj,y_traj,y_fulltraj] = get_fwdsim_bk_guess(varargin) 
            obj = varargin{1}; 
            if nargin>1 
                guess_sys_data = varargin{2}; 
            else 
                guess_sys_data = []; 
            end 
            if nargin>2 
                x_i = varargin{3}; 
            else 
                x_i = []; 
            end 
            if isempty(guess_sys_data) 
                guess_sys_data.f = obj.sys_data.f_guess; 
                guess_sys_data.g = obj.sys_data.g_guess; 
                guess_sys_data.h = obj.sys_data.h_guess; 
                guess_sys_data.h_ext = obj.sys_data.h_ext_guess; 
            end 
            if isempty(x_i) 
                x_i = obj.sys_data.x0_guess; 
            end 
            bs_guess = obj.to_sys_pred_results.sys_data.bs_guess; 
            x_traj = x_i'; 
            if obj.C_switch_data(1)==0 % y_traj[0] <-- h/h_ext 
                y_traj = transpose(obj.sys_data.h_ext(x_i)); 
                y_fulltraj = y_traj; 
            else 
                y_traj = transpose(obj.sys_data.h(x_i)); 
            end 
            for i=1:obj.sys_params.N 
                b_i = bs_guess(i,:)'; 
                u_i = obj.input_data(i,:)'; 
                try 
                x_i = guess_sys_data.f(x_i) + guess_sys_data.g(x_i,u_i,b_i); 
                catch 
                    keyboard 
                end 
                if sum(i==obj.C_switch_data)>0 
                    y_i = guess_sys_data.h_ext(x_i); 
                else 
                    y_i = guess_sys_data.h(x_i); 
                end 
                x_traj = [x_traj; x_i']; 
                y_traj = [y_traj; transpose(y_i)]; 
                y_fulltraj = [y_fulltraj; transpose(guess_sys_data.h_ext(x_i))]; 
            end 
        end 
        function [x_traj,y_traj,y_fulltraj] = get_fwdsim_bk_ltv_guess(varargin) 
            obj = varargin{1}; 
            if nargin>1 
                guess_sys_data = varargin{2}; 
            else 
                guess_sys_data = []; 
            end 
            if nargin>2 
                x_i = varargin{3}; 
            else 
                x_i = []; 
            end 
            if isempty(guess_sys_data) 
                guess_sys_data.f = obj.sys_data.f_guess; 
                guess_sys_data.g = obj.sys_data.g_guess; 
                guess_sys_data.h = obj.sys_data.h_guess; 
                guess_sys_data.h_ext = obj.sys_data.h_ext_guess; 
            end 
            if isempty(x_i) 
                x_i = obj.sys_data.x0_guess; 
            end 
            K_guess = obj.to_sys_pred_results.sys_data.K_guess; 
            bs_guess = obj.to_sys_pred_results.sys_data.bs_guess; 
            x_traj = x_i'; 
            if obj.C_switch_data(1)==0 % y_traj[0] <-- h/h_ext 
                y_traj = transpose(obj.sys_data.h_ext(x_i)); 
                y_fulltraj = y_traj; 
            else 
                y_traj = transpose(obj.sys_data.h(x_i)); 
            end 
            for i=1:obj.sys_params.N 
                t = obj.sys_params.dT*(i-1); 
                b_i = bs_guess(i,:)'; 
                u_i = obj.input_data(i,:)'; 
                x_i(end-length(b_i)+1:end) = b_i; % <<== bias update 
                try 
                x_i = guess_sys_data.f(x_i) + guess_sys_data.g(t,x_i,u_i,diag(K_guess)); 
                catch 
                    keyboard 
                end 
                if sum(i==obj.C_switch_data)>0 
                    y_i = guess_sys_data.h_ext(x_i); 
                else 
                    y_i = guess_sys_data.h(x_i); 
                end 
                x_traj = [x_traj; x_i']; 
                y_traj = [y_traj; transpose(y_i)]; 
                y_fulltraj = [y_fulltraj; transpose(guess_sys_data.h_ext(x_i))]; 
            end 
        end 
        function lam_traj = get_bwdsim_adjoint(varargin) 
            obj = varargin{1}; 
            if nargin>1 
                del_y_traj = varargin{2}; 
            else 
                del_y_traj = 0; 
            end 
            if nargin>2 
                x_traj = varargin{3}; 
            else 
                x_traj = 0; 
            end 
            x_i = x_traj(end,:)'; 
            if obj.C_switch_data(end)==size(obj.input_data,1) % C/C_ext 
                lam_i = -obj.adjsys_data.C_ext_T(x_i)*obj.weight*del_y_traj(end,:)'; 
            else 
                lam_i = -obj.adjsys_data.C_T(x_i)*obj.weight*del_y_traj(end,:)'; 
            end 
            lam_traj = lam_i'; 
            for i=obj.sys_params.N:-1:1 
                u_i = obj.input_data(i,:)'; 
                x_i = x_traj(i,:)'; 
                if sum(i==obj.C_switch_data)>0 
                    lam_i = obj.adjsys_data.A_T(x_i,u_i)*lam_i ...
                        - obj.adjsys_data.C_ext_T(x_i)*obj.weight*del_y_traj(i,:)'; 
                else 
                    lam_i = obj.adjsys_data.A_T(x_i,u_i)*lam_i ...
                        - obj.adjsys_data.C_T(x_i)*obj.weight*del_y_traj(i,:)'; 
                end 
                lam_traj = [lam_i'; lam_traj]; 
            end 
        end 
        function lam_traj = get_bwdsim_statemes_adjoint(varargin) 
            obj = varargin{1}; 
            del_y_traj = varargin{2}; 
            x_traj = varargin{3}; 
            W = varargin{4}; 
            % x_i = x_traj(end,:)'; 
            lam_i = -W*del_y_traj(end,:)'; 
            lam_traj = lam_i'; 
            for i=obj.sys_params.N:-1:1 
                u_i = obj.input_data(i,:)'; 
                x_i = x_traj(i,:)'; 
                lam_i = obj.adjsys_data.A_T(x_i,u_i)*lam_i - W*del_y_traj(i,:)'; 
                lam_traj = [lam_i'; lam_traj]; 
            end 
        end 
        function lam_traj = get_bwdsim_ekf_adjoint(varargin) 
            obj = varargin{1}; 
            del_y_traj = varargin{2}; 
            x_traj = varargin{3}; 
            W = varargin{4}; 
            % x_i = x_traj(end,:)'; 
            lam_i = -W*del_y_traj(end,:)'; 
            lam_traj = lam_i'; 
            for i=obj.sys_params.N:-1:1 
                u_i = obj.input_data(i,:)'; 
                x_i = x_traj(i,:)'; 
                K_k = reshape(obj.kalman_gain(i,:),obj.sys_params.n,[]); 
                if sum(i==obj.C_switch_data)~=0 
                    M = eye(obj.sys_params.n) - K_k*obj.linzd_data.C_ext(x_i); 
                else 
                    M = eye(obj.sys_params.n) - K_k*obj.linzd_data.C(x_i); 
                end 
                lam_i = obj.adjsys_data.A_T(x_i,u_i)*transpose(M)*lam_i ...
                    - W*del_y_traj(i,:)'; 
                lam_traj = [lam_i'; lam_traj]; 
            end 
        end 
        function lam_traj = get_bwdsim_bk_adjoint(varargin) 
            obj = varargin{1}; 
            if nargin>1 
                del_y_traj = varargin{2}; 
            else 
                del_y_traj = 0; 
            end 
            if nargin>2 
                x_traj = varargin{3}; 
            else 
                x_traj = 0; 
            end 
            bs_guess = obj.to_sys_pred_results.sys_data.bs_guess; 
            x_i = x_traj(end,:)'; 
            if obj.C_switch_data(end)==size(obj.input_data,1) % C/C_ext 
                lam_i = -obj.adjsys_data.C_ext_T(x_i)*obj.weight*del_y_traj(end,:)'; 
            else 
                lam_i = -obj.adjsys_data.C_T(x_i)*obj.weight*del_y_traj(end,:)'; 
            end 
            lam_traj = lam_i'; 
            for i=obj.sys_params.N:-1:1 
                b_i = bs_guess(i,:)'; 
                u_i = obj.input_data(i,:)'; 
                x_i = x_traj(i,:)'; 
                if sum(i==obj.C_switch_data)>0 
                    lam_i = obj.adjsys_data.A_T(x_i,u_i,b_i)*lam_i ...
                        - obj.adjsys_data.C_ext_T(x_i)*obj.weight*del_y_traj(i,:)'; 
                else 
                    lam_i = obj.adjsys_data.A_T(x_i,u_i,b_i)*lam_i ...
                        - obj.adjsys_data.C_T(x_i)*obj.weight*del_y_traj(i,:)'; 
                end 
                lam_traj = [lam_i'; lam_traj]; 
            end 
        end 
        function lam_traj = get_bwdsim_bk_ltv_adjoint(varargin) 
            obj = varargin{1}; 
            if nargin>1 
                del_y_traj = varargin{2}; 
            else 
                del_y_traj = 0; 
            end 
            if nargin>2 
                x_traj = varargin{3}; 
            else 
                x_traj = 0; 
            end 
            K_guess = obj.to_sys_pred_results.sys_data.K_guess; 
            bs_guess = obj.to_sys_pred_results.sys_data.bs_guess; 
            params = diag(K_guess); 
            x_i = x_traj(end,:)'; 
            if obj.C_switch_data(end)==size(obj.input_data,1) % C/C_ext 
                lam_i = -obj.adjsys_data.C_ext_T(x_i)*obj.weight*del_y_traj(end,:)'; 
            else 
                lam_i = -obj.adjsys_data.C_T(x_i)*obj.weight*del_y_traj(end,:)'; 
            end 
            lam_traj = lam_i'; 
            for i=obj.sys_params.N:-1:1 
                t = obj.sys_params.dT*(i-1); 
                b_i = bs_guess(i,:)'; 
                u_i = obj.input_data(i,:)'; 
                x_i = x_traj(i,:)'; 
                x_i(end-length(b_i)+1:end) = b_i; % <<== bias update 
                if sum(i==obj.C_switch_data)>0 
                    lam_i = obj.adjsys_data.A_T(t,x_i,u_i,params)*lam_i ...
                        - obj.adjsys_data.C_ext_T(x_i)*obj.weight*del_y_traj(i,:)'; 
                else 
                    lam_i = obj.adjsys_data.A_T(t,x_i,u_i,params)*lam_i ...
                        - obj.adjsys_data.C_T(x_i)*obj.weight*del_y_traj(i,:)'; 
                end 
                lam_traj = [lam_i'; lam_traj]; 
            end 
        end 
        function lam_traj = get_bwdsim_ekf_ltv_adjoint(varargin) 
            obj = varargin{1}; 
            del_y_traj = varargin{2}; 
            x_traj = varargin{3}; 
            W = varargin{4}; 
            K_guess = obj.to_sys_pred_results.sys_data.K_guess; 
            bs_guess = obj.to_sys_pred_results.sys_data.bs_guess; 
            params = diag(K_guess); 
            x_i = x_traj(end,:)'; 
            if obj.C_switch_data(end)==size(obj.input_data,1) % C/C_ext 
                lam_i = -W*del_y_traj(end,:)'; 
            else 
                lam_i = -W*del_y_traj(end,:)'; 
            end 
            lam_traj = lam_i'; 
            for i=obj.sys_params.N:-1:1 
                t = obj.sys_params.dT*(i-1); 
                b_i = bs_guess(i,:)'; 
                u_i = obj.input_data(i,:)'; 
                x_i = x_traj(i,:)'; 
                x_i(end-length(b_i)+1:end) = b_i; % <<== bias update 
                lam_i = obj.adjsys_data.A_T(t,x_i,u_i,params)*lam_i ...
                    - W*del_y_traj(i,:)'; 
                lam_traj = [lam_i'; lam_traj]; 
            end 
        end 
        function [x_best, p_best, klmn_gain] = get_ekf_simple_step(varargin) 
            obj = varargin{1}; 
            i_step = varargin{2}; 
            y_odo_marker_prevx = varargin{3}; 
            u_imu = varargin{4}; 
            if nargin>4 
                guess_sys_data = varargin{5}; 
            else 
                guess_sys_data = []; 
            end 
            if isempty(guess_sys_data) 
                guess_sys_data.f = obj.sys_data.f; % not f_guess 
                guess_sys_data.g = obj.sys_data.g; % not g_guess 
                guess_sys_data.h = obj.sys_data.h; % not h_guess 
                guess_sys_data.h_ext = obj.sys_data.h_ext; % not h_guess 
            end 

            % 
            x_est = obj.ekf_data.x_est; 
            p_est = obj.ekf_data.p_est; 

            % Initialize state transition matrix
            A = obj.linzd_data.A(x_est,u_imu); 
            if sum(i_step==obj.C_switch_data)>0 
                H = obj.linzd_data.C_ext(x_est);    % Initialize measurement matrix 
                R = obj.noise_data.R_ext;
            else 
                H = obj.linzd_data.C(x_est);    % Initialize measurement matrix
                R = obj.noise_data.R;
            end 
            Q = obj.noise_data.Q;
            
            % Predicted state and covariance
            x_prd = guess_sys_data.f(x_est) + guess_sys_data.g(x_est,u_imu); 
            p_prd = A * p_est * A' + Q; 
        
            % Estimation
            S = H * p_prd' * H' + R;
            B = H * p_prd';
            klmn_gain = (S \ B)';
        
            % Estimated state and covariance 
            if sum(i_step==obj.C_switch_data)>0 
                y_residue = y_odo_marker_prevx - guess_sys_data.h_ext(x_prd); 
            else 
                y_residue = y_odo_marker_prevx - guess_sys_data.h(x_prd); 
            end 
            x_est = x_prd + klmn_gain * y_residue; 
            p_est = p_prd - klmn_gain * H * p_prd;
        
            % Best 
            obj.ekf_data.x_est = x_est; 
            obj.ekf_data.p_est = p_est; 
            x_best = x_est; 
            p_best = p_est; 
        
        end 
        function [x_best, p_best, klmn_gain] = get_ekf_step(varargin) 
            obj = varargin{1}; 
            i_step = varargin{2}; 
            y_odo_marker_prevx = varargin{3}; 
            u_imu = varargin{4}; 
            if nargin>4 
                guess_sys_data = varargin{5}; 
            else 
                guess_sys_data = []; 
            end 
            if isempty(guess_sys_data) 
                guess_sys_data.f = obj.sys_data.f; % not f_guess 
                guess_sys_data.g = obj.sys_data.g; % not g_guess 
                guess_sys_data.h = obj.sys_data.h; % not h_guess 
                guess_sys_data.h_ext = obj.sys_data.h_ext; % not h_guess 
            end 

            t = obj.sys_params.dT*(i_step-1); 
            K_guess = obj.to_sys_pred_results.sys_data.K_guess; 
            % 
            x_est = obj.ekf_data.x_est; 
            p_est = obj.ekf_data.p_est; 

            % Initialize state transition matrix
            A = obj.linzd_data.A(t,x_est,u_imu,diag(K_guess)); 
            if sum(i_step==obj.C_switch_data)>0 
                H = obj.linzd_data.C_ext(x_est);    % Initialize measurement matrix 
                R = obj.noise_data.R_ext;
            else 
                H = obj.linzd_data.C(x_est);    % Initialize measurement matrix
                R = obj.noise_data.R;
            end 
            Q = obj.noise_data.Q;
            
            % Predicted state and covariance
            x_prd = guess_sys_data.f(x_est) + guess_sys_data.g(t,x_est,u_imu,diag(K_guess)); 
            p_prd = A * p_est * A' + Q; 
        
            % Estimation
            S = H * p_prd' * H' + R;
            B = H * p_prd';
            klmn_gain = (S \ B)';
        
            % Estimated state and covariance 
            if sum(i_step==obj.C_switch_data)>0 
                y_residue = y_odo_marker_prevx - guess_sys_data.h_ext(x_prd); 
            else 
                y_residue = y_odo_marker_prevx - guess_sys_data.h(x_prd); 
            end 
            x_est = x_prd + klmn_gain * y_residue; 
            p_est = p_prd - klmn_gain * H * p_prd;
        
            % Best 
            obj.ekf_data.x_est = x_est; 
            obj.ekf_data.p_est = p_est; 
            x_best = x_est; 
            p_best = p_est; 
        
        end 
        function [x_best, p_best, kalman_gain] = get_ekf_unkwn_dT_step(varargin) 
            obj = varargin{1}; 
            i_step = varargin{2}; 
            y_odo_marker_prevx = varargin{3}; 
            u_imu = varargin{4}; 
            if nargin>4 
                guess_sys_data = varargin{5}; 
            else 
                guess_sys_data = []; 
            end 
            if isempty(guess_sys_data) 
                guess_sys_data.f = obj.sys_data.f; % not f_guess 
                guess_sys_data.g = obj.sys_data.g; % not g_guess 
                guess_sys_data.h = obj.sys_data.h; % not h_guess 
                guess_sys_data.h_ext = obj.sys_data.h_ext; % not h_guess 
            end 

            t = obj.sys_params.dT*(i_step-1); 
            K_guess = obj.to_sys_pred_results.sys_data.K_guess; 
            % 
            x_est = obj.ekf_data.x_est; 
            p_est = obj.ekf_data.p_est; 

            % Initialize state transition matrix
            A = obj.linzd_data.A(t,x_est,u_imu,[diag(K_guess);obj.sys_params.dT]); 
            if sum(i_step==obj.C_switch_data)>0 
                H = obj.linzd_data.C_ext(x_est);    % Initialize measurement matrix 
                R = obj.noise_data.R_ext;
            else 
                H = obj.linzd_data.C(x_est);    % Initialize measurement matrix
                R = obj.noise_data.R;
                H = H(1,:); R = R(1,1); 
            end 
            Q = obj.noise_data.Q;
            
            % Predicted state and covariance 
            x_prd = guess_sys_data.f(x_est) + guess_sys_data.g(t,x_est,u_imu,...
                [diag(K_guess);obj.sys_params.dT]); 
            p_prd = A * p_est * A' + Q; 
            % if sum(sum(isnan(p_prd))+sum(isinf(p_prd)))>0; keyboard; end 
        
            % Estimation
            S = H * p_prd' * H' + R;
            B = H * p_prd';
            klmn_gain = (S \ B)';

            % Estimated state and covariance 
            if sum(i_step==obj.C_switch_data)>0 
                y_residue = y_odo_marker_prevx - guess_sys_data.h_ext(x_prd); 
                kalman_gain = klmn_gain; 
            else 
                y_residue = y_odo_marker_prevx - guess_sys_data.h(x_prd); 
                y_residue = y_residue(1); 
                kalman_gain = [klmn_gain,zeros(size(klmn_gain,1),3)]; 
            end 
%             du = x_prd - x_est; 
%             dx = du + klmn_gain(:,1) * y_residue(1); % x_prd + klmn_gain(:,1) * y_residue(1) - x_est; 
%             kg_n = zeros(17,4); 
%             kg_n(1) = 0.2498; 
%             kg_n(2:4,1) = dx(1)*(dx(2:4)/norm(dx(2:4).*[6356800*pi/180;6378100*pi/180;1]))/y_residue(1) ...
%                 - du(2:4)/y_residue(1); 
%             kg_n(9:11,1) = dx(1)*(dx(9:11)/norm(dx(9:11)))/y_residue(1) ...
%                 - du(9:11)/y_residue(1); 
%             klmn_gain = kg_n; % [0.249742477870269,0,0,0;-5.24587171120479e-07,0,0,0;-1.93849353487397e-07,0,0,0;0.00561947283491665,0,0,0;0,0,0,0;0,0,0,0;0,0,0,0;0,0,0,0;0.0232828014280217,0,0,0;-0.00789087568637537,0,0,0;-0.00224786759873758,0,0,0;0,0,0,0;0,0,0,0;0,0,0,0;0,0,0,0;0,0,0,0;0,0,0,0]; 
%             % dx_n = x_prd + klmn_gain * y_residue - x_est; 
            x_est = x_prd + klmn_gain * y_residue; 
            p_est = p_prd - klmn_gain * H * p_prd; 
            % if isnan(x_est); keyboard; end 
            % disp([norm(dx_n(2:4).*[6356800*pi/180;6378100*pi/180;1]), norm(dx(9:11))]; 
        
            % Best 
            obj.ekf_data.x_est = x_est; 
            obj.ekf_data.p_est = p_est; 
            x_best = x_est; 
            p_best = p_est; 
            
            if sum(i_step==obj.C_switch_data)>0 
                y_residue = y_odo_marker_prevx - guess_sys_data.h_ext(x_prd); 
            else 
                y_residue = y_odo_marker_prevx - guess_sys_data.h(x_prd); 
                klmn_gain = [klmn_gain,zeros(size(klmn_gain,1),3)]; 
            end 
        
        end 
        function [x_best, p_best, kalman_gain] = get_ekf_unkwn_dT_vel_scaled_step(varargin) 
            obj = varargin{1}; 
            i_step = varargin{2}; 
            y_odo_marker_prevx = varargin{3}; 
            u_imu = varargin{4}; 
            if nargin>4 
                guess_sys_data = varargin{5}; 
            else 
                guess_sys_data = []; 
            end 
            if isempty(guess_sys_data) 
                guess_sys_data.f = obj.sys_data.f; % not f_guess 
                guess_sys_data.g = obj.sys_data.g; % not g_guess 
                guess_sys_data.h = obj.sys_data.h; % not h_guess 
                guess_sys_data.h_ext = obj.sys_data.h_ext; % not h_guess 
            end 

            t = obj.sys_params.dT*(i_step-1); 
            K_guess = obj.to_sys_pred_results.sys_data.K_guess; 
            % 
            x_est = obj.ekf_data.x_est; 
            p_est = obj.ekf_data.p_est; 

            % Initialize state transition matrix
            A = obj.linzd_data.A(t,x_est,u_imu,[diag(K_guess);obj.sys_params.dT;obj.sys_params.vel_scl]); 
            if sum(i_step==obj.C_switch_data)>0 
                H = obj.linzd_data.C_ext(x_est);    % Initialize measurement matrix 
                R = obj.noise_data.R_ext;
            else 
                H = obj.linzd_data.C(x_est);    % Initialize measurement matrix
                R = obj.noise_data.R;
                H = H(1,:); R = R(1,1); 
            end 
            Q = obj.noise_data.Q;
            
            % Predicted state and covariance 
            x_prd = guess_sys_data.f(x_est) + guess_sys_data.g(t,x_est,u_imu,...
                [diag(K_guess);obj.sys_params.dT;obj.sys_params.vel_scl]); 
            p_prd = A * p_est * A' + Q; 
            % if sum(sum(isnan(p_prd))+sum(isinf(p_prd)))>0; keyboard; end 
        
            % Estimation
            S = H * p_prd' * H' + R;
            B = H * p_prd';
            klmn_gain = (S \ B)';

            % Estimated state and covariance 
            if sum(i_step==obj.C_switch_data)>0 
                y_residue = y_odo_marker_prevx - guess_sys_data.h_ext(x_prd); 
                kalman_gain = klmn_gain; 
            else 
                y_residue = y_odo_marker_prevx - guess_sys_data.h(x_prd); 
                y_residue = y_residue(1); 
                kalman_gain = [klmn_gain,zeros(size(klmn_gain,1),3)]; 
            end 
%             du = x_prd - x_est; 
%             dx = du + klmn_gain(:,1) * y_residue(1); % x_prd + klmn_gain(:,1) * y_residue(1) - x_est; 
%             kg_n = zeros(17,4); 
%             kg_n(1) = 0.2498; 
%             kg_n(2:4,1) = dx(1)*(dx(2:4)/norm(dx(2:4).*[6356800*pi/180;6378100*pi/180;1]))/y_residue(1) ...
%                 - du(2:4)/y_residue(1); 
%             kg_n(9:11,1) = dx(1)*(dx(9:11)/norm(dx(9:11)))/y_residue(1) ...
%                 - du(9:11)/y_residue(1); 
%             klmn_gain = kg_n; % [0.249742477870269,0,0,0;-5.24587171120479e-07,0,0,0;-1.93849353487397e-07,0,0,0;0.00561947283491665,0,0,0;0,0,0,0;0,0,0,0;0,0,0,0;0,0,0,0;0.0232828014280217,0,0,0;-0.00789087568637537,0,0,0;-0.00224786759873758,0,0,0;0,0,0,0;0,0,0,0;0,0,0,0;0,0,0,0;0,0,0,0;0,0,0,0]; 
%             % dx_n = x_prd + klmn_gain * y_residue - x_est; 
            x_est = x_prd + klmn_gain * y_residue; 
            p_est = p_prd - klmn_gain * H * p_prd; 
            % if isnan(x_est); keyboard; end 
            % disp([norm(dx_n(2:4).*[6356800*pi/180;6378100*pi/180;1]), norm(dx(9:11))]; 
        
            % Best 
            obj.ekf_data.x_est = x_est; 
            obj.ekf_data.p_est = p_est; 
            x_best = x_est; 
            p_best = p_est; 
            
            if sum(i_step==obj.C_switch_data)>0 
                y_residue = y_odo_marker_prevx - guess_sys_data.h_ext(x_prd); 
            else 
                y_residue = y_odo_marker_prevx - guess_sys_data.h(x_prd); 
                klmn_gain = [klmn_gain,zeros(size(klmn_gain,1),3)]; 
            end 
        
        end 
        function [x_traj,y_traj] = get_ekf_guess_system_and_data(varargin) 
            obj = varargin{1}; 
            if nargin>1 
                guess_sys_data = varargin{2}; 
            else 
                guess_sys_data = []; 
            end 
            if nargin>2 
                x_i = varargin{3}; 
            else 
                x_i = []; 
            end 
            if isempty(guess_sys_data) 
                guess_sys_data.f = obj.sys_data.f_guess; 
                guess_sys_data.g = obj.sys_data.g_guess; 
                guess_sys_data.h = obj.sys_data.h_guess; 
                guess_sys_data.h_ext = obj.sys_data.h_ext_guess; 
            end 
            if isempty(x_i) 
                x_i = obj.sys_data.x0_guess; 
            end 
            x_traj = x_i'; 
            if obj.C_switch_data(1)==0 % y_traj[0] <-- h/h_ext 
                y_traj = transpose(obj.sys_data.h_ext(x_i)); 
                y_fulltraj = y_traj; 
            else 
                y_traj = transpose(obj.sys_data.h(x_i)); 
            end 
            for i=1:obj.sys_params.N 
                t = obj.sys_params.dT*(i-1); 
                u_i = obj.input_data(i,:)'; 
                try 
                x_i = guess_sys_data.f(x_i) + guess_sys_data.g(t,x_i,u_i); 
                catch 
                    keyboard 
                end 
                if sum(i==obj.C_switch_data)>0 
                    y_i = guess_sys_data.h_ext(x_i); 
                else 
                    y_i = guess_sys_data.h(x_i); 
                end 
                x_traj = [x_traj; x_i']; 
                y_traj = [y_traj; transpose(y_i)]; 
                y_fulltraj = [y_fulltraj; transpose(guess_sys_data.h_ext(x_i))]; 
            end 
        end 
        function [x_traj,y_traj] = get_obsrvr_guess_system_and_data(varargin) 
            obj = varargin{1}; 
            if nargin>1 
                guess_sys_data = varargin{2}; 
            else 
                guess_sys_data = []; 
            end 
            if nargin>2 
                x_i = varargin{3}; 
            else 
                x_i = []; 
            end 
            if isempty(guess_sys_data) 
                guess_sys_data.f = obj.sys_data.f_guess; 
                guess_sys_data.g = obj.sys_data.g_guess; 
                guess_sys_data.h = obj.sys_data.h_guess; 
                guess_sys_data.h_ext = obj.sys_data.h_ext_guess; 
            end 
            if isempty(x_i) 
                x_i = obj.sys_data.x0_guess; 
            end 
            % This is it! 
            new_input = [obj.input,]; 


            % <---------> 
            x_traj = x_i'; 
            if obj.C_switch_data(1)==0 % y_traj[0] <-- h/h_ext 
                y_traj = transpose(obj.sys_data.h_ext(x_i)); 
                y_fulltraj = y_traj; 
            else 
                y_traj = transpose(obj.sys_data.h(x_i)); 
            end 
            for i=1:obj.sys_params.N 
                t = obj.sys_params.dT*(i-1); 
                u_i = obj.input_data(i,:)'; 
                try 
                x_i = guess_sys_data.f(x_i) + guess_sys_data.g(t,x_i,u_i); 
                catch 
                    keyboard 
                end 
                if sum(i==obj.C_switch_data)>0 
                    y_i = guess_sys_data.h_ext(x_i); 
                else 
                    y_i = guess_sys_data.h(x_i); 
                end 
                x_traj = [x_traj; x_i']; 
                y_traj = [y_traj; transpose(y_i)]; 
                y_fulltraj = [y_fulltraj; transpose(guess_sys_data.h_ext(x_i))]; 
            end 
        end 
        function [x_best, p_best, kalman_gain] = get_ekfnoC_unkwn_dT_vel_scaled_step(varargin) 
            obj = varargin{1}; 
            i_step = varargin{2}; 
            y_odo_marker_prevx = varargin{3}; 
            u_imu = varargin{4}; 
            if nargin>4 
                guess_sys_data = varargin{5}; 
            else 
                guess_sys_data = []; 
            end 
            if isempty(guess_sys_data) 
                guess_sys_data.f = obj.sys_data.f; % not f_guess 
                guess_sys_data.g = obj.sys_data.g; % not g_guess 
                guess_sys_data.h = obj.sys_data.h; % not h_guess 
                guess_sys_data.h_ext = obj.sys_data.h_ext; % not h_guess 
            end 

            t = obj.sys_params.dT*(i_step-1); 
            K_guess = obj.to_sys_pred_results.sys_data.K_guess; 
            % 
            x_est = obj.ekf_data.x_est; 
            p_est = obj.ekf_data.p_est; 

            % Initialize state transition matrix
            A = obj.linzd_data.A(t,x_est,u_imu,[diag(K_guess);obj.sys_params.dT;obj.sys_params.vel_scl]); 
            H = obj.linzd_data.C(x_est);    % Initialize measurement matrix
            R = obj.noise_data.R;
            H = H(1,:); R = R(1,1); 
            Q = obj.noise_data.Q;
            
            % Predicted state and covariance 
            x_prd = guess_sys_data.f(x_est) + guess_sys_data.g(t,x_est,u_imu,...
                [diag(K_guess);obj.sys_params.dT;obj.sys_params.vel_scl]); 
            p_prd = A * p_est * A' + Q; 
            % if sum(sum(isnan(p_prd))+sum(isinf(p_prd)))>0; keyboard; end 
        
            % Estimation
            S = H * p_prd' * H' + R;
            B = H * p_prd';
            klmn_gain = (S \ B)';

            % Estimated state and covariance 
            y_residue = y_odo_marker_prevx - guess_sys_data.h(x_prd); 
            y_residue = y_residue(1); 
            kalman_gain = [klmn_gain,zeros(size(klmn_gain,1),3)]; 
%             du = x_prd - x_est; 
%             dx = du + klmn_gain(:,1) * y_residue(1); % x_prd + klmn_gain(:,1) * y_residue(1) - x_est; 
%             kg_n = zeros(17,4); 
%             kg_n(1) = 0.2498; 
%             kg_n(2:4,1) = dx(1)*(dx(2:4)/norm(dx(2:4).*[6356800*pi/180;6378100*pi/180;1]))/y_residue(1) ...
%                 - du(2:4)/y_residue(1); 
%             kg_n(9:11,1) = dx(1)*(dx(9:11)/norm(dx(9:11)))/y_residue(1) ...
%                 - du(9:11)/y_residue(1); 
%             klmn_gain = kg_n; % [0.249742477870269,0,0,0;-5.24587171120479e-07,0,0,0;-1.93849353487397e-07,0,0,0;0.00561947283491665,0,0,0;0,0,0,0;0,0,0,0;0,0,0,0;0,0,0,0;0.0232828014280217,0,0,0;-0.00789087568637537,0,0,0;-0.00224786759873758,0,0,0;0,0,0,0;0,0,0,0;0,0,0,0;0,0,0,0;0,0,0,0;0,0,0,0]; 
%             % dx_n = x_prd + klmn_gain * y_residue - x_est; 
            x_est = x_prd + klmn_gain * y_residue; 
            p_est = p_prd - klmn_gain * H * p_prd; 
            % if isnan(x_est); keyboard; end 
            % disp([norm(dx_n(2:4).*[6356800*pi/180;6378100*pi/180;1]), norm(dx(9:11))]; 
        
            % Best 
            obj.ekf_data.x_est = x_est; 
            obj.ekf_data.p_est = p_est; 
            x_best = x_est; 
            p_best = p_est; 
            

            y_residue = y_odo_marker_prevx - guess_sys_data.h(x_prd); 
            klmn_gain = [klmn_gain,zeros(size(klmn_gain,1),3)]; 
        
        end 
        function [x_best, p_best, klmn_gain] = get_ekfvm_unkwn_dT_vel_scaled_step(varargin) 
            obj = varargin{1}; 
            i_step = varargin{2}; 
            y_odo_marker_prevx = varargin{3}; 
            u_imu = varargin{4}; 
            if nargin>4 
                guess_sys_data = varargin{5}; 
            else 
                guess_sys_data = []; 
            end 
            if isempty(guess_sys_data) 
                guess_sys_data.f = obj.sys_data.f; % not f_guess 
                guess_sys_data.g = obj.sys_data.g; % not g_guess 
                guess_sys_data.h = obj.sys_data.h; % not h_guess 
                guess_sys_data.h_ext = obj.sys_data.h_ext; % not h_guess 
            end 

            t = obj.sys_params.dT*(i_step-1); 
            K_guess = obj.to_sys_pred_results.sys_data.K_guess; 
            % 
            x_est = obj.ekf_data.x_est; 
            p_est = obj.ekf_data.p_est; 

            % Initialize state transition matrix
            A = obj.linzd_data.A(t,x_est,u_imu,[diag(K_guess);obj.sys_params.dT;obj.sys_params.vel_scl]); 
            H = obj.linzd_data.C_ext(x_est);    % Initialize measurement matrix
            R = obj.noise_data.R_ext;
            Q = obj.noise_data.Q;
            
            % Predicted state and covariance 
            x_prd = guess_sys_data.f(x_est) + guess_sys_data.g(t,x_est,u_imu,...
                [diag(K_guess);obj.sys_params.dT;obj.sys_params.vel_scl]); 
            p_prd = A * p_est * A' + Q; 
            % if sum(sum(isnan(p_prd))+sum(isinf(p_prd)))>0; keyboard; end 
        
            % Estimation
            S = H * p_prd' * H' + R;
            B = H * p_prd';
            klmn_gain = (S \ B)';

            % Estimated state and covariance 
            y_residue = y_odo_marker_prevx - guess_sys_data.h_ext(x_prd); 
%             du = x_prd - x_est; 
%             dx = du + klmn_gain(:,1) * y_residue(1); % x_prd + klmn_gain(:,1) * y_residue(1) - x_est; 
%             kg_n = zeros(17,4); 
%             kg_n(1) = 0.2498; 
%             kg_n(2:4,1) = dx(1)*(dx(2:4)/norm(dx(2:4).*[6356800*pi/180;6378100*pi/180;1]))/y_residue(1) ...
%                 - du(2:4)/y_residue(1); 
%             kg_n(9:11,1) = dx(1)*(dx(9:11)/norm(dx(9:11)))/y_residue(1) ...
%                 - du(9:11)/y_residue(1); 
%             klmn_gain = kg_n; % [0.249742477870269,0,0,0;-5.24587171120479e-07,0,0,0;-1.93849353487397e-07,0,0,0;0.00561947283491665,0,0,0;0,0,0,0;0,0,0,0;0,0,0,0;0,0,0,0;0.0232828014280217,0,0,0;-0.00789087568637537,0,0,0;-0.00224786759873758,0,0,0;0,0,0,0;0,0,0,0;0,0,0,0;0,0,0,0;0,0,0,0;0,0,0,0]; 
%             % dx_n = x_prd + klmn_gain * y_residue - x_est; 
            x_est = x_prd + klmn_gain * y_residue; 
            p_est = p_prd - klmn_gain * H * p_prd; 
            % if isnan(x_est); keyboard; end 
            % disp([norm(dx_n(2:4).*[6356800*pi/180;6378100*pi/180;1]), norm(dx(9:11))]; 
        
            % Best 
            obj.ekf_data.x_est = x_est; 
            obj.ekf_data.p_est = p_est; 
            x_best = x_est; 
            p_best = p_est; 
            

            y_residue = y_odo_marker_prevx - guess_sys_data.h(x_prd); 
            klmn_gain = [klmn_gain,zeros(size(klmn_gain,1),3)]; 
        
        end 
        function [x_best, p_best, klmn_gain] = get_ekfvm_unkwn_dT_vel_scaled_varbleR_step(varargin) 
            obj = varargin{1}; 
            i_step = varargin{2}; 
            y_odo_marker_prevx = varargin{3}; 
            u_imu = varargin{4}; 
            if nargin>4 
                guess_sys_data = varargin{5}; 
            else 
                guess_sys_data = []; 
            end 
            if isempty(guess_sys_data) 
                guess_sys_data.f = obj.sys_data.f; % not f_guess 
                guess_sys_data.g = obj.sys_data.g; % not g_guess 
                guess_sys_data.h = obj.sys_data.h; % not h_guess 
                guess_sys_data.h_ext = obj.sys_data.h_ext; % not h_guess 
            end 

            t = obj.sys_params.dT*(i_step-1); 
            K_guess = obj.to_sys_pred_results.sys_data.K_guess; 
            % 
            x_est = obj.ekf_data.x_est; 
            p_est = obj.ekf_data.p_est; 

            % Initialize state transition matrix
            A = obj.linzd_data.A(t,x_est,u_imu,[diag(K_guess);obj.sys_params.dT;obj.sys_params.vel_scl]); 
            H = obj.linzd_data.C_ext(x_est);    % Initialize measurement matrix
            Q = obj.noise_data.Q;
            R = obj.noise_data.R;
            R_ext = obj.noise_data.R_ext;
            alp_R = obj.noise_data.alp_R(i_step); 
            R_mix = alp_R*R + (1-alp_R)*R_ext; 
            
            % Predicted state and covariance 
            x_prd = guess_sys_data.f(x_est) + guess_sys_data.g(t,x_est,u_imu,...
                [diag(K_guess);obj.sys_params.dT;obj.sys_params.vel_scl]); 
            p_prd = A * p_est * A' + Q; 
            % if sum(sum(isnan(p_prd))+sum(isinf(p_prd)))>0; keyboard; end 
        
            % Estimation
            S = H * p_prd' * H' + R_mix;
            B = H * p_prd';
            klmn_gain = (S \ B)';

            % Estimated state and covariance 
            y_residue = y_odo_marker_prevx - guess_sys_data.h_ext(x_prd); 
%             du = x_prd - x_est; 
%             dx = du + klmn_gain(:,1) * y_residue(1); % x_prd + klmn_gain(:,1) * y_residue(1) - x_est; 
%             kg_n = zeros(17,4); 
%             kg_n(1) = 0.2498; 
%             kg_n(2:4,1) = dx(1)*(dx(2:4)/norm(dx(2:4).*[6356800*pi/180;6378100*pi/180;1]))/y_residue(1) ...
%                 - du(2:4)/y_residue(1); 
%             kg_n(9:11,1) = dx(1)*(dx(9:11)/norm(dx(9:11)))/y_residue(1) ...
%                 - du(9:11)/y_residue(1); 
%             klmn_gain = kg_n; % [0.249742477870269,0,0,0;-5.24587171120479e-07,0,0,0;-1.93849353487397e-07,0,0,0;0.00561947283491665,0,0,0;0,0,0,0;0,0,0,0;0,0,0,0;0,0,0,0;0.0232828014280217,0,0,0;-0.00789087568637537,0,0,0;-0.00224786759873758,0,0,0;0,0,0,0;0,0,0,0;0,0,0,0;0,0,0,0;0,0,0,0;0,0,0,0]; 
%             % dx_n = x_prd + klmn_gain * y_residue - x_est; 
            x_est = x_prd + klmn_gain * y_residue; 
            p_est = p_prd - klmn_gain * H * p_prd; 
            % if isnan(x_est); keyboard; end 
            % disp([norm(dx_n(2:4).*[6356800*pi/180;6378100*pi/180;1]), norm(dx(9:11))]; 
        
            % Best 
            obj.ekf_data.x_est = x_est; 
            obj.ekf_data.p_est = p_est; 
            x_best = x_est; 
            p_best = p_est; 
            

            y_residue = y_odo_marker_prevx - guess_sys_data.h(x_prd); 
            klmn_gain = [klmn_gain,zeros(size(klmn_gain,1),3)]; 
        
        end 
        % 
        function delmu = get_del_mu(obj,x_traj) 
            lr = 1e-2; 
            delslkLB = obj.slackfcn_data.lb(x_traj); 
            delslkLB(isinf(delslkLB)) = 0; 
            delslkUB = obj.slackfcn_data.ub(x_traj); 
            delslkUB(isinf(delslkUB)) = 0; 
            obj.muLB = max(0,obj.muLB + lr*delslkLB); 
            obj.muUB = max(0,obj.muUB + lr*delslkUB); 
            delmu = obj.muUB - obj.muLB; 
        end 
        %$ Set methods: set_ 
        function set_sys_params(varargin) 
            if nargin==6 
                [obj,n,N,m,r,dT] = varargin{:}; 
                vel_scl = 1; 
            else 
                [obj,n,N,m,r,dT,vel_scl] = varargin{:}; 
            end 
            obj.sys_params.n = n; 
            obj.sys_params.N = N; 
            obj.sys_params.m = m; 
            obj.sys_params.r = r; 
            obj.sys_params.dT = dT; 
            obj.sys_params.vel_scl = vel_scl; 
        end 
        function set_system_data(varargin) 
            obj = varargin{1}; 
            if nargin==12 
                [f,g,h,h_ext,x0] = varargin{2:6}; 
                [f_guess,g_guess,h_guess,h_ext_guess] = varargin{7:10}; 
                x0_guess = varargin{11}; 
                C_swtch_data = varargin{12}; 
            elseif nargin==8 
                [f,g,h,h_ext,x0] = varargin{2:6}; 
                [f_guess,g_guess,h_guess,h_ext_guess] = varargin{2:5}; 
                x0_guess = varargin{7}; 
                C_swtch_data = varargin{8}; 
            elseif nargin==7 
                [f,g,h,h_ext,x0] = varargin{2:6};  
                [f_guess,g_guess,h_guess,h_ext_guess] = varargin{2:5}; 
                x0_guess = varargin{6}; 
                C_swtch_data = varargin{7}; 
            elseif nargin==5 
                [f,g,h,x0] = varargin{2:5};  
                [f_guess,g_guess,h_guess] = varargin{2:5}; 
                h_ext = h; 
                h_ext_guess = h;  
                x0_guess = varargin{5}; 
                C_swtch_data = []; 
            else 
                error('Incorrect number of inputs! ') 
            end 
            obj.sys_data.f = f; 
            obj.sys_data.g = g; 
            obj.sys_data.h = h; 
            obj.sys_data.h_ext = h_ext; 
            obj.sys_data.x0 = x0; 
            obj.sys_data.f_guess = f_guess; 
            obj.sys_data.g_guess = g_guess; 
            obj.sys_data.h_guess = h_guess; 
            obj.sys_data.h_ext_guess = h_ext_guess; 
            obj.sys_data.x0_guess = x0_guess; 
            obj.C_switch_data = C_swtch_data; 
        end 
        function set_linearized_and_adjoint_data(varargin) 
            obj = varargin{1}; 
            if nargin==5 
                [A,B,C,C_ext] = varargin{2:5}; 
            elseif nargin==4 
                [A,B,C] = varargin{2:4}; 
                C_ext = C; 
            else 
                error('Incorrect number of inputs! '); 
            end 
            obj.linzd_data.A = A; % @(x,u) 
            obj.linzd_data.B =  B; 
            obj.linzd_data.C = C; 
            obj.linzd_data.C_ext = C_ext; 
            obj.adjsys_data.A_T = @(x,u) A(x,u)'; 
            obj.adjsys_data.B_T = @(x,u) B(x,u)'; 
            obj.adjsys_data.C_T = @(x) C(x)'; 
            obj.adjsys_data.C_ext_T = @(x) C_ext(x)'; 
        end 
        function set_linearized_and_adjoint_data_4bk(varargin) 
            obj = varargin{1}; 
            if nargin==5 
                [A,B,C,C_ext] = varargin{2:5}; 
            elseif nargin==4 
                [A,B,C] = varargin{2:4}; 
                C_ext = C; 
            else 
                error('Incorrect number of inputs! '); 
            end 
            obj.linzd_data.A = A; % @(x,u) 
            obj.linzd_data.B =  B; 
            obj.linzd_data.C = C; 
            obj.linzd_data.C_ext = C_ext; 
            obj.adjsys_data.A_T = @(x,u,bk) A(x,u,bk)'; 
            obj.adjsys_data.B_T = @(x,u) B(x,u)'; 
            obj.adjsys_data.C_T = @(x) C(x)'; 
            obj.adjsys_data.C_ext_T = @(x) C_ext(x)'; 
        end 
        function set_linearized_and_adjoint_data_4ltv(varargin) 
            obj = varargin{1}; 
            if nargin==5 
                [A,B,C,C_ext] = varargin{2:5}; 
            elseif nargin==4 
                [A,B,C] = varargin{2:4}; 
                C_ext = C; 
            else 
                error('Incorrect number of inputs! '); 
            end 
            obj.linzd_data.A = A; 
            obj.linzd_data.B =  B; 
            obj.linzd_data.C = C; 
            obj.linzd_data.C_ext = C_ext; 
            obj.adjsys_data.A_T = @(t,x,u,prms) A(t,x,u,prms)'; 
            obj.adjsys_data.B_T = @(t,x,u,prms) B(t,x,u,prms)'; 
            obj.adjsys_data.C_T = @(x) C(x)'; 
            obj.adjsys_data.C_ext_T = @(x) C_ext(x)'; 
        end 
        function set_input_data(obj,ip_data) 
            obj.input_data = ip_data; 
            obj.alpha = 0.3/size(ip_data,1)^2; 
        end 
        function set_noise_data(varargin) 
            obj = varargin{1}; 
            if nargin>4 
                Q = varargin{2}; 
                R = varargin{3}; 
                R_ext = varargin{4};
                sgm = varargin{5};
            elseif nargin>3 
                Q = varargin{2}; 
                R = varargin{3}; 
                R_ext = varargin{4};
                sgm = []; 
            elseif nargin>2 
                Q = varargin{2}; 
                R = varargin{3}; 
                R_ext = R;
                sgm = []; 
            elseif nargin>1 
                QR_wgts = varargin{2}; 
                Q = QR_wgts(1)*eye(obj.sys_params.n); 
                R = QR_wgts(2)*eye(obj.sys_params.m); 
                R_ext = R;
                sgm = []; 
            else 
                Q = eye(obj.sys_params.n); 
                R = eye(obj.sys_params.m); 
                R_ext = R;
                sgm = []; 
            end 
            obj.noise_data.Q = Q; 
            obj.noise_data.R = R; 
            obj.noise_data.R_ext = R_ext; 
            if ~isempty(sgm) 
                try % get N 
                    N = obj.sys_params.N; 
                catch 
                    error('Set the parameters first `set_sys_params`!') 
                end 
                ndist = normpdf(1:N,N/2,4*sgm*sqrt(N)); 
                obj.noise_data.alp_R = ndist/max(ndist); 
            end 
        end 
        function set_output_data(varargin) 
            obj = varargin{1}; 
            if nargin>1 
                op_data = varargin{2}; 
                obj.traj_data.states = nan(size(op_data,1),obj.sys_params.n); 
                obj.traj_data.mesrd_true = nan(size(op_data,1),size(op_data,2)); 
                obj.traj_data.mesrd_noisy = op_data; 
            else 
                obj.eval_and_render_fwdsim(); 
            end 
        end 
        function set_guess(obj,x0_guess,K_guess,bs_guess) 
            obj.to_sys_pred_results.sys_data.x0_guess = x0_guess; 
            obj.to_sys_pred_results.sys_data.K_guess = K_guess; 
            obj.to_sys_pred_results.sys_data.bs_guess = bs_guess; 
        end 
        function set_bounding_constraints(obj,LBf,UBf) 
            obj.slackfcn_data.lb = LBf; 
            obj.slackfcn_data.ub = UBf; 
        end 
        function set_lqr_wghts(obj,Q,R) 
            obj.lqr_data.Q = Q; 
            obj.lqr_data.R = R; 
        end 
        %$ Load methods: load_ 
        %$ Save methods: save_ 
        % Trajopt 
        function eval_and_render_fwdsim(varargin) 
            obj = varargin{1}; 
            obj.eval_fwdsim_true(); 
            [x_traj,y_traj] = obj.get_fwdsim_guess(); 
            % 
            subplot(3,1,1) 
            plot(obj.traj_data.states) 
            hold on 
            plot(x_traj, '-.') 
            hold off 
            obj.label_data(true); 
            grid on 
            subplot(3,1,2) 
            plot(obj.input_data) 
            xlabel('time --> ') 
            ylabel('control --> ') 
            grid on 
            subplot(3,1,3) 
            plot(obj.traj_data.mesrd_true) 
            hold on 
            plot(obj.traj_data.mesrd_noisy) 
            plot(y_traj, '-.') 
            hold off 
            obj.label_data(~true); 
            grid on 
            try % sgtitle 
                sgtitle('Forward simulation') 
            catch 
                disp('Version issue') 
            end 
        end 
        function eval_fwdsim_true(obj) 
            x_i = obj.sys_data.x0; 
            x_traj = x_i'; 
            if obj.C_switch_data(1)==0 % y_traj[0] <-- h/h_ext 
                y_traj = transpose(obj.sys_data.h_ext(x_i)); 
            else 
                y_traj = transpose(obj.sys_data.h(x_i)); 
            end 
            y_traj_noisy = y_traj + obj.sigma*randn(1); 
            for i=1:obj.sys_params.N 
                t = obj.sys_params.dT*(i-1); 
                u_i = obj.input_data(i,:)'; 
                x_i = obj.sys_data.f(x_i) + obj.sys_data.g(t,x_i,u_i); 
                x_traj = [x_traj; x_i']; 
                if sum(i==obj.C_switch_data)>0 
                    y_traj = [y_traj; transpose(obj.sys_data.h_ext(x_i))]; 
                    y_traj_noisy = [y_traj_noisy; transpose(obj.sys_data.h_ext(x_i)) + obj.sigma*randn(1)]; 
                else 
                    y_traj = [y_traj; transpose(obj.sys_data.h(x_i))]; 
                    y_traj_noisy = [y_traj_noisy; transpose(obj.sys_data.h(x_i)) + obj.sigma*randn(1)]; 
                end 
            end 
            obj.traj_data.states = x_traj; 
            obj.traj_data.mesrd_true = y_traj; 
            obj.traj_data.mesrd_noisy = y_traj_noisy; 
        end 
        function eval_trajopt_main_bmatrix(obj) 
            if ~isfield(obj.to_sys_pred_results.sys_data,'guess_sys_data') 
                obj.to_sys_pred_results.sys_data.f = obj.sys_data.f_guess; 
                obj.to_sys_pred_results.sys_data.g = obj.sys_data.g_guess; 
                obj.to_sys_pred_results.sys_data.h = obj.sys_data.h_guess; 
                obj.to_sys_pred_results.sys_data.h_ext = obj.sys_data.h_ext_guess; 
                obj.to_sys_pred_results.sys_data.x0_guess = obj.sys_data.x0_guess; 
            end 
            N = obj.sys_params.N; 
            obj.alpha = 0.3/N^2; 
            guess_sys_data = obj.to_sys_pred_results.sys_data; 
            x0_guess = obj.sys_data.x0_guess; 
            obj.weight = eye(obj.sys_params.m); 
            % x0_guess = obj.sys_data.x0; 
            for iter=1:obj.max_iter 
                % S1. Fwd sim 
                [x_traj,y_traj] = obj.get_fwdsim_guess(guess_sys_data,x0_guess); 
                % S2. Bckwd sim 
                del_y = obj.traj_data.mesrd_noisy - y_traj; 
                lam_traj = obj.get_bwdsim_adjoint(del_y,x_traj); 
                % S3. Grads 
                dLdg = sum(obj.input_data'*lam_traj(2:end,:),1)'; 
                u_0 = obj.input_data(1,:)'; 
                x_0 = x_traj(1,:)'; 
                if obj.C_switch_data(1)==0 % y_traj[0] <-- h/h_ext 
                    dLdx0 = obj.adjsys_data.A_T(x_0,u_0)*lam_traj(2,:)' ...
                        - obj.adjsys_data.C_ext_T(x_0)*obj.weight*del_y(1,:)'; 
                else 
                    dLdx0 = obj.adjsys_data.A_T(x_0,u_0)*lam_traj(2,:)' ...
                        - obj.adjsys_data.C_T(x_0)*obj.weight*del_y(1,:)'; 
                end 
                % S4. Update 
                guess_sys_data.g = @(x,u) (guess_sys_data.g([],[],1) - obj.alpha*dLdg)*u; 
                x0_guess = x0_guess - obj.alpha*N*dLdx0; 
            end 
            obj.to_sys_pred_results.sys_data = guess_sys_data; 
            obj.to_sys_pred_results.sys_data.x0_guess = x0_guess; 
        end 
        function [K_guess,bs_guess] = eval_trajopt_main_gain_bias_init(obj,acc_scale,K_guess,bs_guess) 
            if ~isfield(obj.to_sys_pred_results.sys_data,'guess_sys_data') 
                obj.to_sys_pred_results.sys_data.f = obj.sys_data.f_guess; 
                obj.to_sys_pred_results.sys_data.g = obj.sys_data.g_guess; 
                obj.to_sys_pred_results.sys_data.h = obj.sys_data.h_guess; 
                obj.to_sys_pred_results.sys_data.h_ext = obj.sys_data.h_ext_guess; 
                obj.to_sys_pred_results.sys_data.x0_guess = obj.sys_data.x0_guess; 
            end 
            N = obj.sys_params.N; 
            obj.alpha = 0.3*acc_scale/N^2; 
            guess_sys_data = obj.to_sys_pred_results.sys_data; 
            x0_guess = obj.sys_data.x0_guess; 
            obj.weight = eye(obj.sys_params.m); 
            % x0_guess = obj.sys_data.x0; 
            for iter=1:obj.max_iter 
                % S1. Fwd sim 
                [x_traj,y_traj] = obj.get_fwdsim_guess(guess_sys_data,x0_guess); 
                % S2. Bckwd sim 
                del_y = obj.traj_data.mesrd_noisy - y_traj; 
                lam_traj = obj.get_bwdsim_adjoint(del_y,x_traj); 
                % S3. Grads 
                dLdKvec = 0; 
                for i=1:N 
                    u_i = obj.input_data(i,:)'; 
                    x_i = x_traj(i,:)'; 
                    dLdKvec = dLdKvec + transpose(...
                        (lam_traj(i+1,:)*obj.linzd_data.B(x_i,u_i))*obj.input_data(i,:)'); 
                end 
                dLdbs = 0; 
                for i=1:N 
                    u_i = obj.input_data(i,:)'; 
                    x_i = x_traj(i,:)'; 
                    dLdbs = dLdbs + transpose(lam_traj(i+1,:)*obj.linzd_data.B(x_i,u_i)); 
                end 
                u_0 = obj.input_data(1,:)'; 
                x_0 = x_traj(1,:)'; 
                if obj.C_switch_data(1)==0 % y_traj[0] <-- h/h_ext 
                    dLdx0 = obj.adjsys_data.A_T(x_0,u_0)*lam_traj(2,:)' ...
                        - obj.adjsys_data.C_ext_T(x_0)*obj.weight*del_y(1,:)'; 
                else 
                    dLdx0 = obj.adjsys_data.A_T(x_0,u_0)*lam_traj(2,:)' ...
                        - obj.adjsys_data.C_T(x_0)*obj.weight*del_y(1,:)'; 
                end 
                % S4. Update 
                K_guess = K_guess - obj.alpha*N*diag(dLdKvec); 
                bs_guess = bs_guess - obj.alpha*N*dLdbs; 
                guess_sys_data.g = @(t,x,u) obj.linzd_data.B(x,u)*(K_guess*u + bs_guess); 
                x0_guess = x0_guess - obj.alpha*N*dLdx0; 
            end 
            obj.to_sys_pred_results.sys_data = guess_sys_data; 
            obj.to_sys_pred_results.sys_data.x0_guess = x0_guess; 
        end 
        function [K_guess,bs_guess,x0_guess,factr,y_fulltraj,W,del_y] = eval_trajopt_main_gain_bias_init_ili(obj,percent_update,...
                K_guess,bs_guess,x0_guess,dT,C_q,S_w,earth_gravity) 
            if ~isfield(obj.to_sys_pred_results.sys_data,'guess_sys_data') 
                obj.to_sys_pred_results.sys_data.f = obj.sys_data.f_guess; 
                obj.to_sys_pred_results.sys_data.g = obj.sys_data.g_guess; 
                obj.to_sys_pred_results.sys_data.h = obj.sys_data.h_guess; 
                obj.to_sys_pred_results.sys_data.h_ext = obj.sys_data.h_ext_guess; 
                obj.to_sys_pred_results.sys_data.x0_guess = obj.sys_data.x0_guess; 
            end 
            % 
            factr = 1; 
            saved_guess = {K_guess,bs_guess,x0_guess}; 
            % 
            N = obj.sys_params.N; 
            obj.alpha = 0.3/N^2; 
            guess_sys_data = obj.to_sys_pred_results.sys_data; 
            % x0_guess = obj.sys_data.x0_guess; 
            % obj.weight = eye(obj.sys_params.m); 
            obj.weight = [8.15849660302496/N^2,0,0,0;0,4151641837221.92,0,0;0,0,4151641837221.92,0;0,0,0,1647724.67444092]; % 
            % obj.weight = 1e-10*[0.00603838048126849,0,0,0;0,7.48506940906427e+19,0,0;0,0,7.48506940906427e+19,0;0,0,0,11483.7188104406]; 
            W = obj.weight; 
            % Way-1: how to get weight W: (no changes) 
            % >> dv_all = ([-eye(N),zeros(N,1)] + [zeros(N,1),eye(N)])*y_fulltraj 
            % >> dv_all = [dv_all(:,1),0.5*(abs(dv_all(:,2))+abs(dv_all(:,3))),dv_all(:,4)] 
            % >> Q_diag = 1./mean(dv_all,1).^2 
            % >> W = diag([Q_diag(1),Q_diag(2)*[1,1],Q_diag(3)]) 
            % x0_guess = obj.sys_data.x0; 
            % Way-2: how to get weight W: (result blows up) 
            % >> dv_all = del_y(end,:).^2 
            % >> dv_all = [dv_all(:,1),0.5*(abs(dv_all(:,2))+abs(dv_all(:,3))),dv_all(:,4)] 
            % >> Q_diag = 1./dv_all.^2 
            % >> W = diag([Q_diag(1),Q_diag(2)*[1,1],Q_diag(3)]) 
            % x0_guess = obj.sys_data.x0; 
            for iter=1:obj.max_iter 
                % S1. Fwd sim 
                [x_traj,y_traj,y_fulltraj] = obj.get_fwdsim_guess(guess_sys_data,x0_guess); 
                % S2. Bckwd sim 
                del_y = obj.traj_data.mesrd_noisy - y_traj; 
                lam_traj = obj.get_bwdsim_adjoint(del_y,x_traj); 
                % S3. Grads 
                dLdKvec = 0; 
                for i=1:N 
                    u_i = obj.input_data(i,:)'; 
                    x_i = x_traj(i,:)'; 
                    dLdKvec = dLdKvec + transpose(...
                        (lam_traj(i+1,:)*obj.linzd_data.B(x_i,u_i))*diag(obj.input_data(i,:))); 
                end 
                dLdbs = 0; 
                for i=1:N 
                    u_i = obj.input_data(i,:)'; 
                    x_i = x_traj(i,:)'; 
                    dLdbs = dLdbs + transpose(lam_traj(i+1,:)*obj.linzd_data.B(x_i,u_i)); 
                end 
                u_0 = obj.input_data(1,:)'; 
                x_0 = x_traj(1,:)'; 
                if obj.C_switch_data(1)==0 % y_traj[0] <-- h/h_ext 
                    dLdx0 = obj.adjsys_data.A_T(x_0,u_0)*lam_traj(2,:)' ...
                        - obj.adjsys_data.C_ext_T(x_0)*obj.weight*del_y(1,:)'; 
                else 
                    dLdx0 = obj.adjsys_data.A_T(x_0,u_0)*lam_traj(2,:)' ...
                        - obj.adjsys_data.C_T(x_0)*obj.weight*del_y(1,:)'; 
                end 
                % S4. Update 
                delK_update = obj.alpha*N*diag(dLdKvec); 
                delbs_update = obj.alpha*N*dLdbs; 
                delx0_update = obj.alpha*N*dLdx0; 
                if iter==1  
%                     alK = (percent_update(1)/100)*min(abs(diag(K_guess))./abs(diag(delK_update))); 
%                     albs = (percent_update(1)/100)*min(abs(bs_guess)./abs(delbs_update)); 
%                     alx0 = (percent_update(end)/100)*min(abs(x0_guess)./abs(delx0_update)); 
                    % alx0 = (percent_update(end)/100)*min(abs([240;23;72;87;1;1;1;1;1;1;1])./abs(delx0_update)); 
                    alK = 16e-4*(percent_update(1)/100)*4e-21; % 4e-21 is ~great for 12m 
                    albs = 10e-4*(120/N)*(percent_update(1)/100)*1e-7; % 1e-7 is ~great for 12m 
                    alx0 = 10e-1*(120/N)*(percent_update(end)/100)*1e-8; % 1e-8 is ~great for 12m 
                end 
                % condition break 
                if sum(isnan(delK_update(:))) || sum(isnan(delbs_update(:))) || sum(isnan(delx0_update(:))) 
                    % K = K_guess; bs = bs_guess; x0 = x0_guess; 
                    % save to_ili_res2 K bs x0
                    [K_guess,bs_guess,x0_guess] = saved_guess{:}; 
                    factr = 1; 
                    warning('NaN now!') 
                    break; 
                end 
                % 
                K_guess = K_guess - alK*delK_update; 
                bs_guess = bs_guess - albs*delbs_update; 
                q_gen = @(q,imu_w) q + dT*0.5*S_w(K_guess(4:6,4:6)*imu_w + bs_guess(4:6))*q; 
                f_q = @(q,imu_w) q_gen(q,imu_w)/norm(q_gen(q,imu_w)); 
                f_v = @(q,v,imu_a) v + dT*(C_q(q)*(K_guess(1:3,1:3)*imu_a + bs_guess(1:3)) - [0;0;earth_gravity]); 
                guess_sys_data.g = @(x,u) [zeros(4,1);f_q(x(5:8),u(4:6));f_v(x(5:8),x(9:11),u(1:3))]; 
                x0_guess = x0_guess - alx0*delx0_update; 
                % test: disp(alK*delK_update); disp(albs*delbs_update); disp(alx0*delx0_update) 
            end 
            obj.to_sys_pred_results.sys_data = guess_sys_data; 
            obj.to_sys_pred_results.sys_data.x0_guess = x0_guess; 
            obj.to_sys_pred_results.sys_data.K_guess = K_guess; 
            obj.to_sys_pred_results.sys_data.bs_guess = bs_guess; 
        end 
        function [K_guess,bs_guess,x0_guess,factr,y_fulltraj,W,Z,del_y] = eval_trajopt_main_gain_kbias_init_ili(obj,percent_update,...
                K_guess,bs_guess,x0_guess,dT,C_q,S_w,earth_gravity) 
            if ~isfield(obj.to_sys_pred_results.sys_data,'guess_sys_data') 
                obj.to_sys_pred_results.sys_data.f = obj.sys_data.f_guess; 
                obj.to_sys_pred_results.sys_data.g = obj.sys_data.g_guess; 
                obj.to_sys_pred_results.sys_data.h = obj.sys_data.h_guess; 
                obj.to_sys_pred_results.sys_data.h_ext = obj.sys_data.h_ext_guess; 
                obj.to_sys_pred_results.sys_data.x0_guess = obj.sys_data.x0_guess; 
            end 
            % 
            factr = 1; 
            saved_guess = {K_guess,bs_guess,x0_guess}; 
            % 
            obj.to_sys_pred_results.sys_data.bs_guess = bs_guess; 
            N = obj.sys_params.N; 
            obj.alpha = 0.3/N^2; 
            guess_sys_data = obj.to_sys_pred_results.sys_data; 
            % x0_guess = obj.sys_data.x0_guess; 
            % obj.weight = eye(obj.sys_params.m); 
            obj.weight = [8.15849660302496/N^2,0,0,0;0,4151641837221.92,0,0;0,0,4151641837221.92,0;0,0,0,1647724.67444092]; % 
            % obj.weight = 1e-10*[0.00603838048126849,0,0,0;0,7.48506940906427e+19,0,0;0,0,7.48506940906427e+19,0;0,0,0,11483.7188104406]; 
            W = obj.weight; 
            Z = 1*eye(obj.sys_params.r); 
            % Way-1: how to get weight W: (no changes) 
            % >> dv_all = ([-eye(N),zeros(N,1)] + [zeros(N,1),eye(N)])*y_fulltraj 
            % >> dv_all = [dv_all(:,1),0.5*(abs(dv_all(:,2))+abs(dv_all(:,3))),dv_all(:,4)] 
            % >> Q_diag = 1./mean(dv_all,1).^2 
            % >> W = diag([Q_diag(1),Q_diag(2)*[1,1],Q_diag(3)]) 
            % x0_guess = obj.sys_data.x0; 
            % Way-2: how to get weight W: (result blows up) 
            % >> dv_all = del_y(end,:).^2 
            % >> dv_all = [dv_all(:,1),0.5*(abs(dv_all(:,2))+abs(dv_all(:,3))),dv_all(:,4)] 
            % >> Q_diag = 1./dv_all.^2 
            % >> W = diag([Q_diag(1),Q_diag(2)*[1,1],Q_diag(3)]) 
            % x0_guess = obj.sys_data.x0; 
            for iter=1:obj.max_iter 
                % S1. Fwd sim 
                [x_traj,y_traj,y_fulltraj] = obj.get_fwdsim_bk_guess(guess_sys_data,x0_guess); 
                % S2. Bckwd sim 
                del_y = obj.traj_data.mesrd_noisy - y_traj; 
                lam_traj = obj.get_bwdsim_bk_adjoint(del_y,x_traj); 
                % S3. Grads 
                dLdKvec = 0; 
                for i=1:N 
                    u_i = obj.input_data(i,:)'; 
                    x_i = x_traj(i,:)'; 
                    dLdKvec = dLdKvec + transpose(...
                        (lam_traj(i+1,:)*obj.linzd_data.B(x_i,u_i))*diag(obj.input_data(i,:))); 
                end 
                b_0 = bs_guess(1,:)'; b_1 = bs_guess(2,:)'; 
                dLdbs = transpose(lam_traj(2,:)*obj.linzd_data.B(x_i,u_i) - (b_1-b_0)'*Z); 
                for i=2:N-1 
                    b_i = bs_guess(i,:)'; b_im1 = bs_guess(i-1,:)'; b_ip1 = bs_guess(i+1,:)'; 
                    u_i = obj.input_data(i,:)'; 
                    x_i = x_traj(i,:)'; 
                    dLdbs = [dLdbs, transpose(lam_traj(i+1,:)*obj.linzd_data.B(x_i,u_i) ...
                        - (2*b_i-b_im1-b_ip1)'*Z)]; 
                end 
                b_Nm1 = bs_guess(end,:)'; b_Nm2 = bs_guess(end-1,:)'; 
                dLdbs = [dLdbs, transpose(lam_traj(N+1,:)*obj.linzd_data.B(x_i,u_i) ...
                    + (b_Nm1-b_Nm2)'*Z)]; 
                b_0 =  bs_guess(1,:)'; 
                u_0 = obj.input_data(1,:)'; 
                x_0 = x_traj(1,:)'; 
                if obj.C_switch_data(1)==0 % y_traj[0] <-- h/h_ext 
                    dLdx0 = obj.adjsys_data.A_T(x_0,u_0,b_0)*lam_traj(2,:)' ...
                        - obj.adjsys_data.C_ext_T(x_0)*obj.weight*del_y(1,:)'; 
                else 
                    dLdx0 = obj.adjsys_data.A_T(x_0,u_0,b_0)*lam_traj(2,:)' ...
                        - obj.adjsys_data.C_T(x_0)*obj.weight*del_y(1,:)'; 
                end 
                % S4. Update 
                delK_update = obj.alpha*N*diag(dLdKvec); 
                delbs_update = obj.alpha*N*dLdbs; 
                delx0_update = obj.alpha*N*dLdx0; 
                if iter==1  
%                     alK = (percent_update(1)/100)*min(abs(diag(K_guess))./abs(diag(delK_update))); 
%                     albs = (percent_update(1)/100)*min(abs(bs_guess)./abs(delbs_update)); 
%                     alx0 = (percent_update(end)/100)*min(abs(x0_guess)./abs(delx0_update)); 
                    % alx0 = (percent_update(end)/100)*min(abs([240;23;72;87;1;1;1;1;1;1;1])./abs(delx0_update)); 
                    alK = 16e-4*(percent_update(1)/100)*4e-21; % 4e-21 is ~great for 12m 
                    albs = 10e-4*(120/N)*(percent_update(1)/100)*1e-7; % 1e-7 is ~great for 12m 
                    alx0 = 10e-1*(120/N)*(percent_update(end)/100)*1e-8; % 1e-8 is ~great for 12m 
                    alK = 1e-4*(percent_update(1)/100)*4e-21; % 4e-21 is ~great for 12m 
                    albs = 1e-2*(120/N)*(percent_update(1)/100)*1e-7; % 1e-7 is ~great for 12m 
                    alx0 = 1e-1*(120/N)*(percent_update(end)/100)*1e-8; % 1e-8 is ~great for 12m 
                end 
                % condition break 
                if sum(isnan(delK_update(:))) || sum(isnan(delbs_update(:))) || sum(isnan(delx0_update(:))) 
                    % K = K_guess; bs = bs_guess; x0 = x0_guess; 
                    % save to_ili_res2 K bs x0
                    [K_guess,bs_guess,x0_guess] = saved_guess{:}; 
                    factr = 1; 
                    warning('NaN now!') 
                    break; 
                end 
                % 
                K_guess = K_guess - alK*delK_update; 
                bs_guess = bs_guess - albs*delbs_update'; 
                q_gen = @(q,imu_w,bk) q + dT*0.5*S_w(K_guess(4:6,4:6)*imu_w + bk(4:6))*q; 
                f_q = @(q,imu_w,bk) q_gen(q,imu_w,bk)/norm(q_gen(q,imu_w,bk)); 
                f_v = @(q,v,imu_a,bk) v + dT*(C_q(q)*(K_guess(1:3,1:3)*imu_a + bk(1:3)) - [0;0;earth_gravity]); 
                guess_sys_data.g = @(x,u,bk) [zeros(4,1);f_q(x(5:8),u(4:6),bk);f_v(x(5:8),x(9:11),u(1:3),bk)]; 
                x0_guess = x0_guess - alx0*delx0_update; 
                obj.to_sys_pred_results.sys_data.bs_guess = bs_guess; 
                % test: disp(alK*delK_update); disp(albs*delbs_update); disp(alx0*delx0_update) 
            end 
            obj.to_sys_pred_results.sys_data = guess_sys_data; 
            obj.to_sys_pred_results.sys_data.x0_guess = x0_guess; 
            obj.to_sys_pred_results.sys_data.K_guess = K_guess; 
            obj.to_sys_pred_results.sys_data.bs_guess = bs_guess; 
        end 
        % EKF 
        function [x_est_traj,y_traj,y_fulltraj] = eval_ekf_simple(varargin) 
            obj = varargin{1}; 
            if nargin==2 
                guess_sys_data = []; 
                obj.ekf_data.x_est = obj.sys_data.x0; 
                obj.ekf_data.p_est = varargin{2}*eye(length(obj.sys_data.x0)); 
                y_traj_noisy = []; 
            elseif nargin==3 
                guess_sys_data = []; 
                obj.ekf_data.x_est = varargin{2}; 
                obj.ekf_data.p_est = varargin{3}*eye(length(obj.sys_data.x0)); 
                y_traj_noisy = []; 
            elseif nargin==4 
                guess_sys_data = varargin{2}; 
                obj.ekf_data.x_est = varargin{3}; 
                obj.ekf_data.p_est = varargin{4}*eye(length(obj.sys_data.x0)); 
                y_traj_noisy = []; 
            elseif nargin==5 
                guess_sys_data = varargin{2}; 
                obj.ekf_data.x_est = varargin{3}; 
                obj.ekf_data.p_est = varargin{4}*eye(length(obj.sys_data.x0)); 
                y_traj_noisy = varargin{5}; 
            end 
            N = obj.sys_params.N; 
            n = obj.sys_params.n; 
            x_est_traj = zeros(N+1,n); 
            % Initial state conditions
            if ~isfield(obj.ekf_data,'x_est') 
                obj.ekf_data.x_est = zeros(length(obj.sys_data.x0), 1);        
                obj.ekf_data.p_est = 100*ones(length(obj.sys_data.x0)); 
            end
            x_est_traj(1,:) = obj.ekf_data.x_est; 
            if isempty(y_traj_noisy) 
                y_traj_noisy = obj.traj_data.mesrd_noisy; 
            end 
            if obj.C_switch_data(1)==0 % y_traj[0] <-- h/h_ext 
                y_traj = transpose(obj.sys_data.h_ext(obj.ekf_data.x_est)); 
            else 
                y_traj = transpose(obj.sys_data.h(obj.ekf_data.x_est)); 
            end 
            y_fulltraj = y_traj; 
            all_klmn_gain = []; 
            for i=1:N 
                u_i = obj.input_data(i,:)'; 
                y_ip1 = y_traj_noisy(i+1,:)'; 
                [x_best, ~, klmn_gain] = obj.get_ekf_simple_step(i,y_ip1,u_i,guess_sys_data); 
                x_est_traj(i+1,:) = x_best'; 
                if sum(i==obj.C_switch_data)>0 
                    yhat_i = obj.sys_data.h_ext(x_best); 
                else 
                    yhat_i = obj.sys_data.h(x_best); 
                end 
                y_traj = [y_traj; transpose(yhat_i)]; 
                y_fulltraj = [y_fulltraj; transpose(obj.sys_data.h_ext(x_best))]; 
                all_klmn_gain = [all_klmn_gain, klmn_gain(:)]; 
            end 
            obj.efk_traj_results.states = x_est_traj; 
            obj.kalman_gain = transpose(all_klmn_gain); 
        end 
        function [x_est_traj,y_traj,y_fulltraj] = eval_ekf(varargin) 
            obj = varargin{1}; 
            if nargin==2 
                guess_sys_data = []; 
                obj.ekf_data.x_est = obj.sys_data.x0; 
                obj.ekf_data.p_est = varargin{2}*eye(length(obj.sys_data.x0)); 
                y_traj_noisy = []; 
            elseif nargin==3 
                guess_sys_data = []; 
                obj.ekf_data.x_est = varargin{2}; 
                obj.ekf_data.p_est = varargin{3}*eye(length(obj.sys_data.x0)); 
                y_traj_noisy = []; 
            elseif nargin==4 
                guess_sys_data = varargin{2}; 
                obj.ekf_data.x_est = varargin{3}; 
                obj.ekf_data.p_est = varargin{4}*eye(length(obj.sys_data.x0)); 
                y_traj_noisy = []; 
            elseif nargin==5 
                guess_sys_data = varargin{2}; 
                obj.ekf_data.x_est = varargin{3}; 
                obj.ekf_data.p_est = varargin{4}*eye(length(obj.sys_data.x0)); 
                y_traj_noisy = varargin{5}; 
            end 
            N = obj.sys_params.N; 
            n = obj.sys_params.n; 
            x_est_traj = zeros(N+1,n); 
            % Initial state conditions
            if ~isfield(obj.ekf_data,'x_est') 
                obj.ekf_data.x_est = zeros(length(obj.sys_data.x0), 1);        
                obj.ekf_data.p_est = 100*ones(length(obj.sys_data.x0)); 
            end
            x_est_traj(1,:) = obj.ekf_data.x_est; 
            if isempty(y_traj_noisy) 
                y_traj_noisy = obj.traj_data.mesrd_noisy; 
            end 
            if obj.C_switch_data(1)==0 % y_traj[0] <-- h/h_ext 
                y_traj = transpose(obj.sys_data.h_ext(obj.ekf_data.x_est)); 
            else 
                y_traj = transpose(obj.sys_data.h(obj.ekf_data.x_est)); 
            end 
            y_fulltraj = y_traj; 
            all_klmn_gain = []; 
            for i=1:N 
                u_i = obj.input_data(i,:)'; 
                y_ip1 = y_traj_noisy(i+1,:)'; 
                [x_best, ~, klmn_gain] = obj.get_ekf_step(i,y_ip1,u_i,guess_sys_data); 
                x_est_traj(i+1,:) = x_best'; 
                if sum(i==obj.C_switch_data)>0 
                    yhat_i = obj.sys_data.h_ext(x_best); 
                else 
                    yhat_i = obj.sys_data.h(x_best); 
                end 
                y_traj = [y_traj; transpose(yhat_i)]; 
                y_fulltraj = [y_fulltraj; transpose(obj.sys_data.h_ext(x_best))]; 
                all_klmn_gain = [all_klmn_gain, klmn_gain(:)]; 
            end 
            obj.efk_traj_results.states = x_est_traj; 
            obj.kalman_gain = transpose(all_klmn_gain); 
        end 
        function [x_est_traj,y_traj,y_fulltraj] = eval_shifted_ekf(varargin) 
            obj = varargin{1}; 
            tmpCsw = obj.C_switch_data; 
            obj.C_switch_data(1:end-1) = obj.C_switch_data(1:end-1)+1; % shift the measurement identifier 
            y_traj_noisy = obj.traj_data.mesrd_noisy; 
            y_traj_noisy = [y_traj_noisy(1,:); y_traj_noisy(1:end-2,:); y_traj_noisy(end,:)]; % shift the measurements 
            varargin = [varargin, y_traj_noisy]; 
            [x_est_traj,y_traj,y_fulltraj] = obj.eval_ekf(varargin{2:end}); 
            obj.C_switch_data = tmpCsw; 
        end 
        function [x_est_traj,y_traj,y_fulltraj,del_y] = eval_ekf_unknwn_dT_simple(varargin) 
            obj = varargin{1}; 
            if nargin==2 
                guess_sys_data = []; 
                obj.ekf_data.x_est = obj.sys_data.x0; 
                obj.ekf_data.p_est = varargin{2}*eye(length(obj.sys_data.x0)); 
                y_traj_noisy = []; 
            elseif nargin==3 
                guess_sys_data = []; 
                obj.ekf_data.x_est = varargin{2}; 
                obj.ekf_data.p_est = varargin{3}*eye(length(obj.sys_data.x0)); 
                y_traj_noisy = []; 
            elseif nargin==4 
                guess_sys_data = varargin{2}; 
                obj.ekf_data.x_est = varargin{3}; 
                obj.ekf_data.p_est = varargin{4}*eye(length(obj.sys_data.x0)); 
                y_traj_noisy = []; 
            elseif nargin==5 
                guess_sys_data = varargin{2}; 
                obj.ekf_data.x_est = varargin{3}; 
                obj.ekf_data.p_est = varargin{4}*eye(length(obj.sys_data.x0)); 
                y_traj_noisy = varargin{5}; 
            end 
            N = obj.sys_params.N; 
            n = obj.sys_params.n; 
            x_est_traj = zeros(N+1,n); 
            % Initial state conditions
            if ~isfield(obj.ekf_data,'x_est') 
                obj.ekf_data.x_est = zeros(length(obj.sys_data.x0), 1);        
                obj.ekf_data.p_est = 100*ones(length(obj.sys_data.x0)); 
            end
            x_est_traj(1,:) = obj.ekf_data.x_est; 
            if isempty(y_traj_noisy) 
                y_traj_noisy = obj.traj_data.mesrd_noisy; 
            end 
            if obj.C_switch_data(1)==0 % y_traj[0] <-- h/h_ext 
                y_traj = transpose(obj.sys_data.h_ext(obj.ekf_data.x_est)); 
            else 
                y_traj = transpose(obj.sys_data.h(obj.ekf_data.x_est)); 
            end 
            y_fulltraj = y_traj; 
            all_klmn_gain = []; 
            for i=1:N 
                u_i = obj.input_data(i,:)'; 
                y_ip1 = y_traj_noisy(i+1,:)'; 
                [x_best, ~, klmn_gain] = obj.get_ekf_unkwn_dT_step(i,y_ip1,u_i,guess_sys_data); 
                x_est_traj(i+1,:) = x_best'; 
                if sum(i==obj.C_switch_data)>0 
                    yhat_i = obj.sys_data.h_ext(x_best); 
                else 
                    yhat_i = obj.sys_data.h(x_best); 
                end 
                y_traj = [y_traj; transpose(yhat_i)]; 
                y_fulltraj = [y_fulltraj; transpose(obj.sys_data.h_ext(x_best))]; 
                all_klmn_gain = [all_klmn_gain, klmn_gain(:)]; 
            end 
            del_y = y_traj_noisy - y_traj; 
            obj.efk_traj_results.states = x_est_traj; 
            obj.kalman_gain = transpose(all_klmn_gain); 
        end 
        function [x_est_traj,y_traj,y_fulltraj,del_y] = eval_ekf_unknwn_dT_vel_scaled_simple(varargin) 
            obj = varargin{1}; 
            if nargin==2 
                guess_sys_data = []; 
                obj.ekf_data.x_est = obj.sys_data.x0; 
                obj.ekf_data.p_est = varargin{2}*eye(length(obj.sys_data.x0)); 
                y_traj_noisy = []; 
            elseif nargin==3 
                guess_sys_data = []; 
                obj.ekf_data.x_est = varargin{2}; 
                obj.ekf_data.p_est = varargin{3}*eye(length(obj.sys_data.x0)); 
                y_traj_noisy = []; 
            elseif nargin==4 
                guess_sys_data = varargin{2}; 
                obj.ekf_data.x_est = varargin{3}; 
                obj.ekf_data.p_est = varargin{4}*eye(length(obj.sys_data.x0)); 
                y_traj_noisy = []; 
            elseif nargin==5 
                guess_sys_data = varargin{2}; 
                obj.ekf_data.x_est = varargin{3}; 
                obj.ekf_data.p_est = varargin{4}*eye(length(obj.sys_data.x0)); 
                y_traj_noisy = varargin{5}; 
            end 
            N = obj.sys_params.N; 
            n = obj.sys_params.n; 
            x_est_traj = zeros(N+1,n); 
            % Initial state conditions
            if ~isfield(obj.ekf_data,'x_est') 
                obj.ekf_data.x_est = zeros(length(obj.sys_data.x0), 1);        
                obj.ekf_data.p_est = 100*ones(length(obj.sys_data.x0)); 
            end
            x_est_traj(1,:) = obj.ekf_data.x_est; 
            if isempty(y_traj_noisy) 
                y_traj_noisy = obj.traj_data.mesrd_noisy; 
            end 
            if obj.C_switch_data(1)==0 % y_traj[0] <-- h/h_ext 
                y_traj = transpose(obj.sys_data.h_ext(obj.ekf_data.x_est)); 
            else 
                y_traj = transpose(obj.sys_data.h(obj.ekf_data.x_est)); 
            end 
            y_fulltraj = y_traj; 
            all_klmn_gain = []; 
            for i=1:N 
                u_i = obj.input_data(i,:)'; 
                y_ip1 = y_traj_noisy(i+1,:)'; 
                [x_best, ~, klmn_gain] = obj.get_ekf_unkwn_dT_vel_scaled_step(i,y_ip1,u_i,guess_sys_data); 
                x_est_traj(i+1,:) = x_best'; 
                if sum(i==obj.C_switch_data)>0 
                    yhat_i = obj.sys_data.h_ext(x_best); 
                else 
                    yhat_i = obj.sys_data.h(x_best); 
                end 
                y_traj = [y_traj; transpose(yhat_i)]; 
                y_fulltraj = [y_fulltraj; transpose(obj.sys_data.h_ext(x_best))]; 
                all_klmn_gain = [all_klmn_gain, klmn_gain(:)]; 
            end 
            del_y = y_traj_noisy - y_traj; 
            obj.efk_traj_results.states = x_est_traj; 
            obj.kalman_gain = transpose(all_klmn_gain); 
        end 
        function [x_est_traj,y_traj,y_fulltraj,del_y] = eval_ekfnoC_unknwn_dT_vel_scaled_simple(varargin) 
            obj = varargin{1}; 
            if nargin==2 
                guess_sys_data = []; 
                obj.ekf_data.x_est = obj.sys_data.x0; 
                obj.ekf_data.p_est = varargin{2}*eye(length(obj.sys_data.x0)); 
                y_traj_noisy = []; 
            elseif nargin==3 
                guess_sys_data = []; 
                obj.ekf_data.x_est = varargin{2}; 
                obj.ekf_data.p_est = varargin{3}*eye(length(obj.sys_data.x0)); 
                y_traj_noisy = []; 
            elseif nargin==4 
                guess_sys_data = varargin{2}; 
                obj.ekf_data.x_est = varargin{3}; 
                obj.ekf_data.p_est = varargin{4}*eye(length(obj.sys_data.x0)); 
                y_traj_noisy = []; 
            elseif nargin==5 
                guess_sys_data = varargin{2}; 
                obj.ekf_data.x_est = varargin{3}; 
                obj.ekf_data.p_est = varargin{4}*eye(length(obj.sys_data.x0)); 
                y_traj_noisy = varargin{5}; 
            end 
            N = obj.sys_params.N; 
            n = obj.sys_params.n; 
            x_est_traj = zeros(N+1,n); 
            % Initial state conditions
            if ~isfield(obj.ekf_data,'x_est') 
                obj.ekf_data.x_est = zeros(length(obj.sys_data.x0), 1);        
                obj.ekf_data.p_est = 100*ones(length(obj.sys_data.x0)); 
            end
            x_est_traj(1,:) = obj.ekf_data.x_est; 
            if isempty(y_traj_noisy) 
                y_traj_noisy = obj.traj_data.mesrd_noisy; 
            end 
            if obj.C_switch_data(1)==0 % y_traj[0] <-- h/h_ext 
                y_traj = transpose(obj.sys_data.h_ext(obj.ekf_data.x_est)); 
            else 
                y_traj = transpose(obj.sys_data.h(obj.ekf_data.x_est)); 
            end 
            y_fulltraj = y_traj; 
            all_klmn_gain = []; 
            for i=1:N 
                u_i = obj.input_data(i,:)'; 
                y_ip1 = y_traj_noisy(i+1,:)'; 
                [x_best, ~, klmn_gain] = obj.get_ekfnoC_unkwn_dT_vel_scaled_step(i,y_ip1,u_i,guess_sys_data); 
                x_est_traj(i+1,:) = x_best'; 
                if sum(i==obj.C_switch_data)>0 
                    yhat_i = obj.sys_data.h_ext(x_best); 
                else 
                    yhat_i = obj.sys_data.h(x_best); 
                end 
                y_traj = [y_traj; transpose(yhat_i)]; 
                y_fulltraj = [y_fulltraj; transpose(obj.sys_data.h_ext(x_best))]; 
                all_klmn_gain = [all_klmn_gain, klmn_gain(:)]; 
            end 
            del_y = y_traj_noisy - y_traj; 
            obj.efk_traj_results.states = x_est_traj; 
            obj.kalman_gain = transpose(all_klmn_gain); 
        end 
        function [x_est_traj,y_traj,y_fulltraj,del_y] = eval_ekfvm_unknwn_dT_vel_scaled_simple(varargin) 
            obj = varargin{1}; 
            if nargin==2 
                guess_sys_data = []; 
                obj.ekf_data.x_est = obj.sys_data.x0; 
                obj.ekf_data.p_est = varargin{2}*eye(length(obj.sys_data.x0)); 
                y_traj_noisy = []; 
            elseif nargin==3 
                guess_sys_data = []; 
                obj.ekf_data.x_est = varargin{2}; 
                obj.ekf_data.p_est = varargin{3}*eye(length(obj.sys_data.x0)); 
                y_traj_noisy = []; 
            elseif nargin==4 
                guess_sys_data = varargin{2}; 
                obj.ekf_data.x_est = varargin{3}; 
                obj.ekf_data.p_est = varargin{4}*eye(length(obj.sys_data.x0)); 
                y_traj_noisy = []; 
            elseif nargin==5 
                guess_sys_data = varargin{2}; 
                obj.ekf_data.x_est = varargin{3}; 
                obj.ekf_data.p_est = varargin{4}*eye(length(obj.sys_data.x0)); 
                y_traj_noisy = varargin{5}; 
            end 
            N = obj.sys_params.N; 
            n = obj.sys_params.n; 
            x_est_traj = zeros(N+1,n); 
            % Initial state conditions
            if ~isfield(obj.ekf_data,'x_est') 
                obj.ekf_data.x_est = zeros(length(obj.sys_data.x0), 1);        
                obj.ekf_data.p_est = 100*ones(length(obj.sys_data.x0)); 
            end
            x_est_traj(1,:) = obj.ekf_data.x_est; 
            if isempty(y_traj_noisy) 
                y_traj_noisy = obj.traj_data.mesrd_noisy; 
            end 
            if obj.C_switch_data(1)==0 % y_traj[0] <-- h/h_ext 
                y_traj = transpose(obj.sys_data.h_ext(obj.ekf_data.x_est)); 
            else 
                y_traj = transpose(obj.sys_data.h(obj.ekf_data.x_est)); 
            end 
            y_fulltraj = y_traj; 
            all_klmn_gain = []; 
            for i=1:N 
                u_i = obj.input_data(i,:)'; 
                y_ip1 = y_traj_noisy(i+1,:)'; 
                [x_best, ~, klmn_gain] = obj.get_ekfvm_unkwn_dT_vel_scaled_step(i,y_ip1,u_i,guess_sys_data); 
                x_est_traj(i+1,:) = x_best'; 
                % if sum(i==obj.C_switch_data)>0 
                yhat_i = obj.sys_data.h_ext(x_best); 
                % else 
                %     yhat_i = obj.sys_data.h(x_best); 
                % end 
                y_traj = [y_traj; transpose(yhat_i)]; 
                y_fulltraj = [y_fulltraj; transpose(obj.sys_data.h_ext(x_best))]; 
                all_klmn_gain = [all_klmn_gain, klmn_gain(:)]; 
            end 
            del_y = y_traj_noisy - y_traj; 
            obj.efk_traj_results.states = x_est_traj; 
            obj.kalman_gain = transpose(all_klmn_gain); 
        end 
        function [x_est_traj,y_traj,y_fulltraj,del_y] = eval_ekfvm_unknwn_dT_vel_scaled_varbleR_simple(varargin) 
            obj = varargin{1}; 
            if nargin==2 
                guess_sys_data = []; 
                obj.ekf_data.x_est = obj.sys_data.x0; 
                obj.ekf_data.p_est = varargin{2}*eye(length(obj.sys_data.x0)); 
                y_traj_noisy = []; 
            elseif nargin==3 
                guess_sys_data = []; 
                obj.ekf_data.x_est = varargin{2}; 
                obj.ekf_data.p_est = varargin{3}*eye(length(obj.sys_data.x0)); 
                y_traj_noisy = []; 
            elseif nargin==4 
                guess_sys_data = varargin{2}; 
                obj.ekf_data.x_est = varargin{3}; 
                obj.ekf_data.p_est = varargin{4}*eye(length(obj.sys_data.x0)); 
                y_traj_noisy = []; 
            elseif nargin==5 
                guess_sys_data = varargin{2}; 
                obj.ekf_data.x_est = varargin{3}; 
                obj.ekf_data.p_est = varargin{4}*eye(length(obj.sys_data.x0)); 
                y_traj_noisy = varargin{5}; 
            end 
            N = obj.sys_params.N; 
            n = obj.sys_params.n; 
            x_est_traj = zeros(N+1,n); 
            % Initial state conditions
            if ~isfield(obj.ekf_data,'x_est') 
                obj.ekf_data.x_est = zeros(length(obj.sys_data.x0), 1);        
                obj.ekf_data.p_est = 100*ones(length(obj.sys_data.x0)); 
            end
            x_est_traj(1,:) = obj.ekf_data.x_est; 
            if isempty(y_traj_noisy) 
                y_traj_noisy = obj.traj_data.mesrd_noisy; 
            end 
            if obj.C_switch_data(1)==0 % y_traj[0] <-- h/h_ext 
                y_traj = transpose(obj.sys_data.h_ext(obj.ekf_data.x_est)); 
            else 
                y_traj = transpose(obj.sys_data.h(obj.ekf_data.x_est)); 
            end 
            y_fulltraj = y_traj; 
            all_klmn_gain = []; 
            for i=1:N 
                u_i = obj.input_data(i,:)'; 
                y_ip1 = y_traj_noisy(i+1,:)'; 
                [x_best, ~, klmn_gain] = obj.get_ekfvm_unkwn_dT_vel_scaled_varbleR_step(i,y_ip1,u_i,guess_sys_data); 
                x_est_traj(i+1,:) = x_best'; 
                % if sum(i==obj.C_switch_data)>0 
                yhat_i = obj.sys_data.h_ext(x_best); 
                % else 
                %     yhat_i = obj.sys_data.h(x_best); 
                % end 
                y_traj = [y_traj; transpose(yhat_i)]; 
                y_fulltraj = [y_fulltraj; transpose(obj.sys_data.h_ext(x_best))]; 
                all_klmn_gain = [all_klmn_gain, klmn_gain(:)]; 
            end 
            del_y = y_traj_noisy - y_traj; 
            obj.efk_traj_results.states = x_est_traj; 
            obj.kalman_gain = transpose(all_klmn_gain); 
        end 
        % New 
        function [K_guess,bs_guess,x0_guess,factr,y_fulltraj,W,del_y] = eval_ektopt_older(obj,percent_update,...
                K_guess,bs_guess,x0_guess,dT,C_q,S_w,earth_gravity) 
%             obj = varargin{1}; 
%             if nargin==2 
%                 obj.ekf_data.x_est = obj.sys_data.x0; 
%                 obj.ekf_data.p_est = varargin{2}*eye(length(obj.sys_data.x0)); 
%             elseif nargin==3 
%                 obj.ekf_data.x_est = varargin{2}; 
%                 obj.ekf_data.p_est = varargin{3}*eye(length(obj.sys_data.x0)); 
%             end 
%             N = obj.sys_params.N; 
%             n = obj.sys_params.n; 
%             x_est_traj = zeros(N+1,n); 
%             % Initial state conditions
%             if ~isfield(obj.ekf_data,'x_est') 
%                 obj.ekf_data.x_est = zeros(length(obj.sys_data.x0), 1);        
%                 obj.ekf_data.p_est = 100*ones(length(obj.sys_data.x0)); 
%             end
%             x_est_traj(1,:) = obj.ekf_data.x_est; 
%             y_traj_noisy = obj.traj_data.mesrd_noisy; 
            if ~isfield(obj.to_sys_pred_results,'sys_data') 
                obj.to_sys_pred_results.sys_data.f = obj.sys_data.f_guess; 
                obj.to_sys_pred_results.sys_data.g = obj.sys_data.g_guess; 
                obj.to_sys_pred_results.sys_data.h = obj.sys_data.h_guess; 
                obj.to_sys_pred_results.sys_data.h_ext = obj.sys_data.h_ext_guess; 
                obj.to_sys_pred_results.sys_data.x0_guess = obj.sys_data.x0_guess; 
            end 
            % 
            factr = 1; 
            saved_guess = {K_guess,bs_guess,x0_guess}; 
            % 
            N = obj.sys_params.N; 
            obj.alpha = 0.3/N^2; 
            guess_sys_data = obj.to_sys_pred_results.sys_data; 
            % x0_guess = obj.sys_data.x0_guess; 
            % obj.weight = eye(obj.sys_params.m); 
            obj.weight = [8.15849660302496/N^2,0,0,0;0,4151641837221.92,0,0;0,0,4151641837221.92,0;0,0,0,1647724.67444092]; % 
            % obj.weight = 1e-10*[0.00603838048126849,0,0,0;0,7.48506940906427e+19,0,0;0,0,7.48506940906427e+19,0;0,0,0,11483.7188104406]; 
            W = obj.weight; 
            % Way-1: how to get weight W: (no changes) 
            % >> dv_all = ([-eye(N),zeros(N,1)] + [zeros(N,1),eye(N)])*y_fulltraj 
            % >> dv_all = [dv_all(:,1),0.5*(abs(dv_all(:,2))+abs(dv_all(:,3))),dv_all(:,4)] 
            % >> Q_diag = 1./mean(dv_all,1).^2 
            % >> W = diag([Q_diag(1),Q_diag(2)*[1,1],Q_diag(3)]) 
            % x0_guess = obj.sys_data.x0; 
            % Way-2: how to get weight W: (result blows up) 
            % >> dv_all = del_y(end,:).^2 
            % >> dv_all = [dv_all(:,1),0.5*(abs(dv_all(:,2))+abs(dv_all(:,3))),dv_all(:,4)] 
            % >> Q_diag = 1./dv_all.^2 
            % >> W = diag([Q_diag(1),Q_diag(2)*[1,1],Q_diag(3)]) 
            % x0_guess = obj.sys_data.x0; 
            for iter=1:obj.max_iter 
                % S1. Fwd EKF sim       
                [x_est_traj,y_traj,y_fulltraj] = obj.eval_ekf_simple(guess_sys_data,x0_guess,N); 
                % [x_est_traj,y_traj,y_fulltraj] = obj.eval_shifted_ekf(guess_sys_data,obj.sys_data.x0_guess,N); 
                % S2. Bckwd sim 
                del_y = obj.traj_data.mesrd_noisy - y_traj; 
                lam_traj = obj.get_bwdsim_adjoint(del_y,x_est_traj); 
                % S3. Grads 
                dLdKvec = 0; 
                for i=1:N 
                    u_i = obj.input_data(i,:)'; 
                    x_i = x_est_traj(i,:)'; 
                    dLdKvec = dLdKvec + transpose(...
                        (lam_traj(i+1,:)*obj.linzd_data.B(x_i,u_i))*diag(obj.input_data(i,:))); 
                end 
                dLdbs = 0; 
                for i=1:N 
                    u_i = obj.input_data(i,:)'; 
                    x_i = x_est_traj(i,:)'; 
                    dLdbs = dLdbs + transpose(lam_traj(i+1,:)*obj.linzd_data.B(x_i,u_i)); 
                end 
                u_0 = obj.input_data(1,:)'; 
                x_0 = x_est_traj(1,:)'; 
                if obj.C_switch_data(1)==0 % y_traj[0] <-- h/h_ext 
                    dLdx0 = obj.adjsys_data.A_T(x_0,u_0)*lam_traj(2,:)' ...
                        - obj.adjsys_data.C_ext_T(x_0)*obj.weight*del_y(1,:)'; 
                else 
                    dLdx0 = obj.adjsys_data.A_T(x_0,u_0)*lam_traj(2,:)' ...
                        - obj.adjsys_data.C_T(x_0)*obj.weight*del_y(1,:)'; 
                end 
                % S4. Update 
                delK_update = obj.alpha*N*diag(dLdKvec); 
                delbs_update = obj.alpha*N*dLdbs; 
                delx0_update = obj.alpha*N*dLdx0; 
                if iter==1  
%                     alK = (percent_update(1)/100)*min(abs(diag(K_guess))./abs(diag(delK_update))); 
%                     albs = (percent_update(1)/100)*min(abs(bs_guess)./abs(delbs_update)); 
%                     alx0 = (percent_update(end)/100)*min(abs(x0_guess)./abs(delx0_update)); 
                    % alx0 = (percent_update(end)/100)*min(abs([240;23;72;87;1;1;1;1;1;1;1])./abs(delx0_update)); 
                    alK = 86e-4*(percent_update(1)/100)*4e-21; % 4e-21 is ~great for 12m 
                    albs = 10e-4*(120/N)*(percent_update(1)/100)*1e-7; % 1e-7 is ~great for 12m 
                    alx0 = 10e-4*(120/N)*(percent_update(end)/100)*1e-8; % 1e-8 is ~great for 12m 
                    save learning_rates alK albs alx0 
                end 
                % condition break 
                if sum(isnan(delK_update(:))) || sum(isnan(delbs_update(:))) || sum(isnan(delx0_update(:))) 
                    % K = K_guess; bs = bs_guess; x0 = x0_guess; 
                    % save to_ili_res2 K bs x0
                    [K_guess,bs_guess,x0_guess] = saved_guess{:}; 
                    factr = 1; 
                    warning('NaN now!') 
                    break; 
                end 
                % 
                K_guess = K_guess - alK*delK_update; 
                % bs_guess = bs_guess - albs*repmat(delbs_update,1,size(bs_guess,1))'; 
                x0_guess = x0_guess - [alx0*delx0_update(1:end-length(delbs_update)); albs*delbs_update]; 
                q_gen = @(q,bs,imu_w) q + dT*0.5*S_w(K_guess(4:6,4:6)*imu_w + bs(4:6))*q; 
                f_q = @(q,bs,imu_w) q_gen(q,bs,imu_w)/norm(q_gen(q,bs,imu_w)); 
                f_v = @(q,v,bs,imu_a) v + dT*(C_q(q)*(K_guess(1:3,1:3)*imu_a + bs(1:3)) - [0;0;earth_gravity]); 
                guess_sys_data.g = @(x,u) [zeros(4,1);f_q(x(5:8),x(12:17),u(4:6));f_v(x(5:8),x(9:11),x(12:17),u(1:3));zeros(6,1)]; 
                % test: disp(alK*delK_update); disp(albs*delbs_update); disp(alx0*delx0_update) 
            end 
            obj.to_sys_pred_results.sys_data = guess_sys_data; 
            obj.to_sys_pred_results.sys_data.x0_guess = x0_guess; 
            obj.to_sys_pred_results.sys_data.K_guess = K_guess; 
            obj.to_sys_pred_results.sys_data.bs_guess = bs_guess; 
            obj.efk_traj_results.states = x_est_traj;  
        end 
        function [K_guess,bs_guess,x0_guess,factr,y_fulltraj,Q,del_x] = eval_ektopt_old(obj,percent_update,...
                K_guess,bs_guess,x0_guess,dT,C_q,S_w,earth_gravity) 
%             obj = varargin{1}; 
%             if nargin==2 
%                 obj.ekf_data.x_est = obj.sys_data.x0; 
%                 obj.ekf_data.p_est = varargin{2}*eye(length(obj.sys_data.x0)); 
%             elseif nargin==3 
%                 obj.ekf_data.x_est = varargin{2}; 
%                 obj.ekf_data.p_est = varargin{3}*eye(length(obj.sys_data.x0)); 
%             end 
%             N = obj.sys_params.N; 
%             n = obj.sys_params.n; 
%             x_est_traj = zeros(N+1,n); 
%             % Initial state conditions
%             if ~isfield(obj.ekf_data,'x_est') 
%                 obj.ekf_data.x_est = zeros(length(obj.sys_data.x0), 1);        
%                 obj.ekf_data.p_est = 100*ones(length(obj.sys_data.x0)); 
%             end
%             x_est_traj(1,:) = obj.ekf_data.x_est; 
%             y_traj_noisy = obj.traj_data.mesrd_noisy; 
            if ~isfield(obj.to_sys_pred_results.sys_data,'guess_sys_data') 
                obj.to_sys_pred_results.sys_data.f = obj.sys_data.f_guess; 
                obj.to_sys_pred_results.sys_data.g = obj.sys_data.g_guess; 
                obj.to_sys_pred_results.sys_data.h = obj.sys_data.h_guess; 
                obj.to_sys_pred_results.sys_data.h_ext = obj.sys_data.h_ext_guess; 
                obj.to_sys_pred_results.sys_data.x0_guess = obj.sys_data.x0_guess; 
            end 
            % 
            factr = 1; 
            saved_guess = {K_guess,bs_guess,x0_guess}; 
            % 
            N = obj.sys_params.N; 
            obj.alpha = 0.3/N^2; 
            guess_sys_data = obj.to_sys_pred_results.sys_data; 
            % x0_guess = obj.sys_data.x0_guess; 
            % obj.weight = eye(obj.sys_params.m); 
            obj.weight = [8.15849660302496/N^2,0,0,0;0,4151641837221.92,0,0;0,0,4151641837221.92,0;0,0,0,1647724.67444092]; % 
            Q = 1e0*diag([1,1e6*ones(1,2),1,ones(1,4),ones(1,3),ones(1,6)]); 
            % obj.weight = 1e-10*[0.00603838048126849,0,0,0;0,7.48506940906427e+19,0,0;0,0,7.48506940906427e+19,0;0,0,0,11483.7188104406]; 
            W = obj.weight; 
            % Way-1: how to get weight W: (no changes) 
            % >> dv_all = ([-eye(N),zeros(N,1)] + [zeros(N,1),eye(N)])*y_fulltraj 
            % >> dv_all = [dv_all(:,1),0.5*(abs(dv_all(:,2))+abs(dv_all(:,3))),dv_all(:,4)] 
            % >> Q_diag = 1./mean(dv_all,1).^2 
            % >> W = diag([Q_diag(1),Q_diag(2)*[1,1],Q_diag(3)]) 
            % x0_guess = obj.sys_data.x0; 
            % Way-2: how to get weight W: (result blows up) 
            % >> dv_all = del_y(end,:).^2 
            % >> dv_all = [dv_all(:,1),0.5*(abs(dv_all(:,2))+abs(dv_all(:,3))),dv_all(:,4)] 
            % >> Q_diag = 1./dv_all.^2 
            % >> W = diag([Q_diag(1),Q_diag(2)*[1,1],Q_diag(3)]) 
            % x0_guess = obj.sys_data.x0; 
            for iter=1:obj.max_iter 
                % S1. Fwd EKF sim       
                [x_est_traj,y_traj,y_fulltraj] = obj.eval_ekf(guess_sys_data,x0_guess,N); 
                % [x_est_traj,y_traj,y_fulltraj] = obj.eval_shifted_ekf(guess_sys_data,obj.sys_data.x0_guess,N); 
                % >> again 
                x_traj = obj.get_fwdsim_guess(guess_sys_data,x0_guess); 
                % S2. Bckwd sim 
                % del_y = obj.traj_data.mesrd_noisy - y_traj; 
                % lam_traj = obj.get_bwdsim_adjoint(del_y,x_est_traj); 
                del_x = x_traj - x_est_traj; 
                % lam_traj = obj.get_bwdsim_statemes_adjoint(del_x,x_est_traj,Q); 
                lam_traj = obj.get_bwdsim_ekf_adjoint(del_x,x_est_traj,Q); 
                % S3. Grads 
                dLdKvec = 0; 
                for i=1:N 
                    u_i = obj.input_data(i,:)'; 
                    x_i = x_est_traj(i,:)'; 
                    dLdKvec = dLdKvec + transpose(...
                        (lam_traj(i+1,:)*obj.linzd_data.B(x_i,u_i))*diag(obj.input_data(i,:))); 
                end 
                dLdbs = 0; 
                for i=1:N 
                    u_i = obj.input_data(i,:)'; 
                    x_i = x_est_traj(i,:)'; 
                    dLdbs = dLdbs + transpose(lam_traj(i+1,:)*obj.linzd_data.B(x_i,u_i)); 
                end 
                u_0 = obj.input_data(1,:)'; 
                x_0 = x_est_traj(1,:)'; 
                %                 if obj.C_switch_data(1)==0 % y_traj[0] <-- h/h_ext 
                %                     dLdx0 = obj.adjsys_data.A_T(x_0,u_0)*lam_traj(2,:)' ...
                %                         - obj.adjsys_data.C_ext_T(x_0)*obj.weight*del_y(1,:)'; 
                %                 else 
                %                     dLdx0 = obj.adjsys_data.A_T(x_0,u_0)*lam_traj(2,:)' ...
                %                         - obj.adjsys_data.C_T(x_0)*obj.weight*del_y(1,:)'; 
                % end 
                dLdx0 = obj.adjsys_data.A_T(x_0,u_0)*lam_traj(2,:)' - Q*del_x(1,:)'; 
                % S4. Update 
                delK_update = obj.alpha*N*diag(dLdKvec); 
                delbs_update = obj.alpha*N*dLdbs; 
                delx0_update = obj.alpha*N*dLdx0; 
                if iter==1  
%                     alK = (percent_update(1)/100)*min(abs(diag(K_guess))./abs(diag(delK_update))); 
%                     albs = (percent_update(1)/100)*min(abs(bs_guess)./abs(delbs_update)); 
%                     alx0 = (percent_update(end)/100)*min(abs(x0_guess)./abs(delx0_update)); 
                    % alx0 = (percent_update(end)/100)*min(abs([240;23;72;87;1;1;1;1;1;1;1])./abs(delx0_update)); 
                    alK = 86e-4*(percent_update(1)/100)*4e-21; % 4e-21 is ~great for 12m 
                    albs = 10e-4*(120/N)*(percent_update(1)/100)*1e-7; % 1e-7 is ~great for 12m 
                    alx0 = 10e-4*(120/N)*(percent_update(end)/100)*1e-8; % 1e-8 is ~great for 12m 
                    save learning_rates alK albs alx0 
                end 
                % condition break 
                if sum(isnan(delK_update(:))) || sum(isnan(delbs_update(:))) || sum(isnan(delx0_update(:))) 
                    % K = K_guess; bs = bs_guess; x0 = x0_guess; 
                    % save to_ili_res2 K bs x0
                    [K_guess,bs_guess,x0_guess] = saved_guess{:}; 
                    factr = 1; 
                    warning('NaN now!') 
                    break; 
                end 
                % 
                K_guess = K_guess - alK*delK_update; 
                % bs_guess = bs_guess - albs*repmat(delbs_update,1,size(bs_guess,1))'; 
                x0_guess = x0_guess - [alx0*delx0_update(1:end-length(delbs_update)); albs*delbs_update]; 
                q_gen = @(q,bs,imu_w) q + dT*0.5*S_w(K_guess(4:6,4:6)*imu_w + bs(4:6))*q; 
                f_q = @(q,bs,imu_w) q_gen(q,bs,imu_w)/norm(q_gen(q,bs,imu_w)); 
                f_v = @(q,v,bs,imu_a) v + dT*(C_q(q)*(K_guess(1:3,1:3)*imu_a + bs(1:3)) - [0;0;earth_gravity]); 
                guess_sys_data.g = @(x,u) [zeros(4,1);f_q(x(5:8),x(12:17),u(4:6));f_v(x(5:8),x(9:11),x(12:17),u(1:3));zeros(6,1)]; 
                % test: disp(alK*delK_update); disp(albs*delbs_update); disp(alx0*delx0_update) 
            end 
            obj.to_sys_pred_results.sys_data = guess_sys_data; 
            obj.to_sys_pred_results.sys_data.x0_guess = x0_guess; 
            obj.to_sys_pred_results.sys_data.K_guess = K_guess; 
            obj.to_sys_pred_results.sys_data.bs_guess = bs_guess; 
            obj.efk_traj_results.states = x_est_traj;  
        end 
        function [K_guess,bs_guess,x0_guess,factr,y_fulltraj,W_ekf,del_p] = eval_ektopt(obj,percent_update,...
                K_guess,bs_guess,x0_guess,dT,C_q,S_w,earth_gravity) 
%             obj = varargin{1}; 
%             if nargin==2 
%                 obj.ekf_data.x_est = obj.sys_data.x0; 
%                 obj.ekf_data.p_est = varargin{2}*eye(length(obj.sys_data.x0)); 
%             elseif nargin==3 
%                 obj.ekf_data.x_est = varargin{2}; 
%                 obj.ekf_data.p_est = varargin{3}*eye(length(obj.sys_data.x0)); 
%             end 
%             N = obj.sys_params.N; 
%             n = obj.sys_params.n; 
%             x_est_traj = zeros(N+1,n); 
%             % Initial state conditions
%             if ~isfield(obj.ekf_data,'x_est') 
%                 obj.ekf_data.x_est = zeros(length(obj.sys_data.x0), 1);        
%                 obj.ekf_data.p_est = 100*ones(length(obj.sys_data.x0)); 
%             end
%             x_est_traj(1,:) = obj.ekf_data.x_est; 
%             y_traj_noisy = obj.traj_data.mesrd_noisy; 
            if ~isfield(obj.to_sys_pred_results.sys_data,'guess_sys_data') 
                obj.to_sys_pred_results.sys_data.f = obj.sys_data.f_guess; 
                obj.to_sys_pred_results.sys_data.g = obj.sys_data.g_guess; 
                obj.to_sys_pred_results.sys_data.h = obj.sys_data.h_guess; 
                obj.to_sys_pred_results.sys_data.h_ext = obj.sys_data.h_ext_guess; 
                obj.to_sys_pred_results.sys_data.x0_guess = obj.sys_data.x0_guess; 
            end 
            % 
            factr = 1; 
            saved_guess = {K_guess,bs_guess,x0_guess}; 
            % 
            N = obj.sys_params.N; 
            obj.alpha = 0.3/N^2; 
            guess_sys_data = obj.to_sys_pred_results.sys_data; 
            % x0_guess = obj.sys_data.x0_guess; 
            % obj.weight = eye(obj.sys_params.m); 
            obj.weight = [8.15849660302496/N^2,0,0,0;0,4151641837221.92,0,0;0,0,4151641837221.92,0;0,0,0,1647724.67444092]; % 
            Q = 1e0*diag([1,1e6*ones(1,2),1,ones(1,4),ones(1,3),ones(1,6)]); 
            % obj.weight = 1e-10*[0.00603838048126849,0,0,0;0,7.48506940906427e+19,0,0;0,0,7.48506940906427e+19,0;0,0,0,11483.7188104406]; 
            W = obj.weight; 
            % 
            W_ekf = 1e0*diag([5e10*ones(1,2),1]); 
            P = [zeros(3,1),eye(3),zeros(3,7+6)]; 
            % tmpP = [zeros(1,N+1);eye(N),zeros(N,1)]; 
            % Pmap = diag([1,2*ones(1,N-1),1]) - tmpP - tmpP'; 
            % 
            % Way-1: how to get weight W: (no changes) 
            % >> dv_all = ([-eye(N),zeros(N,1)] + [zeros(N,1),eye(N)])*y_fulltraj 
            % >> dv_all = [dv_all(:,1),0.5*(abs(dv_all(:,2))+abs(dv_all(:,3))),dv_all(:,4)] 
            % >> Q_diag = 1./mean(dv_all,1).^2 
            % >> W = diag([Q_diag(1),Q_diag(2)*[1,1],Q_diag(3)]) 
            % x0_guess = obj.sys_data.x0; 
            % Way-2: how to get weight W: (result blows up) 
            % >> dv_all = del_y(end,:).^2 
            % >> dv_all = [dv_all(:,1),0.5*(abs(dv_all(:,2))+abs(dv_all(:,3))),dv_all(:,4)] 
            % >> Q_diag = 1./dv_all.^2 
            % >> W = diag([Q_diag(1),Q_diag(2)*[1,1],Q_diag(3)]) 
            % x0_guess = obj.sys_data.x0; 
            for iter=1:obj.max_iter 
                % S1. Fwd EKF sim       
                [x_est_traj,y_traj,y_fulltraj] = obj.eval_ekf(guess_sys_data,x0_guess,N); 
                % [x_est_traj,y_traj,y_fulltraj] = obj.eval_shifted_ekf(guess_sys_data,obj.sys_data.x0_guess,N); 
                % >> again 
                % x_traj = obj.get_fwdsim_guess(guess_sys_data,x0_guess); 
                % S2. Bckwd sim 
                % del_y = obj.traj_data.mesrd_noisy - y_traj; 
                % lam_traj = obj.get_bwdsim_adjoint(del_y,x_est_traj); 
                % del_x = x_traj - x_est_traj; 
                % lam_traj = obj.get_bwdsim_statemes_adjoint(del_x,x_est_traj,Q); 
                % lam_traj = obj.get_bwdsim_ekf_adjoint(del_x,x_est_traj,Q); 
                % del_p = Pmap*x_est_traj(:,2:4); 
                del_p = [[1,-1]*x_est_traj(1:2,2:4);...
                    2*x_est_traj(2:end-1,2:4)-x_est_traj(1:end-2,2:4)-x_est_traj(3:end,2:4);...
                    [-1,1]*x_est_traj(end-1:end,2:4)]; 
                lam_traj = obj.get_bwdsim_ekf_adjoint(del_p,x_est_traj,P'*W_ekf); 
                % S3. Grads 
                dLdKvec = 0; 
                for i=1:N 
                    u_i = obj.input_data(i,:)'; 
                    x_i = x_est_traj(i,:)'; 
                    dLdKvec = dLdKvec + transpose(...
                        (lam_traj(i+1,:)*obj.linzd_data.B(x_i,u_i))*diag(obj.input_data(i,:))); 
                end 
                dLdbs = 0; 
                for i=1:N 
                    u_i = obj.input_data(i,:)'; 
                    x_i = x_est_traj(i,:)'; 
                    dLdbs = dLdbs + transpose(lam_traj(i+1,:)*obj.linzd_data.B(x_i,u_i)); 
                end 
                u_0 = obj.input_data(1,:)'; 
                x_0 = x_est_traj(1,:)'; 
                %                 if obj.C_switch_data(1)==0 % y_traj[0] <-- h/h_ext 
                %                     dLdx0 = obj.adjsys_data.A_T(x_0,u_0)*lam_traj(2,:)' ...
                %                         - obj.adjsys_data.C_ext_T(x_0)*obj.weight*del_y(1,:)'; 
                %                 else 
                %                     dLdx0 = obj.adjsys_data.A_T(x_0,u_0)*lam_traj(2,:)' ...
                %                         - obj.adjsys_data.C_T(x_0)*obj.weight*del_y(1,:)'; 
                % end 
                % dLdx0 = obj.adjsys_data.A_T(x_0,u_0)*lam_traj(2,:)' - Q*del_x(1,:)'; 
                K_k = reshape(obj.kalman_gain(1,:),obj.sys_params.n,[]); 
                if obj.C_switch_data(1)==0 
                    M = eye(obj.sys_params.n) - K_k*obj.linzd_data.C_ext(x_0); 
                else 
                    M = eye(obj.sys_params.n) - K_k*obj.linzd_data.C(x_0); 
                end 
                dLdx0 = obj.adjsys_data.A_T(x_0,u_0)*transpose(M)*lam_traj(2,:)' ...
                    - P'*W_ekf*del_p(1,:)'; 
                % S4. Update 
                delK_update = obj.alpha*N*diag(dLdKvec); 
                delbs_update = obj.alpha*N*dLdbs; 
                delx0_update = obj.alpha*N*dLdx0; 
                if iter==1  
%                     alK = (percent_update(1)/100)*min(abs(diag(K_guess))./abs(diag(delK_update))); 
%                     albs = (percent_update(1)/100)*min(abs(bs_guess)./abs(delbs_update)); 
%                     alx0 = (percent_update(end)/100)*min(abs(x0_guess)./abs(delx0_update)); 
                    % alx0 = (percent_update(end)/100)*min(abs([240;23;72;87;1;1;1;1;1;1;1])./abs(delx0_update)); 
                    alK = 86e-1*(percent_update(1)/100)*4e-21; % 4e-21 is ~great for 12m 
                    albs = 10e-2*(120/N)*(percent_update(1)/100)*1e-7; % 1e-7 is ~great for 12m 
                    alx0 = 10e-1*(120/N)*(percent_update(end)/100)*1e-8; % 1e-8 is ~great for 12m 
                    save learning_rates alK albs alx0 
                end 
                % condition break 
                if sum(isnan(delK_update(:))) || sum(isnan(delbs_update(:))) || sum(isnan(delx0_update(:))) 
                    % K = K_guess; bs = bs_guess; x0 = x0_guess; 
                    % save to_ili_res2 K bs x0
                    [K_guess,bs_guess,x0_guess] = saved_guess{:}; 
                    factr = 1; 
                    warning('NaN now!') 
                    break; 
                end 
                % 
                K_guess = K_guess - alK*delK_update; 
                % bs_guess = bs_guess - albs*repmat(delbs_update,1,size(bs_guess,1))'; 
                x0_guess = x0_guess - [alx0*delx0_update(1:end-length(delbs_update)); albs*delbs_update]; 
                q_gen = @(q,bs,imu_w) q + dT*0.5*S_w(K_guess(4:6,4:6)*imu_w + bs(4:6))*q; 
                f_q = @(q,bs,imu_w) q_gen(q,bs,imu_w)/norm(q_gen(q,bs,imu_w)); 
                f_v = @(q,v,bs,imu_a) v + dT*(C_q(q)*(K_guess(1:3,1:3)*imu_a + bs(1:3)) - [0;0;earth_gravity]); 
                guess_sys_data.g = @(x,u) [zeros(4,1);f_q(x(5:8),x(12:17),u(4:6));f_v(x(5:8),x(9:11),x(12:17),u(1:3));zeros(6,1)]; 
                % test: disp(alK*delK_update); disp(albs*delbs_update); disp(alx0*delx0_update) 
            end 
            obj.to_sys_pred_results.sys_data = guess_sys_data; 
            obj.to_sys_pred_results.sys_data.x0_guess = x0_guess; 
            obj.to_sys_pred_results.sys_data.K_guess = K_guess; 
            obj.to_sys_pred_results.sys_data.bs_guess = bs_guess; 
            obj.efk_traj_results.states = x_est_traj;  
        end 
        % 
        function [K_guess,bs_guess,x0_guess,factr,y_fulltraj,W,del_y] = eval_ektopt_ver1(obj,percent_update,...
                K_guess,bs_guess,x0_guess,dT,C_q,S_w,earth_gravity) 
%             obj = varargin{1}; 
%             if nargin==2 
%                 obj.ekf_data.x_est = obj.sys_data.x0; 
%                 obj.ekf_data.p_est = varargin{2}*eye(length(obj.sys_data.x0)); 
%             elseif nargin==3 
%                 obj.ekf_data.x_est = varargin{2}; 
%                 obj.ekf_data.p_est = varargin{3}*eye(length(obj.sys_data.x0)); 
%             end 
%             N = obj.sys_params.N; 
%             n = obj.sys_params.n; 
%             x_est_traj = zeros(N+1,n); 
%             % Initial state conditions
%             if ~isfield(obj.ekf_data,'x_est') 
%                 obj.ekf_data.x_est = zeros(length(obj.sys_data.x0), 1);        
%                 obj.ekf_data.p_est = 100*ones(length(obj.sys_data.x0)); 
%             end
%             x_est_traj(1,:) = obj.ekf_data.x_est; 
%             y_traj_noisy = obj.traj_data.mesrd_noisy; 
            if ~isfield(obj.to_sys_pred_results.sys_data,'guess_sys_data') 
                obj.to_sys_pred_results.sys_data.f = obj.sys_data.f_guess; 
                obj.to_sys_pred_results.sys_data.g = obj.sys_data.g_guess; 
                obj.to_sys_pred_results.sys_data.h = obj.sys_data.h_guess; 
                obj.to_sys_pred_results.sys_data.h_ext = obj.sys_data.h_ext_guess; 
                obj.to_sys_pred_results.sys_data.x0_guess = obj.sys_data.x0_guess; 
            end 
            % 
            factr = 1; 
            saved_guess = {K_guess,bs_guess,x0_guess}; 
            % 
            N = obj.sys_params.N; 
            obj.alpha = 0.3/N^2; 
            guess_sys_data = obj.to_sys_pred_results.sys_data; 
            % x0_guess = obj.sys_data.x0_guess; 
            % obj.weight = eye(obj.sys_params.m); 
            obj.weight = [8.15849660302496/N^2,0,0,0;0,4151641837221.92,0,0;0,0,4151641837221.92,0;0,0,0,1647724.67444092]; % 
            % obj.weight = 1e-10*[0.00603838048126849,0,0,0;0,7.48506940906427e+19,0,0;0,0,7.48506940906427e+19,0;0,0,0,11483.7188104406]; 
            W = obj.weight; 
            % Way-1: how to get weight W: (no changes) 
            % >> dv_all = ([-eye(N),zeros(N,1)] + [zeros(N,1),eye(N)])*y_fulltraj 
            % >> dv_all = [dv_all(:,1),0.5*(abs(dv_all(:,2))+abs(dv_all(:,3))),dv_all(:,4)] 
            % >> Q_diag = 1./mean(dv_all,1).^2 
            % >> W = diag([Q_diag(1),Q_diag(2)*[1,1],Q_diag(3)]) 
            % x0_guess = obj.sys_data.x0; 
            % Way-2: how to get weight W: (result blows up) 
            % >> dv_all = del_y(end,:).^2 
            % >> dv_all = [dv_all(:,1),0.5*(abs(dv_all(:,2))+abs(dv_all(:,3))),dv_all(:,4)] 
            % >> Q_diag = 1./dv_all.^2 
            % >> W = diag([Q_diag(1),Q_diag(2)*[1,1],Q_diag(3)]) 
            % x0_guess = obj.sys_data.x0; 
            for iter=1:obj.max_iter 
                % S1. Fwd EKF sim       
                [x_est_traj,y_traj,y_fulltraj] = obj.eval_ekf(guess_sys_data,x0_guess,N); 
                % [x_est_traj,y_traj,y_fulltraj] = obj.eval_shifted_ekf(guess_sys_data,obj.sys_data.x0_guess,N); 
                % S2. Bckwd sim 
                del_y = obj.traj_data.mesrd_noisy - y_traj; 
                lam_traj = obj.get_bwdsim_bk_ltv_adjoint(del_y,x_est_traj); 
                % S3. Grads 
                dLdKvec = 0; 
                for i=1:N 
                    t = obj.sys_params.dT*(i-1); 
                    u_i = obj.input_data(i,:)'; 
                    x_i = x_est_traj(i,:)'; 
                    dLdKvec = dLdKvec + transpose(...
                        (lam_traj(i+1,:)*obj.linzd_data.B(t,x_i,u_i,diag(K_guess)))*diag(obj.input_data(i,:))); 
                end 
                dLdbs = 0; 
                for i=1:N 
                    t = obj.sys_params.dT*(i-1); 
                    u_i = obj.input_data(i,:)'; 
                    x_i = x_est_traj(i,:)'; 
                    dLdbs = dLdbs + transpose(lam_traj(i+1,:)*obj.linzd_data.B(t,x_i,u_i,diag(K_guess))); 
                end 
                u_0 = obj.input_data(1,:)'; 
                x_0 = x_est_traj(1,:)'; 
                if obj.C_switch_data(1)==0 % y_traj[0] <-- h/h_ext 
                    dLdx0 = obj.adjsys_data.A_T(0,x_0,u_0,diag(K_guess))*lam_traj(2,:)' ...
                        - obj.adjsys_data.C_ext_T(x_0)*obj.weight*del_y(1,:)'; 
                else 
                    dLdx0 = obj.adjsys_data.A_T(0,x_0,u_0,diag(K_guess))*lam_traj(2,:)' ...
                        - obj.adjsys_data.C_T(x_0)*obj.weight*del_y(1,:)'; 
                end 
                % S4. Update 
                delK_update = obj.alpha*N*diag(dLdKvec); 
                delbs_update = obj.alpha*N*dLdbs; 
                delx0_update = obj.alpha*N*dLdx0; 
                if iter==1  
%                     alK = (percent_update(1)/100)*min(abs(diag(K_guess))./abs(diag(delK_update))); 
%                     albs = (percent_update(1)/100)*min(abs(bs_guess)./abs(delbs_update)); 
%                     alx0 = (percent_update(end)/100)*min(abs(x0_guess)./abs(delx0_update)); 
                    % alx0 = (percent_update(end)/100)*min(abs([240;23;72;87;1;1;1;1;1;1;1])./abs(delx0_update)); 
                    alK = 86e-4*(percent_update(1)/100)*4e-21; % 4e-21 is ~great for 12m 
                    albs = 10e-4*(120/N)*(percent_update(1)/100)*1e-7; % 1e-7 is ~great for 12m 
                    alx0 = 10e-4*(120/N)*(percent_update(end)/100)*1e-8; % 1e-8 is ~great for 12m 
                    save learning_rates alK albs alx0 
                end 
                % condition break 
                if sum(isnan(delK_update(:))) || sum(isnan(delbs_update(:))) || sum(isnan(delx0_update(:))) 
                    % K = K_guess; bs = bs_guess; x0 = x0_guess; 
                    % save to_ili_res2 K bs x0
                    [K_guess,bs_guess,x0_guess] = saved_guess{:}; 
                    factr = 1; 
                    warning('NaN now!') 
                    break; 
                end 
                % 
                K_guess = K_guess - alK*delK_update; 
                % bs_guess = bs_guess - albs*repmat(delbs_update,1,size(bs_guess,1))'; 
                x0_guess = x0_guess - [alx0*delx0_update(1:end-length(delbs_update)); albs*delbs_update]; 
                %                 q_gen = @(q,bs,imu_w) q + dT*0.5*S_w(K_guess(4:6,4:6)*imu_w + bs(4:6))*q; 
                %                 f_q = @(q,bs,imu_w) q_gen(q,bs,imu_w)/norm(q_gen(q,bs,imu_w)); 
                %                 f_v = @(q,v,bs,imu_a) v + dT*(C_q(q)*(K_guess(1:3,1:3)*imu_a + bs(1:3)) - [0;0;earth_gravity]); 
                %                 guess_sys_data.g = @(t,x,u,prms) [zeros(4,1);f_q(x(5:8),x(12:17),u(4:6));f_v(x(5:8),x(9:11),x(12:17),u(1:3));zeros(6,1)]; 
                % test: disp(alK*delK_update); disp(albs*delbs_update); disp(alx0*delx0_update) 
                % 
                % obj.to_sys_pred_results.sys_data = guess_sys_data; 
                obj.to_sys_pred_results.sys_data.x0_guess = x0_guess; 
                obj.to_sys_pred_results.sys_data.K_guess = K_guess; 
                obj.to_sys_pred_results.sys_data.bs_guess = bs_guess; 
            end 
            obj.efk_traj_results.states = x_est_traj;  
        end 
        function [K_guess,bs_guess,x0_guess,factr,y_fulltraj,Q,del_x] = eval_ektopt_ver2(obj,percent_update,...
                K_guess,bs_guess,x0_guess,dT,C_q,S_w,earth_gravity) 
%             obj = varargin{1}; 
%             if nargin==2 
%                 obj.ekf_data.x_est = obj.sys_data.x0; 
%                 obj.ekf_data.p_est = varargin{2}*eye(length(obj.sys_data.x0)); 
%             elseif nargin==3 
%                 obj.ekf_data.x_est = varargin{2}; 
%                 obj.ekf_data.p_est = varargin{3}*eye(length(obj.sys_data.x0)); 
%             end 
%             N = obj.sys_params.N; 
%             n = obj.sys_params.n; 
%             x_est_traj = zeros(N+1,n); 
%             % Initial state conditions
%             if ~isfield(obj.ekf_data,'x_est') 
%                 obj.ekf_data.x_est = zeros(length(obj.sys_data.x0), 1);        
%                 obj.ekf_data.p_est = 100*ones(length(obj.sys_data.x0)); 
%             end
%             x_est_traj(1,:) = obj.ekf_data.x_est; 
%             y_traj_noisy = obj.traj_data.mesrd_noisy; 
            if ~isfield(obj.to_sys_pred_results.sys_data,'guess_sys_data') 
                obj.to_sys_pred_results.sys_data.f = obj.sys_data.f_guess; 
                obj.to_sys_pred_results.sys_data.g = obj.sys_data.g_guess; 
                obj.to_sys_pred_results.sys_data.h = obj.sys_data.h_guess; 
                obj.to_sys_pred_results.sys_data.h_ext = obj.sys_data.h_ext_guess; 
                obj.to_sys_pred_results.sys_data.x0_guess = obj.sys_data.x0_guess; 
            end 
            % 
            factr = 1; 
            saved_guess = {K_guess,bs_guess,x0_guess}; 
            % 
            N = obj.sys_params.N; 
            obj.alpha = 0.3/N^2; 
            guess_sys_data = obj.to_sys_pred_results.sys_data; 
            % x0_guess = obj.sys_data.x0_guess; 
            % obj.weight = eye(obj.sys_params.m); 
            obj.weight = [8.15849660302496/N^2,0,0,0;0,4151641837221.92,0,0;0,0,4151641837221.92,0;0,0,0,1647724.67444092]; % 
            Q = 1e0*diag([1,1e6*ones(1,2),1,ones(1,4),ones(1,3),ones(1,6)]); 
            % obj.weight = 1e-10*[0.00603838048126849,0,0,0;0,7.48506940906427e+19,0,0;0,0,7.48506940906427e+19,0;0,0,0,11483.7188104406]; 
            W = obj.weight; 
            % Way-1: how to get weight W: (no changes) 
            % >> dv_all = ([-eye(N),zeros(N,1)] + [zeros(N,1),eye(N)])*y_fulltraj 
            % >> dv_all = [dv_all(:,1),0.5*(abs(dv_all(:,2))+abs(dv_all(:,3))),dv_all(:,4)] 
            % >> Q_diag = 1./mean(dv_all,1).^2 
            % >> W = diag([Q_diag(1),Q_diag(2)*[1,1],Q_diag(3)]) 
            % x0_guess = obj.sys_data.x0; 
            % Way-2: how to get weight W: (result blows up) 
            % >> dv_all = del_y(end,:).^2 
            % >> dv_all = [dv_all(:,1),0.5*(abs(dv_all(:,2))+abs(dv_all(:,3))),dv_all(:,4)] 
            % >> Q_diag = 1./dv_all.^2 
            % >> W = diag([Q_diag(1),Q_diag(2)*[1,1],Q_diag(3)]) 
            % x0_guess = obj.sys_data.x0; 
            for iter=1:obj.max_iter 
                % S1. Fwd EKF sim       
                [x_est_traj,y_traj,y_fulltraj] = obj.eval_ekf(guess_sys_data,x0_guess,N); 
                % [x_est_traj,y_traj,y_fulltraj] = obj.eval_shifted_ekf(guess_sys_data,obj.sys_data.x0_guess,N); 
                % >> again 
                x_traj = obj.get_fwdsim_bk_ltv_guess(guess_sys_data,x0_guess); 
                % S2. Bckwd sim 
                % del_y = obj.traj_data.mesrd_noisy - y_traj; 
                % lam_traj = obj.get_bwdsim_adjoint(del_y,x_est_traj); 
                del_x = x_traj - x_est_traj; 
                % lam_traj = obj.get_bwdsim_statemes_adjoint(del_x,x_est_traj,Q); 
                lam_traj = obj.get_bwdsim_ekf_ltv_adjoint(del_x,x_est_traj,Q); 
                % S3. Grads 
                dLdKvec = 0; 
                for i=1:N 
                    t = obj.sys_params.dT*(i-1); 
                    u_i = obj.input_data(i,:)'; 
                    x_i = x_est_traj(i,:)'; 
                    dLdKvec = dLdKvec + transpose(...
                        (lam_traj(i+1,:)*obj.linzd_data.B(t,x_i,u_i,diag(K_guess)))*diag(obj.input_data(i,:))); 
                end 
                dLdbs = 0; 
                for i=1:N 
                    t = obj.sys_params.dT*(i-1); 
                    u_i = obj.input_data(i,:)'; 
                    x_i = x_est_traj(i,:)'; 
                    dLdbs = dLdbs + transpose(lam_traj(i+1,:)*obj.linzd_data.B(t,x_i,u_i,diag(K_guess))); 
                end 
                u_0 = obj.input_data(1,:)'; 
                x_0 = x_est_traj(1,:)'; 
                %                 if obj.C_switch_data(1)==0 % y_traj[0] <-- h/h_ext 
                %                     dLdx0 = obj.adjsys_data.A_T(x_0,u_0)*lam_traj(2,:)' ...
                %                         - obj.adjsys_data.C_ext_T(x_0)*obj.weight*del_y(1,:)'; 
                %                 else 
                %                     dLdx0 = obj.adjsys_data.A_T(x_0,u_0)*lam_traj(2,:)' ...
                %                         - obj.adjsys_data.C_T(x_0)*obj.weight*del_y(1,:)'; 
                % end 
                dLdx0 = obj.adjsys_data.A_T(0,x_0,u_0,diag(K_guess))*lam_traj(2,:)' - Q*del_x(1,:)'; 
                % S4. Update 
                delK_update = obj.alpha*N*diag(dLdKvec); 
                delbs_update = obj.alpha*N*dLdbs; 
                delx0_update = obj.alpha*N*dLdx0; 
                if iter==1  
%                     alK = (percent_update(1)/100)*min(abs(diag(K_guess))./abs(diag(delK_update))); 
%                     albs = (percent_update(1)/100)*min(abs(bs_guess)./abs(delbs_update)); 
%                     alx0 = (percent_update(end)/100)*min(abs(x0_guess)./abs(delx0_update)); 
                    % alx0 = (percent_update(end)/100)*min(abs([240;23;72;87;1;1;1;1;1;1;1])./abs(delx0_update)); 
                    alK = 86e-4*(percent_update(1)/100)*4e-21; % 4e-21 is ~great for 12m 
                    albs = 10e-4*(120/N)*(percent_update(1)/100)*1e-7; % 1e-7 is ~great for 12m 
                    alx0 = 10e-4*(120/N)*(percent_update(end)/100)*1e-8; % 1e-8 is ~great for 12m 
                    save learning_rates alK albs alx0 
                end 
                % condition break 
                if sum(isnan(delK_update(:))) || sum(isnan(delbs_update(:))) || sum(isnan(delx0_update(:))) 
                    % K = K_guess; bs = bs_guess; x0 = x0_guess; 
                    % save to_ili_res2 K bs x0
                    [K_guess,bs_guess,x0_guess] = saved_guess{:}; 
                    factr = 1; 
                    warning('NaN now!') 
                    break; 
                end 
                % 
                K_guess = K_guess - alK*delK_update; 
                % bs_guess = bs_guess - albs*repmat(delbs_update,1,size(bs_guess,1))'; 
                x0_guess = x0_guess - [alx0*delx0_update(1:end-length(delbs_update)); albs*delbs_update]; 
                % obj.to_sys_pred_results.sys_data = guess_sys_data; 
                obj.to_sys_pred_results.sys_data.x0_guess = x0_guess; 
                obj.to_sys_pred_results.sys_data.K_guess = K_guess; 
                obj.to_sys_pred_results.sys_data.bs_guess = bs_guess; 
                % test: disp(alK*delK_update); disp(albs*delbs_update); disp(alx0*delx0_update) 
            end 
            obj.efk_traj_results.states = x_est_traj;  
        end 
        function [K_guess,bs_guess,x0_guess,factr,y_fulltraj,W_ekf,del_p] = eval_ektopt_ver3(obj,percent_update,...
                K_guess,bs_guess,x0_guess,dT,C_q,S_w,earth_gravity) 
%             obj = varargin{1}; 
%             if nargin==2 
%                 obj.ekf_data.x_est = obj.sys_data.x0; 
%                 obj.ekf_data.p_est = varargin{2}*eye(length(obj.sys_data.x0)); 
%             elseif nargin==3 
%                 obj.ekf_data.x_est = varargin{2}; 
%                 obj.ekf_data.p_est = varargin{3}*eye(length(obj.sys_data.x0)); 
%             end 
%             N = obj.sys_params.N; 
%             n = obj.sys_params.n; 
%             x_est_traj = zeros(N+1,n); 
%             % Initial state conditions
%             if ~isfield(obj.ekf_data,'x_est') 
%                 obj.ekf_data.x_est = zeros(length(obj.sys_data.x0), 1);        
%                 obj.ekf_data.p_est = 100*ones(length(obj.sys_data.x0)); 
%             end
%             x_est_traj(1,:) = obj.ekf_data.x_est; 
%             y_traj_noisy = obj.traj_data.mesrd_noisy; 
            if ~isfield(obj.to_sys_pred_results.sys_data,'guess_sys_data') 
                obj.to_sys_pred_results.sys_data.f = obj.sys_data.f_guess; 
                obj.to_sys_pred_results.sys_data.g = obj.sys_data.g_guess; 
                obj.to_sys_pred_results.sys_data.h = obj.sys_data.h_guess; 
                obj.to_sys_pred_results.sys_data.h_ext = obj.sys_data.h_ext_guess; 
                obj.to_sys_pred_results.sys_data.x0_guess = obj.sys_data.x0_guess; 
            end 
            % 
            factr = 1; 
            saved_guess = {K_guess,bs_guess,x0_guess}; 
            % 
            N = obj.sys_params.N; 
            obj.alpha = 0.3/N^2; 
            guess_sys_data = obj.to_sys_pred_results.sys_data; 
            % x0_guess = obj.sys_data.x0_guess; 
            % obj.weight = eye(obj.sys_params.m); 
            obj.weight = [8.15849660302496/N^2,0,0,0;0,4151641837221.92,0,0;0,0,4151641837221.92,0;0,0,0,1647724.67444092]; % 
            Q = 1e0*diag([1,1e6*ones(1,2),1,ones(1,4),ones(1,3),ones(1,6)]); 
            % obj.weight = 1e-10*[0.00603838048126849,0,0,0;0,7.48506940906427e+19,0,0;0,0,7.48506940906427e+19,0;0,0,0,11483.7188104406]; 
            W = obj.weight; 
            % 
            W_ekf = 1e0*diag([5e10*ones(1,2),1]); 
            P = [zeros(3,1),eye(3),zeros(3,7+6)]; 
            % tmpP = [zeros(1,N+1);eye(N),zeros(N,1)]; 
            % Pmap = diag([1,2*ones(1,N-1),1]) - tmpP - tmpP'; 
            % 
            % Way-1: how to get weight W: (no changes) 
            % >> dv_all = ([-eye(N),zeros(N,1)] + [zeros(N,1),eye(N)])*y_fulltraj 
            % >> dv_all = [dv_all(:,1),0.5*(abs(dv_all(:,2))+abs(dv_all(:,3))),dv_all(:,4)] 
            % >> Q_diag = 1./mean(dv_all,1).^2 
            % >> W = diag([Q_diag(1),Q_diag(2)*[1,1],Q_diag(3)]) 
            % x0_guess = obj.sys_data.x0; 
            % Way-2: how to get weight W: (result blows up) 
            % >> dv_all = del_y(end,:).^2 
            % >> dv_all = [dv_all(:,1),0.5*(abs(dv_all(:,2))+abs(dv_all(:,3))),dv_all(:,4)] 
            % >> Q_diag = 1./dv_all.^2 
            % >> W = diag([Q_diag(1),Q_diag(2)*[1,1],Q_diag(3)]) 
            % x0_guess = obj.sys_data.x0; 
            for iter=1:obj.max_iter 
                % S1. Fwd EKF sim       
                [x_est_traj,y_traj,y_fulltraj] = obj.eval_ekf(guess_sys_data,x0_guess,N); 
                % [x_est_traj,y_traj,y_fulltraj] = obj.eval_shifted_ekf(guess_sys_data,obj.sys_data.x0_guess,N); 
                % >> again 
                % x_traj = obj.get_fwdsim_guess(guess_sys_data,x0_guess); 
                % S2. Bckwd sim 
                % del_y = obj.traj_data.mesrd_noisy - y_traj; 
                % lam_traj = obj.get_bwdsim_adjoint(del_y,x_est_traj); 
                % del_x = x_traj - x_est_traj; 
                % lam_traj = obj.get_bwdsim_statemes_adjoint(del_x,x_est_traj,Q); 
                % lam_traj = obj.get_bwdsim_ekf_adjoint(del_x,x_est_traj,Q); 
                % del_p = Pmap*x_est_traj(:,2:4); 
                del_p = [[1,-1]*x_est_traj(1:2,2:4);...
                    2*x_est_traj(2:end-1,2:4)-x_est_traj(1:end-2,2:4)-x_est_traj(3:end,2:4);...
                    [-1,1]*x_est_traj(end-1:end,2:4)]; 
                lam_traj = obj.get_bwdsim_ekf_ltv_adjoint(del_p,x_est_traj,P'*W_ekf); 
                % S3. Grads 
                dLdKvec = 0; 
                for i=1:N 
                    t = obj.sys_params.dT*(i-1); 
                    u_i = obj.input_data(i,:)'; 
                    x_i = x_est_traj(i,:)'; 
                    dLdKvec = dLdKvec + transpose(...
                        (lam_traj(i+1,:)*obj.linzd_data.B(t,x_i,u_i,diag(K_guess)))*diag(obj.input_data(i,:))); 
                end 
                dLdbs = 0; 
                for i=1:N 
                    t = obj.sys_params.dT*(i-1); 
                    u_i = obj.input_data(i,:)'; 
                    x_i = x_est_traj(i,:)'; 
                    dLdbs = dLdbs + transpose(lam_traj(i+1,:)*obj.linzd_data.B(t,x_i,u_i,diag(K_guess))); 
                end 
                u_0 = obj.input_data(1,:)'; 
                x_0 = x_est_traj(1,:)'; 
                %                 if obj.C_switch_data(1)==0 % y_traj[0] <-- h/h_ext 
                %                     dLdx0 = obj.adjsys_data.A_T(x_0,u_0)*lam_traj(2,:)' ...
                %                         - obj.adjsys_data.C_ext_T(x_0)*obj.weight*del_y(1,:)'; 
                %                 else 
                %                     dLdx0 = obj.adjsys_data.A_T(x_0,u_0)*lam_traj(2,:)' ...
                %                         - obj.adjsys_data.C_T(x_0)*obj.weight*del_y(1,:)'; 
                % end 
                % dLdx0 = obj.adjsys_data.A_T(x_0,u_0)*lam_traj(2,:)' - Q*del_x(1,:)'; 
                K_k = reshape(obj.kalman_gain(1,:),obj.sys_params.n,[]); 
                if obj.C_switch_data(1)==0 
                    M = eye(obj.sys_params.n) - K_k*obj.linzd_data.C_ext(x_0); 
                else 
                    M = eye(obj.sys_params.n) - K_k*obj.linzd_data.C(x_0); 
                end 
                dLdx0 = obj.adjsys_data.A_T(0,x_0,u_0,diag(K_guess))*transpose(M)*lam_traj(2,:)' ...
                    - P'*W_ekf*del_p(1,:)'; 
                % S4. Update 
                delK_update = obj.alpha*N*diag(dLdKvec); 
                delbs_update = obj.alpha*N*dLdbs; 
                delx0_update = obj.alpha*N*dLdx0; 
                if iter==1  
%                     alK = (percent_update(1)/100)*min(abs(diag(K_guess))./abs(diag(delK_update))); 
%                     albs = (percent_update(1)/100)*min(abs(bs_guess)./abs(delbs_update)); 
%                     alx0 = (percent_update(end)/100)*min(abs(x0_guess)./abs(delx0_update)); 
                    % alx0 = (percent_update(end)/100)*min(abs([240;23;72;87;1;1;1;1;1;1;1])./abs(delx0_update)); 
                    alK = 86e-1*(percent_update(1)/100)*4e-21; % 4e-21 is ~great for 12m 
                    albs = 10e-2*(120/N)*(percent_update(1)/100)*1e-7; % 1e-7 is ~great for 12m 
                    alx0 = 10e-1*(120/N)*(percent_update(end)/100)*1e-8; % 1e-8 is ~great for 12m 
                    save learning_rates alK albs alx0 
                end 
                % condition break 
                if sum(isnan(delK_update(:))) || sum(isnan(delbs_update(:))) || sum(isnan(delx0_update(:))) 
                    % K = K_guess; bs = bs_guess; x0 = x0_guess; 
                    % save to_ili_res2 K bs x0
                    [K_guess,bs_guess,x0_guess] = saved_guess{:}; 
                    factr = 1; 
                    warning('NaN now!') 
                    break; 
                end 
                % 
                K_guess = K_guess - alK*delK_update; 
                % bs_guess = bs_guess - albs*repmat(delbs_update,1,size(bs_guess,1))'; 
                x0_guess = x0_guess - [alx0*delx0_update(1:end-length(delbs_update)); albs*delbs_update]; 
                % obj.to_sys_pred_results.sys_data = guess_sys_data; 
                obj.to_sys_pred_results.sys_data.x0_guess = x0_guess; 
                obj.to_sys_pred_results.sys_data.K_guess = K_guess; 
                obj.to_sys_pred_results.sys_data.bs_guess = bs_guess; 
                % test: disp(alK*delK_update); disp(albs*delbs_update); disp(alx0*delx0_update) 
            end 
            obj.efk_traj_results.states = x_est_traj;  
        end 
        % Manifold dynamics 
        function [K_guess,bs_guess,x0_guess,factr,y_fulltraj,W,Z,del_y] = eval_trajopt_main_gain_kbias_init_ili_simple_or_manifold(...
                obj,percent_update,K_guess,bs_guess,x0_guess) 
            if ~isfield(obj.to_sys_pred_results.sys_data,'guess_sys_data') 
                obj.to_sys_pred_results.sys_data.f = obj.sys_data.f_guess; 
                obj.to_sys_pred_results.sys_data.g = obj.sys_data.g_guess; 
                obj.to_sys_pred_results.sys_data.h = obj.sys_data.h_guess; 
                obj.to_sys_pred_results.sys_data.h_ext = obj.sys_data.h_ext_guess; 
                obj.to_sys_pred_results.sys_data.x0_guess = obj.sys_data.x0_guess; 
            end 
            % 
            factr = 1; 
            saved_guess = {K_guess,bs_guess,x0_guess}; 
            % 
            N = obj.sys_params.N; 
            obj.alpha = 0.3/N^2; 
            guess_sys_data = obj.to_sys_pred_results.sys_data; 
            % x0_guess = obj.sys_data.x0_guess; 
            % obj.weight = eye(obj.sys_params.m); 
            obj.weight = [8.15849660302496/N^2,0,0,0;0,4151641837221.92,0,0;0,0,4151641837221.92,0;0,0,0,1647724.67444092]; % 
            % obj.weight = 1e-10*[0.00603838048126849,0,0,0;0,7.48506940906427e+19,0,0;0,0,7.48506940906427e+19,0;0,0,0,11483.7188104406]; 
            W = obj.weight; 
            Z = 1*eye(obj.sys_params.r); 
            % Way-1: how to get weight W: (no changes) 
            % >> dv_all = ([-eye(N),zeros(N,1)] + [zeros(N,1),eye(N)])*y_fulltraj 
            % >> dv_all = [dv_all(:,1),0.5*(abs(dv_all(:,2))+abs(dv_all(:,3))),dv_all(:,4)] 
            % >> Q_diag = 1./mean(dv_all,1).^2 
            % >> W = diag([Q_diag(1),Q_diag(2)*[1,1],Q_diag(3)]) 
            % x0_guess = obj.sys_data.x0; 
            % Way-2: how to get weight W: (result blows up) 
            % >> dv_all = del_y(end,:).^2 
            % >> dv_all = [dv_all(:,1),0.5*(abs(dv_all(:,2))+abs(dv_all(:,3))),dv_all(:,4)] 
            % >> Q_diag = 1./dv_all.^2 
            % >> W = diag([Q_diag(1),Q_diag(2)*[1,1],Q_diag(3)]) 
            % x0_guess = obj.sys_data.x0; 
            for iter=1:obj.max_iter 
                % S1. Fwd sim 
                [x_traj,y_traj,y_fulltraj] = obj.get_fwdsim_bk_ltv_guess(guess_sys_data,x0_guess); 
                x_traj(2:end,12:17) = bs_guess; 
                % S2. Bckwd sim 
                del_y = obj.traj_data.mesrd_noisy - y_traj; 
                % lam_traj = obj.get_bwdsim_bk_adjoint(del_y,x_traj); 
                lam_traj = obj.get_bwdsim_bk_ltv_adjoint(del_y,x_traj); 
                % S3. Grads 
                dLdKvec = 0; 
                for i=1:N 
                    t = obj.sys_params.dT*(i-1);  
                    u_i = obj.input_data(i,:)'; 
                    x_i = x_traj(i,:)'; 
                    dLdKvec = dLdKvec + transpose(...
                        (lam_traj(i+1,:)*obj.linzd_data.B(t,x_i,u_i,diag(K_guess)))*diag(obj.input_data(i,:))); 
                end 
                b_0 = bs_guess(1,:)'; b_1 = bs_guess(2,:)'; 
                dLdbs = transpose(lam_traj(2,:)*obj.linzd_data.B(t,x_i,u_i,diag(K_guess)) - (b_1-b_0)'*Z); 
                for i=2:N-1 
                    t = obj.sys_params.dT*(i-1);  
                    b_i = bs_guess(i,:)'; b_im1 = bs_guess(i-1,:)'; b_ip1 = bs_guess(i+1,:)'; 
                    u_i = obj.input_data(i,:)'; 
                    x_i = x_traj(i,:)'; 
                    dLdbs = [dLdbs, transpose(lam_traj(i+1,:)*obj.linzd_data.B(t,x_i,u_i,diag(K_guess)) ...
                        - (2*b_i-b_im1-b_ip1)'*Z)]; 
                end 
                b_Nm1 = bs_guess(end,:)'; b_Nm2 = bs_guess(end-1,:)'; 
                u_N = obj.input_data(end,:)'; 
                x_N = x_traj(end,:)'; 
                t_N = obj.sys_params.dT*(N-1);  
                dLdbs = [dLdbs, transpose(lam_traj(N+1,:)*obj.linzd_data.B(t_N,x_N,u_N,diag(K_guess)) ...
                    + (b_Nm1-b_Nm2)'*Z)]; 
                b_0 =  bs_guess(1,:)'; 
                u_0 = obj.input_data(1,:)'; 
                x_0 = x_traj(1,:)'; 
                if obj.C_switch_data(1)==0 % y_traj[0] <-- h/h_ext 
                    dLdx0 = obj.adjsys_data.A_T(0,x_0,u_0,diag(K_guess))*lam_traj(2,:)' ...
                        - obj.adjsys_data.C_ext_T(x_0)*obj.weight*del_y(1,:)'; 
                else 
                    dLdx0 = obj.adjsys_data.A_T(0,x_0,u_0,diag(K_guess))*lam_traj(2,:)' ...
                        - obj.adjsys_data.C_T(x_0)*obj.weight*del_y(1,:)'; 
                end 
                % S4. Update 
                delK_update = obj.alpha*N*diag(dLdKvec); 
                delbs_update = obj.alpha*N*dLdbs; 
                delx0_update = obj.alpha*N*dLdx0; 
                if iter==1  
%                     alK = (percent_update(1)/100)*min(abs(diag(K_guess))./abs(diag(delK_update))); 
%                     albs = (percent_update(1)/100)*min(abs(bs_guess)./abs(delbs_update)); 
%                     alx0 = (percent_update(end)/100)*min(abs(x0_guess)./abs(delx0_update)); 
                    % alx0 = (percent_update(end)/100)*min(abs([240;23;72;87;1;1;1;1;1;1;1])./abs(delx0_update)); 
                    alK = 16e-4*(percent_update(1)/100)*4e-21; % 4e-21 is ~great for 12m 
                    albs = 10e-4*(120/N)*(percent_update(1)/100)*1e-7; % 1e-7 is ~great for 12m 
                    alx0 = 10e-1*(120/N)*(percent_update(end)/100)*1e-8; % 1e-8 is ~great for 12m 
%                     alK = 1e-0*(percent_update(1)/100)*4e-21; % 4e-21 is ~great for 12m 
%                     albs = 1e-0*(120/N)*(percent_update(1)/100)*1e-7; % 1e-7 is ~great for 12m 
%                     alx0 = 1e-0*(120/N)*(percent_update(end)/100)*1e-8; % 1e-8 is ~great for 12m 
%                     alK = 5e2*(percent_update(1)/100)*4e-21; % 4e-21 is ~great for 12m 
%                     albs = 5e2*(120/N)*(percent_update(1)/100)*1e-7; % 1e-7 is ~great for 12m 
%                     alx0 = 1e-0*(120/N)*(percent_update(end)/100)*1e-8; % 1e-8 is ~great for 12m 
                    % save learning_rate/s alK albs alx0 
                end 
                % condition break 
                if sum(isnan(delK_update(:))) || sum(isnan(delbs_update(:))) || sum(isnan(delx0_update(:))) 
                    % K = K_guess; bs = bs_guess; x0 = x0_guess; 
                    % save to_ili_res2 K bs x0
                    [K_guess,bs_guess,x0_guess] = saved_guess{:}; 
                    factr = 1; 
                    warning('NaN now!') 
                    break; 
                end 
                % 
                K_guess = K_guess - alK*delK_update; 
                bs_guess = bs_guess - albs*delbs_update'; 
                x0_guess = x0_guess - alx0*delx0_update; 
                % obj.to_sys_pred_results.sys_data = guess_sys_data; 
                obj.to_sys_pred_results.sys_data.x0_guess = x0_guess; 
                obj.to_sys_pred_results.sys_data.K_guess = K_guess; 
                obj.to_sys_pred_results.sys_data.bs_guess = bs_guess; 
                % test: disp(alK*delK_update); disp(albs*delbs_update(:,[1:5,end-6:end])); disp(alx0*delx0_update) 
            end 
        end 
        % EKF control generator 
        function [K_guess,bs_guess] = eval_trajopt_control(obj,acc_scale,K_guess,bs_guess) 
            if ~isfield(obj.to_sys_pred_results.sys_data,'guess_sys_data') 
                obj.to_sys_pred_results.sys_data.f = obj.sys_data.f_guess; 
                obj.to_sys_pred_results.sys_data.g = obj.sys_data.g_guess; 
                obj.to_sys_pred_results.sys_data.h = obj.sys_data.h_guess; 
                obj.to_sys_pred_results.sys_data.h_ext = obj.sys_data.h_ext_guess; 
                obj.to_sys_pred_results.sys_data.x0_guess = obj.sys_data.x0_guess; 
            end 
            N = obj.sys_params.N; 
            obj.alpha = 0.3*acc_scale/N^2; 
            guess_sys_data = obj.to_sys_pred_results.sys_data; 
            x0_guess = obj.sys_data.x0_guess; 
            obj.weight = eye(obj.sys_params.m); 
            obj.init_mu(); 
            % x0_guess = obj.sys_data.x0; 
            for iter=1:obj.max_iter 
                % S1. Fwd sim 
                [x_traj,y_traj] = obj.get_fwdsim_guess(guess_sys_data,x0_guess); 
                % S2. Bckwd sim 
                delmu = obj.get_del_mu(x_traj); 
                lam_traj = obj.get_bwdsim_adjoint(delmu,x_traj); 
                % S3. Grads 
                dLdKvec = 0; 
                dLdbs = 0; 
                dLdu = zeros(N,obj.sys_params.r); 
                for i=1:N 
                    u_i = obj.input_data(i,:)'; 
                    x_i = x_traj(i,:)'; 
                    dLdKvec = dLdKvec + transpose(...
                        (lam_traj(i+1,:)*obj.linzd_data.B(x_i,u_i))*obj.input_data(i,:)'); 
                    dLdbs = dLdbs + transpose(lam_traj(i+1,:)*obj.linzd_data.B(x_i,u_i)); 
                    dLdu(i,:) = -transpose(obj.lqr_data.R\obj.adjsys_data.B_T(x_i,u_i)*lam_traj(i+1,:)'); 
                end 
                u_0 = obj.input_data(1,:)'; 
                x_0 = x_traj(1,:)'; 
                if obj.C_switch_data(1)==0 % y_traj[0] <-- h/h_ext 
                    dLdx0 = obj.adjsys_data.A_T(x_0,u_0)*lam_traj(2,:)' ...
                        - obj.adjsys_data.C_ext_T(x_0)*obj.weight*delmu(1,:)'; 
                else 
                    dLdx0 = obj.adjsys_data.A_T(x_0,u_0)*lam_traj(2,:)' ...
                        - obj.adjsys_data.C_T(x_0)*obj.weight*delmu(1,:)'; 
                end 
                % S4. Update 
                % K_guess = K_guess - obj.alpha*N*diag(dLdKvec); 
                % bs_guess = bs_guess - obj.alpha*N*dLdbs; 
                % guess_sys_data.g = @(t,x,u) obj.linzd_data.B(x,u)*(K_guess*u + bs_guess); 
                % x0_guess = x0_guess - obj.alpha*N*dLdx0; 
                obj.input_data = obj.input_data + obj.alpha*N*dLdu; 
            end 
            obj.to_sys_pred_results.sys_data = guess_sys_data; 
            obj.to_sys_pred_results.sys_data.x0_guess = x0_guess; 
        end 
        %% Rendering: render_ 
        function render_state_ekftraj_comparison(obj) 
            plot(obj.traj_data.states,'-.') 
            hold on 
            plot(obj.efk_traj_results.states) 
            hold off 
            obj.label_data(true); 
            grid on 
            title('Predicted using cycle-EKF! ') 
        end 
        function render_output_ekftraj_comparison(obj) 
            y_traj = []; 
            for i=1:size(obj.efk_traj_results.states,1) 
                x_i = obj.efk_traj_results.states(i,:)'; 
                if sum(i-1==obj.C_switch_data)>0 
                    y_i = obj.sys_data.h_ext(x_i); 
                else 
                    y_i = obj.sys_data.h(x_i); 
                end 
                y_traj = [y_traj; y_i']; 
            end 
            plot(obj.traj_data.mesrd_true,'-.') 
            hold on 
            plot(obj.traj_data.mesrd_noisy,'--') 
            plot(y_traj) 
            hold off 
            obj.label_data(~true); 
            grid on 
            title('Predicted using cycle-EKF! ') 
        end 
        function render_state_topttraj_comparison(obj) 
            x_traj = obj.get_fwdsim_guess(obj.to_sys_pred_results.sys_data,...
                obj.to_sys_pred_results.sys_data.x0_guess); 
            plot(obj.traj_data.states,'-.') 
            hold on 
            plot(x_traj) 
            hold off 
            obj.label_data(true); 
            grid on 
            title('Predicted using TrajOpt! ') 
        end 
        function render_output_topttraj_comparison(obj) 
            [~,y_traj] = obj.get_fwdsim_guess(obj.to_sys_pred_results.sys_data,...
                obj.to_sys_pred_results.sys_data.x0_guess); 
            plot(obj.traj_data.mesrd_true,'-.') 
            hold on 
            plot(obj.traj_data.mesrd_noisy,'--') 
            plot(y_traj) 
            hold off 
            obj.label_data(~true); 
            grid on 
            title('Predicted using TrajOpt! ') 
        end 
        function render_state_inittraj_comparison(obj) 
            x_traj = obj.get_fwdsim_guess(); 
            plot(obj.traj_data.states,'-.') 
            hold on 
            plot(x_traj) 
            hold off 
            obj.label_data(true); 
            grid on 
            title('Predicted using initial guess! ') 
        end 
        function render_output_inittraj_comparison(obj) 
            [~,y_traj] = obj.get_fwdsim_guess(); 
            plot(obj.traj_data.mesrd_true,'-.') 
            hold on 
            plot(obj.traj_data.mesrd_noisy,'--') 
            plot(y_traj) 
            hold off 
            obj.label_data(~true); 
            grid on 
            title('Predicted using initial guess! ') 
        end 
        function render_output_ili_bk_topttraj_comparison(obj) 
            %             [~,y_traj] = obj.get_fwdsim_bk_guess(obj.to_sys_pred_results.sys_data,...
            %                 obj.to_sys_pred_results.sys_data.x0_guess); 
            [~,y_traj] = obj.get_fwdsim_bk_ltv_guess(obj.to_sys_pred_results.sys_data,...
                obj.to_sys_pred_results.sys_data.x0_guess); 
            plot(obj.traj_data.mesrd_true,'-.') 
            hold on 
            plot(obj.traj_data.mesrd_noisy,'--') 
            plot(y_traj) 
            hold off 
            obj.label_data(~true); 
            grid on 
            title('Predicted using TrajOpt! ') 
        end %% Testbench: test_ & report_ 
    end 
    methods % Init 
        function init_to(obj) 
            P = [10,1;-2,10]; 
            D = diag([-0.02,-0.08]); 
            A = eye(2) + P\D*P; 
            B = [0.1;-0.08]; 
            C = [1,2;0,0]; 
            C_ext = [1,2;-2,1]; 
            % 
            B_guess = [2;2]; 
            % 
            x0 = [2;1]; 
            N = 30; 
            % 
            C_swtch_data = [0,floor(N/2),N]; 
            f = @(x) A*x; g = @(t,x,u) B*u; h = @(x) C*x; 
            h_ext = @(x) C_ext*x; 
            f_guess = @(x) A*x; g_guess = @(t,x,u) B_guess*u; 
            h_guess = @(x) C*x; h_ext_guess = @(x) C_ext*x; 
            x0_guess = [0;0]; 
            % 
            obj.set_sys_params(length(x0),N,size(C_ext,1),size(B,2),1); 
            obj.set_system_data(f,g,h,h_ext,x0,f_guess,g_guess,h_guess,...
                h_ext_guess,x0_guess,C_swtch_data); 
            obj.set_linearized_and_adjoint_data(@(~,~)A,@(~,~)B,@(~)C,@(~)C_ext); 
            obj.set_input_data(randn(N,size(B,2))); 
            obj.set_noise_data(eye(2),100*eye(2)); 
            obj.set_output_data(); 

            % 
            Obs = [C; C*A]; 
            Obs_ext = [C_ext; C_ext*A]; 
            % 
            disp('Eigenvalues of the sample system = ') 
            disp(eig(A)) 
            disp('Observability matrix (Obs) = ') 
            disp(Obs) 
            disp(['rank of Obs = ', num2str(rank(Obs))]) 
            disp('Observability matrix extended (Obs_ext) = ') 
            disp(Obs) 
            disp(['rank of Obs_ext = ', num2str(rank(Obs_ext))]) 
        end 
        function init_mu(obj) 
            obj.muLB = zeros(obj.sys_params.N+1,obj.sys_params.n); 
            obj.muUB = zeros(obj.sys_params.N+1,obj.sys_params.n); 
        end 
    end 
    methods (Access=protected) 
        function label_data(obj,state_en) 
            x_traj = obj.traj_data.states; 
            y_traj = obj.traj_data.mesrd_noisy; 
            st_lbl_true = {}; st_lbl_pred = {}; 
            for i=1:size(x_traj,2) 
                st_lbl_true = [st_lbl_true; ['x-',num2str(i),' true']]; 
                st_lbl_pred = [st_lbl_pred; ['x-',num2str(i),' pred']]; 
            end 
            mes_lbl_true = {}; mes_lbl_noisy = {}; mes_lbl_pred = {}; 
            for i=1:size(y_traj,2) 
                mes_lbl_true = [mes_lbl_true; ['y-',num2str(i),' true']]; 
                mes_lbl_noisy = [mes_lbl_noisy; ['y-',num2str(i),' noisy']]; 
                mes_lbl_pred = [mes_lbl_pred; ['y-',num2str(i),' pred']]; 
            end 
            % 
            if state_en 
                xlabel('time --> ') 
                ylabel('states --> ') 
                legend(st_lbl_true{:},st_lbl_pred{:}) 
            else 
                xlabel('time --> ') 
                ylabel('output --> ') 
                legend(mes_lbl_true{:},mes_lbl_noisy{:},mes_lbl_pred{:}) 
            end 
        end 
    end 
end 

%% Tests below 
function new_obj = test_to_tools_how_to() 
clc; 
disp('This is a test! ') 
disp('First case: New initial point (overriding existing initialization)! ') 
new_obj = to_tools(); 
new_obj.about(); 

P = [10,1;-2,10]; 
D = diag([-0.02,-0.08]); 
A = eye(2) + P\D*P; 
B = [0.1;-0.08]; 
[evec,~] = eig(A'); 
C = [evec(:,1)';0,0]; 
C_ext = [1,2;-2,1]; 
% 
B_guess = [2;2]; 
% 
x0 = [2;1]; 
N = 30; 
% 
C_swtch_data = [0,floor(N/2),N]; 
f = @(x) A*x; g = @(x,u) B*u; h = @(x) C*x; 
h_ext = @(x) C_ext*x; 
f_guess = @(x) A*x; g_guess = @(x,u) B_guess*u; 
h_guess = @(x) C*x; h_ext_guess = @(x) C_ext*x; 
x0_guess = [-1;-1]; 
% 
new_obj.set_sys_params(length(x0),N,size(C_ext,1),size(B,2)); 
new_obj.set_system_data(f,g,h,h_ext,x0,f_guess,g_guess,h_guess,...
    h_ext_guess,x0_guess,C_swtch_data); 
new_obj.set_linearized_and_adjoint_data(@(~,~)A,@(~,~)B,@(~)C,@(~)C_ext); 
new_obj.set_input_data(randn(N,size(B,2))); 
new_obj.set_noise_data(eye(2),100*eye(2)); 
new_obj.set_output_data(); 

new_obj.render_output_inittraj_comparison(); 

if pause_dbug_fcn3(); keyboard; end; clc 

for i=1:3 
    new_obj.eval_trajopt_main_bmatrix(); 
end 
clf 
new_obj.render_output_topttraj_comparison(); 

if pause_dbug_fcn3(); keyboard; end; clc 

end 

function new_obj = test_to_tools_gain_bias_init() 
clc; 
disp('This is a test! ') 
disp('Second case: Gain, bias, and initial condition tuning! ') 
new_obj = to_tools(); 
new_obj.about(); 

P = [10,1;-2,10]; 
D = diag([-0.02,-0.08]); 
A = eye(2) + P\D*P; 
B = [0.1;-0.08]; 
K = 1.5; 
bs = -0.1; 
[evec,~] = eig(A'); 
C = [evec(:,1)';0,0]; 
C_ext = [1,2;-2,1]; 
% 
K_guess = 2.5; 
bs_guess = 0; 
% 
x0 = [2;1]; 
N = 30; 
dT = 0.1; 
% 
C_swtch_data = [0,floor(N/2),N]; 
f = @(x) A*x; g = @(t,x,u) B*(K*u+bs); h = @(x) C*x; 
h_ext = @(x) C_ext*x; 
f_guess = @(x) A*x; g_guess = @(t,x,u) B*(K_guess*u+bs_guess); 
h_guess = @(x) C*x; h_ext_guess = @(x) C_ext*x; 
x0_guess = [-1;-1]; 
% 
new_obj.set_sys_params(length(x0),N,size(C_ext,1),size(B,2),dT); 
new_obj.set_system_data(f,g,h,h_ext,x0,f_guess,g_guess,h_guess,...
    h_ext_guess,x0_guess,C_swtch_data); 
new_obj.set_linearized_and_adjoint_data(@(~,~)A,@(~,~)B,@(~)C,@(~)C_ext); 
new_obj.set_input_data(randn(N,size(B,2))); 
new_obj.set_noise_data(eye(2),100*eye(2)); 
new_obj.set_output_data(); 
new_obj.set_guess(x0_guess,K_guess,bs_guess); 

new_obj.render_output_inittraj_comparison(); 

if pause_dbug_fcn3(); keyboard; end; clc 

for i=1:6 
    acc_scale = 1; %/i 
    [K_guess,bs_guess] = new_obj.eval_trajopt_main_gain_bias_init(acc_scale,K_guess,bs_guess); 
end 
clf 
new_obj.render_output_topttraj_comparison(); 

if pause_dbug_fcn3(); keyboard; end; clc 

end 

function new_obj = test_gap_in_to_tools_gain_bias_init() 
clc; 
disp('This is a test! ') 
disp('Fourth case: (Gap in TO) Gain, bias, and initial condition tuning! ') 
new_obj = to_tools(); 
new_obj.about(); 

P = [10,1;-2,10]; 
D = diag([-0.02,-0.08]); 
A = eye(2) + P\D*P; 
B = [0.1;-0.08]; 
K = 1.5; 
bs = -0.1; 
[evec,~] = eig(A'); 
C = [evec(:,1)';0,0]; 
C_ext = [1,2;-2,1]; 
% 
K_guess = 2.5; 
bs_guess = 0; 
% 
dT = 0.1; 
x0 = [2;1]; 
N = 30; 
% 
C_swtch_data = [0,floor(N/2),N]; 
f = @(x) A*x; g = @(t,x,u) B*(K*u+bs); h = @(x) C*x; 
h_ext = @(x) C_ext*x; 
P = [10,1;-2,10] + 4*(rand(2)>0.4) - 7*(rand(2)>0.4); 
D = diag([-0.02,-0.08]); 
A = eye(2) + P\D*P; 
f_guess = @(x) A*x; g_guess = @(t,x,u) B*(K_guess*u+bs_guess); 
h_guess = @(x) C*x; h_ext_guess = @(x) C_ext*x; 
x0_guess = [-1;-1]; 
% 
new_obj.set_sys_params(length(x0),N,size(C_ext,1),size(B,2),dT); 
new_obj.set_system_data(f,g,h,h_ext,x0,f_guess,g_guess,h_guess,...
    h_ext_guess,x0_guess,C_swtch_data); 
new_obj.set_linearized_and_adjoint_data(@(~,~)A,@(~,~)B,@(~)C,@(~)C_ext); 
new_obj.set_input_data(randn(N,size(B,2))); 
new_obj.set_noise_data(eye(2),100*eye(2)); 
new_obj.set_output_data(); 
new_obj.set_guess(x0_guess,K_guess,bs_guess); 

new_obj.render_output_inittraj_comparison(); 

if pause_dbug_fcn3(); keyboard; end; clc 

for i=1:6 
    acc_scale = 1; %/i 
    [K_guess,bs_guess] = new_obj.eval_trajopt_main_gain_bias_init(acc_scale,K_guess,bs_guess); 
end 
clf 
new_obj.render_output_topttraj_comparison(); 

if pause_dbug_fcn3(); keyboard; end; clc 

end 

function new_obj = test_ekf_tools_gain_bias_init() 
clc; 
disp('This is a test! ') 
disp('Third case: EKF: Gain, bias, and initial condition tuning! ') 
new_obj = to_tools(); 
new_obj.about(); 

P = [10,1;-2,10]; 
D = diag([-0.02,-0.08]); 
A = eye(2) + P\D*P; 
B = [0.1;-0.08]; 
K = 1.5; 
bs = -0.1; 
[evec,~] = eig(A'); 
C = [evec(:,1)';0,0]; 
C_ext = [1,2;-2,1]; 
% 
K_guess = 2.5; 
bs_guess = 0; 
% 
x0 = [2;1]; 
N = 30; 
% 
C_swtch_data = [0,floor(N/2),N]; 
f = @(x) A*x; g = @(x,u) B*(K*u+bs); h = @(x) C*x; 
h_ext = @(x) C_ext*x; 
f_guess = @(x) A*x; g_guess = @(x,u) B*(K_guess*u+bs_guess); 
h_guess = @(x) C*x; h_ext_guess = @(x) C_ext*x; 
x0_guess = [-1;-1]; x0_guess = x0*0.9; 
% 
new_obj.set_sys_params(length(x0),N,size(C_ext,1),size(B,2)); 
new_obj.set_system_data(f,g,h,h_ext,x0,f_guess,g_guess,h_guess,...
    h_ext_guess,x0_guess,C_swtch_data); 
new_obj.set_linearized_and_adjoint_data(@(~,~)A,@(~,~)B,@(~)C,@(~)C_ext); 
new_obj.set_input_data(randn(N,size(B,2))); 
new_obj.set_noise_data(eye(2),100*eye(2)); 
new_obj.set_output_data(); 

new_obj.render_output_inittraj_comparison(); 

if pause_dbug_fcn3(); keyboard; end; clc 

% new_obj = new_obj; 
for i=1:1 
    if ~isfield(new_obj.to_sys_pred_results,'sys_data') 
        new_obj.to_sys_pred_results.sys_data.f = new_obj.sys_data.f_guess; 
        new_obj.to_sys_pred_results.sys_data.g = new_obj.sys_data.g_guess; 
        new_obj.to_sys_pred_results.sys_data.h = new_obj.sys_data.h_guess; 
        new_obj.to_sys_pred_results.sys_data.h_ext = new_obj.sys_data.h_ext_guess; 
        new_obj.to_sys_pred_results.sys_data.x0_guess = new_obj.sys_data.x0_guess; 
    end 
    N = new_obj.sys_params.N; 
    new_obj.alpha = 0.3/N^2; 
    guess_sys_data = new_obj.to_sys_pred_results.sys_data; 
    x0_guess = new_obj.sys_data.x0_guess; 
    %     new_obj.eval_ekf(); 
    %     new_obj.eval_ekf(N); 
    new_obj.eval_ekf(x0_guess,N); 
end 
clf 
new_obj.render_output_ekftraj_comparison(); 

if pause_dbug_fcn3(); keyboard; end; clc 

end 


function [to_dbug, dbug_en] = pause_dbug_fcn3() 

to_dbug = false; 
dbug_en = true; 

for i=1:10
    disp(' ') 
    usr_key = input('Debug Mode: press `ENTER` to skip; `1` for help >> '); 
    if isempty(usr_key) 
        break 
    end     

    switch usr_key 
        case 1
            warning('Pinging current line number. Paused. ') 
            disp('1: help mode + line print ') 
            disp('2: debug mode ') 
            disp('3: disable debug mode ') 
        case 2 
            disp('Keyboard Mode: ')
            disp(' `dbcont` - continue')
            disp(' `dbquit` - stop')
            disp(' `dbstep` - step to next line') 
            to_dbug = true; 
            break 
        case 3 
            dbug_en = false; 
            break 
        otherwise 
            break 
    end
end

end
