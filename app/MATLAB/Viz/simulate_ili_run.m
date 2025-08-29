classdef simulate_ili_run < draw_stuff % run: >> simulate_ili_run([]) %&ENV
    properties (Access=protected) 
        % data related 
        IMU_ID_data = struct(); 
        reliable_max_index = 1560e3; 
        % temporary 
        acc_gain = []; 
        % for show plots 
        imudata_names = {'gyr-X','gyr-Y','gyr-Z','acc-X','acc-Y','acc-Z','odo-1','odo-2','odo-3'}; 
        % for integrator 
        integrator_input_index = 1; 
        % inline function for Jacobian 
        dCqadq_core = @(a1,a2,a3,q0,q1,q2,q3)reshape([a1.*q0.*4.0-a2.*q3.*2.0+a3.*q2.*2.0,a2.*q0.*4.0+a1.*q3.*2.0-a3.*q1.*2.0,a1.*q2.*-2.0+a2.*q1.*2.0+a3.*q0.*4.0,a1.*q1.*4.0+a2.*q2.*2.0+a3.*q3.*2.0,a1.*q2.*2.0-a3.*q0.*2.0,a2.*q0.*2.0+a1.*q3.*2.0,a2.*q1.*2.0+a3.*q0.*2.0,a1.*q1.*2.0+a2.*q2.*4.0+a3.*q3.*2.0,a1.*q0.*-2.0+a2.*q3.*2.0,a2.*q0.*-2.0+a3.*q1.*2.0,a1.*q0.*2.0+a3.*q2.*2.0,a1.*q1.*2.0+a2.*q2.*2.0+a3.*q3.*4.0],[3,4]); 
        % 
        % Settings 
        auto_mode = false;
        % Odo data 
        uncleaned_odometer_max = []; 
        mean_odo_velocity = []; 
        % Lagrangians 
        lagrngns = struct(); 
        dlgrngn_diter = 0.01; % in percent (0.01 ==> 0.0001) 
        slack_cap = 500; % in percent 
        cost_cap = 300; % absolute value 
    end 
    properties 
        simulate_ili_run_TITLE_1 = '<<<<< Data processing settings >>>>>'; 
        downsampling = []; 
        sampling_frequency = []; 
        moving_average_window = 5; 
        moving_average_coeffs = ones(9,1)/9; % 2x4+1 
        imu_gain_guess = mean([4.2229e-13]); % from past simulation experiments 
        odo_gain_guess = pi*0.0795; % meters 
        odo_gain_backcalc = pi*0.0795; % meters 
        earth_gravity = 9.81; 
        east_radius_of_earth = 6378100; % equatorial (Wikipedia) 
        north_radius_of_earth = 6356800; % polar (Wikipedia) 
        manifld_factr = 1; % manifold is default 
        rotn_factr = 1; % earth rotation is default value 
        % W_gps_eucldn = []; 
        rot_rate_of_earth = 7.292115e-5; % radians per second [=7.292115e-5*180/pi*86400 = 360.9856] 
        simulate_ili_run_TITLE_2 = '<<<<< Master data (downsampled) >>>>>'; 
        static_data = []; 
        raw_datapoints = []; 
        all_datapoints = []; 
        all_timepoints = []; 
        odometer_max = []; 
        marker_data = []; 
        marker_gps_distances = []; 
        marker_cumulative_gps_distances = []; 
        marker_ref_odo_distances = []; 
        marker_cumulative_ref_odo_distances = []; 
        ref_data = []; 
        vendor_data = []; 
        separation_indxs = []; 
        last_index = []; 
        last_index_loc = []; 
        simulate_ili_run_TITLE_3 = '<<<<< Subset data >>>>>'; 
        timepoints = []; 
        datapoints = []; 
        start_index = []; 
        end_index = []; 
        start_gps = []; 
        end_gps = []; 
        start_end_distance = []; 
        selected_marker_indices = []; 
        map_markers = []; 
        simulate_ili_run_TITLE_3o1 = '<<<<< Theory stuff + Tools >>>>>'; 
        dCqadq = []; % = (a,q) obj.dCqadq_core(a(1),a(2),a(3),q(1),q(2),q(3),q(4)); 
        to_obj = to_tools(); 
        simulate_ili_run_TITLE_4 = '<<<<< IMU and pipeline objects >>>>>'; 
        imu_device_obj = []; 
        simulate_ili_run_TITLE_5 = '<<<<< RESULTS >>>>>'; 
        best_gain = []; 
        best_initial_orientation = []; 
        best_final_orientation = []; 
        best_quaternion_orientation_trajectory = []; 
        best_euler_orientation_trajectory = []; 
        integrated_datapoints = struct(); 
        error_results = [];  
        auto_inputs = struct(); 
    end 
    methods 
        %% Core 
        function obj = simulate_ili_run(varargin) 
            if nargin>0 
                % test case execution 
                if isempty(varargin{1}) 
                    obj = obj.tests(); 
                    return 
                end 
                % get new data 
                obj.default_settings(); 
                if nargin==1 
                    [obj.downsampling] = varargin{:}; 
                elseif nargin==2  
                    [obj.downsampling, obj.moving_average_window] = varargin{:}; 
                elseif nargin==3 
                    [obj.downsampling, obj.auto_mode, obj.auto_inputs] = varargin{:}; 
                    disp('Fields:') 
                    disp(' --> selected_marker_indices') 
                    disp(' --> S6.sentvty') 
                    if ~isfield(obj.auto_inputs,'selected_marker_indices') %|| ~isfield(obj.auto_inputs,'selected_marker_indices') 
                        error('Insufficient fields in `obj.auto_inputs`') 
                    end 
                end 
            else 
                % change default data 
                obj.default_settings(); 
            end 
            % obj.W_gps_eucldn = diag([obj.north_radius_of_earth*pi/180;obj.east_radius_of_earth*pi/180;1]); 
            obj.set_sampling_and_resample_data(); 
            obj.load_best(); 
            
            % for this S6 version -- magnitude of velocity is constant in
            % the dynamics 
            obj.mean_odo_velocity = obj.odo_gain_guess*mean(diff(obj.odometer_max(obj.start_index:obj.end_index)))...
                *obj.sampling_frequency/obj.downsampling; 
            disp(['Mean velocity =  ', num2str(obj.mean_odo_velocity)]) 
            disp(['Mean distance per downsample =  ', num2str(obj.mean_odo_velocity*obj.downsampling/obj.sampling_frequency)]) 
%             disp(['Mean distance per sec =  ', num2str(obj.mean_odo_velocity*(obj.downsampling/10)/obj.sampling_frequency)]) 
            disp(['Total distance from mean velocity =  ', num2str(obj.mean_odo_velocity*(obj.downsampling/obj.sampling_frequency)*(obj.end_index-obj.start_index))]) 
%             disp(['Mean distance per sec =  ', num2str(obj.mean_odo_velocity*obj.downsampling/obj.sampling_frequency)]) 
%             disp(['Total distance from mean velocity =  ', num2str(obj.mean_odo_velocity*(obj.end_index-obj.start_index))]) 
            disp(['Total distance from total odo count = ', num2str((obj.odometer_max(obj.end_index)-obj.odometer_max(obj.start_index))*obj.odo_gain_guess)]) 
            disp(['Total straight distance from gps markers = ', num2str(gps2meters(obj.start_gps(1),obj.start_gps(2),obj.end_gps(1),obj.end_gps(2)))]) 
            % 
            obj.about(); 
        end 
        function new_obj = tests(~) 
            clc 

            new_obj = test_simulate_ili_run_case1(); 
            % new_obj = test_simulate_ili_run_case2();  

        end 
        function about(~) 
            disp('This is a sample class framework! '); 
            st = dbstack;
            namestr = st.name; 
            class_name = namestr(1:end-6); 
            disp(['Class name: ', class_name]) 
        end 
        %% Useful methods 
        % Get methods: get_ 
        % --> gravity stuffs 
        function [g, g_mes] = get_static_gravity(obj) 
            g_mes = mean(obj.static_data(4:6,:),2); 
            norm(obj.earth_gravity/norm(g_mes)*g_mes); 
            g = obj.earth_gravity/norm(g_mes)*g_mes; 
        end 
        function k = get_accelerometer_gain(obj) 
            [g, g_mes] = obj.get_static_gravity(); 
            k = mean(g./g_mes); 
            obj.acc_gain = k; 
        end 
        function [g, g_mes] = get_gravity_at_fraction_or_index(varargin) 
            obj = varargin{1}; 
            if nargin>1 
                frac_or_indx = varargin{2}; 
            else 
                disp('Showing result for: `get_gravity_at_fraction(0)` - initial gravity. ') 
                frac_or_indx = 0; 
            end 
            use_as_index = false; 
            if frac_or_indx(end)>2 
                use_as_index = true; 
                disp(' ') 
                disp('Argument is treated as INDEX! ') 
            elseif frac_or_indx<0 || frac_or_indx>1 
                warning('ERROR: faction of the total period should be between 0 and 1! ') 
                return 
            else 
                disp(' ') 
                disp('Argument is treated as FRACTION! ') 
            end 
            % 
            if use_as_index 
                indx = frac_or_indx; 
            else 
                indx = max(1,floor(size(obj.all_datapoints,2)*frac_or_indx)); 
            end 
            if isempty(obj.acc_gain) 
                obj.get_accelerometer_gain(); 
            end 
            g_mes = obj.all_datapoints(4:6,indx); 
            g = obj.acc_gain*g_mes; 
        end 
        function [gstart,gfinish,ghit,gmrkd,hit_indxs,mrkd_indxs] = get_op_at_markers(obj,y_traj) 
            [gstart,gfinish,ghit,gmrkd,hit_indxs,mrkd_indxs] = obj.odo_hidden_marker_hit(y_traj); 
        end 
        % --> indexing and others 
        function [deli,si,ei] = get_delta_index(obj) 
            si = obj.start_index; 
            ei = obj.end_index; 
            deli = ei - si; 
        end 
        function elites = elite_selection(~,best,noel,div,scl) 
            sel = floor(div*noel/100); 
            old_best = best(:,1:sel(1)); 
            old_better = (0.8+0.6*rand)*best(:,1:sel(2)); 
            nonb = noel-sel(1)-sel(2); 
            new_best = scl*best(:,1:nonb) + (1-scl)*best(:,datasample(1:noel,nonb)); 
            elites = [old_best,old_better,new_best]; 
        end 
        function get_mat_S6toS5(~) 
            try 
                load(['../OUTPUT', obj.auto_inputs.path_suffix, '/to_continue_unkwn_dT_vel_scld.mat']) 
                start_iter = 1; 
                save(['../OUTPUT', obj.auto_inputs.path_suffix, '/to_continue_unkwn_dT.mat'],'start_iter','agb_now2') 
            catch 
                warning('ERROR: can`t load `to_continue_unkwn_dT_vel_scld.mat`!') 
            end 
        end 
        % --> applying generated orentations 
        function q = get_orientation_quaternion(varargin) 
            obj = varargin{1}; 
            if nargin>1 
                frac_or_indx = varargin{2}; 
            else 
                disp('Showing result for: `get_gravity_at_fraction(0)` - initial gravity. ') 
                frac_or_indx = 0; 
            end 
            use_as_index = false; 
            if frac_or_indx(end)>2 
                use_as_index = true; 
                disp(' ') 
                disp('Argument is treated as INDEX! ') 
            elseif frac_or_indx<0 || frac_or_indx>1 
                warning('ERROR: faction of the total period should be between 0 and 1! ') 
                return 
            else 
                disp(' ') 
                disp('Argument is treated as FRACTION! ') 
            end 
            % 
            if use_as_index 
                indx = frac_or_indx; 
            else 
                indx = max(1,floor(size(obj.all_datapoints,2)*frac_or_indx)); 
            end 
            if isempty(obj.best_quaternion_orientation_trajectory) 
                warning('run `main_best_orientation_trajectory()` first OR load relevant .mat file! ') 
                return 
            end 
            q = obj.best_quaternion_orientation_trajectory(:,indx); 
        end 
        function eot = get_euler_orientation_trajectory(varargin) 
            obj = varargin{1}; 
            if nargin>1 
                orient_traj = varargin{2}; 
            else 
                orient_traj = obj.best_quaternion_orientation_trajectory; 
            end 
            % 
            sz_quaternion_orient_traj = size(orient_traj,2); 
            eot = zeros(3,sz_quaternion_orient_traj); 
            for i=1:sz_quaternion_orient_traj 
                eot(:,i) = transpose(quat2eul(orient_traj(:,i)')*180/pi); 
            end 
        end 
        function acc_gen = get_oriented_gravity_in_body_frame(varargin) % gravity is oriented 
            obj = varargin{1}; 
            if nargin>1 
                indices = varargin{2}; 
            else 
                indices = obj.start_index:floor(obj.delta_index/20):obj.end_index; 
            end 
            if nargin>2 
                orient_traj = varargin{3}; 
            else 
                orient_traj = obj.best_quaternion_orientation_trajectory; 
            end 
            CT_q = @(q) quat2rotm(q')'; 
            noindices = length(indices); 
            acc_gen = zeros(3,noindices); 
            for i=1:noindices 
                new_q = orient_traj(:,i); 
                acc_gen(:,i) = CT_q(new_q)*[0;0;obj.earth_gravity]; 
            end 
        end 
        function acc_gen = get_oriented_acceleration_trajectory_in_NWU_frame(varargin) % gravity is oriented 
            obj = varargin{1}; 
            if nargin>1 
                indices = varargin{2}; 
            else 
                indices = obj.start_index:floor(obj.delta_index/20):obj.end_index; 
            end 
            if nargin>2 
                orient_traj = varargin{3}; 
            else 
                orient_traj = obj.best_quaternion_orientation_trajectory; 
            end 
            if nargin>3 
                acc_gain_scl = varargin{4}; 
            else 
                acc_gain_scl = 1; 
            end 
            if nargin>4 
                acc_bias = varargin{5}; 
            else 
                acc_bias = [0;0;0]; 
            end 
            C_q = @(q) quat2rotm(q'); 
            noindices = length(indices); 
            acc_gen = zeros(3,noindices); 
            odo_all = obj.odo_gain_guess*repmat([diff(obj.odometer_max(indices)')', 0],3,1); 
            for i=1:noindices 
                new_q = orient_traj(:,i); 
                acc_gen(:,i) = C_q(new_q)*(acc_gain_scl*odo_all(:,i) + acc_bias); 
            end 
        end 
        function [marker_costs,end_point_cost,straightning_cost,odo_cost,vel_odo_cost] = get_costs_mrkd_S6b_odovelcst_lagr(varargin) 
            updt_lagr_en = false; 
            if nargin==5 
                [obj,odo_gen,p_gen,odo_data,noindices] = varargin{:}; 
            elseif nargin==6 
                [obj,odo_gen,p_gen,v_imu_magn,odo_data,noindices] = varargin{:}; 
            elseif nargin==7 
                [obj,odo_gen,p_gen,v_imu_magn,odo_data,noindices,updt_lagr_en] = varargin{:}; 
            elseif nargin==8 
                [obj,odo_gen,p_gen,v_imu_magn,odo_data,noindices,agb_now2,updt_lagr_en] = varargin{:}; 
            end 
            Div_odo = 5e3; 
            % v-- here 
            Q = diag([2e7,2e7,1e-3]); % 1km error x-y plane & z axis produces ~1e3 
            end_Wt = [1,10,1,1,1;1,10,1,2,1]; % marker_costs,end_point_cost,straightning_cost,odo_cost,vel_odo_cost 
            eps_end_pt = -0.25*[0.2,0.5]; % put minus sign to DISABLE 
            elevation_allowed = 5; % meters 
            % 
            final_state = p_gen(:,end); 
            %             straightning_err = [p_gen(1,ceil(noindices/2)),p_gen(2,ceil(noindices/2))] - ...
            %                 [mean([obj.start_gps(1),p_gen(1,end)]),mean([obj.start_gps(2),p_gen(2,end)])]; 
            % %                     straightning_err = [p_gen(1,ceil(noindices/2)),p_gen(2,ceil(noindices/2))] - ...
            % %                         [mean([obj.start_gps(1),obj.end_gps(1)]),mean([obj.start_gps(2),obj.end_gps(2)])]; 
            %             straightning_cost = 0*straightning_err*Q(1:2,1:2)*straightning_err'; 
            elevation_cost = 1e-1*max(elevation_allowed,...
                (final_state(3)-obj.end_gps(3))*Q(3,3)*(final_state(3)-obj.end_gps(3))); 
            gps_dist_cost = 1e0*(final_state(1:2)-obj.end_gps(1:2)')'*Q(1:2,1:2)*(final_state(1:2)-obj.end_gps(1:2)'); 
            end_point_cost = gps_dist_cost + elevation_cost; 
            straightning_err = [p_gen(1,ceil(noindices/2)),p_gen(2,ceil(noindices/2))] - ...
                [mean([obj.start_gps(1),p_gen(1,end)]),mean([obj.start_gps(2),p_gen(2,end)])]; 
%                     straightning_err = [p_gen(1,ceil(noindices/2)),p_gen(2,ceil(noindices/2))] - ...
%                         [mean([obj.start_gps(1),obj.end_gps(1)]),mean([obj.start_gps(2),obj.end_gps(2)])]; 
            straightning_cost = 0*straightning_err*Q(1:2,1:2)*straightning_err'; 
            oerr = (odo_data - odo_data(1)) - odo_gen; 
            odo_cost = 1e-1*sqrt(sum(oerr.^2))/Div_odo; % <-- here 
            voerr = oerr(2:end)-oerr(1:end-1); 
            vel_odo_mismatch_cost = 30*sum((v_imu_magn-obj.mean_odo_velocity).^2); 
            if nargin==8 
                vel_scale_cost = 100*(agb_now2(1)-1)^2; 
            else 
                vel_scale_cost = 0; 
            end 
            vel_odo_cost = vel_odo_mismatch_cost + vel_scale_cost; 
            y_fulltraj = [transpose(odo_data(1)+odo_gen)/obj.odo_gain_guess,p_gen']; 
            [gstart,gfinish,~,gmrkd] = obj.odo_marker_hit(y_fulltraj); 
            err_res = obj.marker_NW_distance(gstart,gfinish,gmrkd,false); 
            marker_costs = obj.lagrngns.marker*(10/30)*sqrt(sum(err_res.^2)); 
            % odo_cost = 50*odo_cost; % manual edit 
            % end_point_cost = 50*end_point_cost; 
            if marker_costs<eps_end_pt(1) 
                marker_costs = end_Wt(1,1)*marker_costs; 
                end_point_cost = end_Wt(1,2)*end_point_cost; 
                straightning_cost = end_Wt(1,3)*straightning_cost; 
                odo_cost = end_Wt(1,4)*odo_cost; 
                vel_odo_cost = end_Wt(1,5)*vel_odo_cost; 
            elseif marker_costs<eps_end_pt(2) 
                marker_costs = end_Wt(2,1)*marker_costs; 
                end_point_cost = end_Wt(2,2)*end_point_cost; 
                straightning_cost = end_Wt(2,3)*straightning_cost; 
                odo_cost = end_Wt(2,4)*odo_cost; 
                vel_odo_cost = end_Wt(2,5)*vel_odo_cost; 
            end 
            % cost caps 
%             marker_costs = max(-obj.cost_cap,min(marker_costs,obj.cost_cap)); 
%             end_point_cost = max(-obj.cost_cap,min(end_point_cost,obj.cost_cap)); 
%             straightning_cost = max(-obj.cost_cap,min(straightning_cost,obj.cost_cap)); 
%             odo_cost = max(-obj.cost_cap,min(odo_cost,obj.cost_cap)); 
%             vel_odo_cost = max(-obj.cost_cap,min(vel_odo_cost,obj.cost_cap)); 
            % lagrangians  
            if updt_lagr_en; obj.update_lagrangians(err_res); end 
        end 
        function [marker_costs,end_point_cost,straightning_cost,odo_cost,vel_odo_cost] = get_costs_mrkd_S6b_odovelcst_loglagr(varargin) 
            updt_lagr_en = false; 
            if nargin==5 
                [obj,odo_gen,p_gen,odo_data,noindices] = varargin{:}; 
            elseif nargin==6 
                [obj,odo_gen,p_gen,v_imu_magn,odo_data,noindices] = varargin{:}; 
            elseif nargin==7 
                [obj,odo_gen,p_gen,v_imu_magn,odo_data,noindices,updt_lagr_en] = varargin{:}; 
            elseif nargin==8 
                [obj,odo_gen,p_gen,v_imu_magn,odo_data,noindices,agb_now2,updt_lagr_en] = varargin{:}; 
            elseif nargin==11 
                [obj,odo_gen,p_gen,q_gen,v_gen,rotated_gravity,v_imu_magn,odo_data,noindices,agb_now2,updt_lagr_en] = varargin{:}; 
            end 
            Div_odo = 5e3; 
            % v-- here 
            Q = diag([2e7,2e7,1e-3]); % 1km error x-y plane & z axis produces ~1e3 
            end_Wt = [1,10,1,1,1;1,10,1,2,1]; % marker_costs,end_point_cost,straightning_cost,odo_cost,vel_odo_cost 
            eps_end_pt = -0.25*[0.2,0.5]; % put minus sign to DISABLE 
            elevation_allowed = 5; % meters 
            % 
            final_state = p_gen(:,end); 
            %             straightning_err = [p_gen(1,ceil(noindices/2)),p_gen(2,ceil(noindices/2))] - ...
            %                 [mean([obj.start_gps(1),p_gen(1,end)]),mean([obj.start_gps(2),p_gen(2,end)])]; 
            % %                     straightning_err = [p_gen(1,ceil(noindices/2)),p_gen(2,ceil(noindices/2))] - ...
            % %                         [mean([obj.start_gps(1),obj.end_gps(1)]),mean([obj.start_gps(2),obj.end_gps(2)])]; 
            %             straightning_cost = 0*straightning_err*Q(1:2,1:2)*straightning_err'; 
            elevation_cost = 1e-1*max(elevation_allowed,...
                (final_state(3)-obj.end_gps(3))*Q(3,3)*(final_state(3)-obj.end_gps(3))); 
            gps_dist_cost = 1e0*(final_state(1:2)-obj.end_gps(1:2)')'*Q(1:2,1:2)*(final_state(1:2)-obj.end_gps(1:2)'); 
            end_point_cost = gps_dist_cost + elevation_cost; 
            straightning_err = [p_gen(1,ceil(noindices/2)),p_gen(2,ceil(noindices/2))] - ...
                [mean([obj.start_gps(1),p_gen(1,end)]),mean([obj.start_gps(2),p_gen(2,end)])]; 
%                     straightning_err = [p_gen(1,ceil(noindices/2)),p_gen(2,ceil(noindices/2))] - ...
%                         [mean([obj.start_gps(1),obj.end_gps(1)]),mean([obj.start_gps(2),obj.end_gps(2)])]; 
            straightning_cost = 0*straightning_err*Q(1:2,1:2)*straightning_err'; 
            oerr = (odo_data - odo_data(1)) - odo_gen; 
            odo_cost = 1e-1*sqrt(sum(oerr.^2))/Div_odo; % <-- here 
            voerr = oerr(2:end)-oerr(1:end-1); 
            vel_odo_mismatch_cost = 30*sum((v_imu_magn-obj.mean_odo_velocity).^2); 
            if nargin==8 
                vel_scale_cost = 100*(agb_now2(1)-1)^2; 
            else 
                vel_scale_cost = 0; 
            end 
            vel_odo_cost = 0*vel_odo_mismatch_cost + vel_scale_cost; 
            y_fulltraj = [transpose(odo_data(1)+odo_gen)/obj.odo_gain_guess,p_gen']; 
            [gstart,gfinish,~,gmrkd] = obj.odo_marker_hit(y_fulltraj); 
            err_res = obj.marker_NW_distance(gstart,gfinish,gmrkd,false); 
            marker_costs = obj.lagrngns.marker*(10/30)*sqrt(sum(err_res.^2)); 
            % odo_cost = 50*odo_cost; % manual edit 
            % end_point_cost = 50*end_point_cost; 
            if marker_costs<eps_end_pt(1) 
                marker_costs = end_Wt(1,1)*marker_costs; 
                end_point_cost = end_Wt(1,2)*end_point_cost; 
                straightning_cost = end_Wt(1,3)*straightning_cost; 
                odo_cost = end_Wt(1,4)*odo_cost; 
                vel_odo_cost = end_Wt(1,5)*vel_odo_cost; 
            elseif marker_costs<eps_end_pt(2) 
                marker_costs = end_Wt(2,1)*marker_costs; 
                end_point_cost = end_Wt(2,2)*end_point_cost; 
                straightning_cost = end_Wt(2,3)*straightning_cost; 
                odo_cost = end_Wt(2,4)*odo_cost; 
                vel_odo_cost = end_Wt(2,5)*vel_odo_cost; 
            end 
            % cost caps 
%             marker_costs = max(-obj.cost_cap,min(marker_costs,obj.cost_cap)); 
%             end_point_cost = max(-obj.cost_cap,min(end_point_cost,obj.cost_cap)); 
%             straightning_cost = max(-obj.cost_cap,min(straightning_cost,obj.cost_cap)); 
%             odo_cost = max(-obj.cost_cap,min(odo_cost,obj.cost_cap)); 
%             vel_odo_cost = max(-obj.cost_cap,min(vel_odo_cost,obj.cost_cap)); 
            % lagrangians  
            if updt_lagr_en; obj.update_loglagrangians(err_res); end 
            % 
            acc_body_frame = diff(v_gen')*obj.downsampling/obj.sampling_frequency + rotated_gravity(:,2:end)'; 
            imu_acc_data = transpose(diag(obj.best_gain(1:3))*obj.datapoints(4:6,1:end-1));
            error_acc = acc_body_frame(2:end,:) - imu_acc_data(2:end,:); 
            mse_acc = 0.8*sum(sum(error_acc.*error_acc,1)); 
            straightning_cost = straightning_cost + mse_acc; 
            % plot(acc_body_frame)
            % hold on; plot((diag(obj.best_gain(1:3))*obj.datapoints(4:6,:))'); hold off
        end 
        % --> system dynamics portions  
        function [odo_dist, gain] = get_odometer_distance(varargin) % generate distance from odometer 
            obj = varargin{1}; 
            if nargin>1 
                indices = varargin{2}; 
            else 
                indices = obj.start_index:floor(obj.delta_index/20):obj.end_index; 
            end 
            % noindices = length(indices); 
            odo_dist = obj.odo_gain_guess*obj.odometer_max(:,indices); gain = obj.odo_gain_guess; 
            % odo_dist = obj.odo_gain_backcalc*obj.odometer_max(:,indices); gain = obj.odo_gain_backcalc; 
        end 
        function [q_dot,q,v_dot,v,p_gen,odo_gen,acc_ef] = get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld(varargin) 
            obj = varargin{1}; 
            agb_now = varargin{2};  % <-- angle, gains, and biases 
            if nargin>2 % epsilon 
                epsilon = varargin{3}; 
            else 
                epsilon = 1; 
            end 
            if nargin>3 % indices 
                indices = varargin{4}; 
            else 
                indices = obj.start_index:obj.end_index; 
            end 
            if nargin>4 % g and w as input 
                odo_all = varargin{5}; 
                w_all = varargin{6}; 
                f = varargin{7}; 
                g = varargin{8}; 
                C_nb = varargin{9}; 
            else 
                odo_all = obj.odo_gain_guess*repmat([diff(obj.odometer_max(indices)')', 0],3,1); 
                w_all = diag(obj.best_gain(4:end))*obj.all_datapoints(1:3,indices); 
            end 
            % 
            vel_odo_gain = agb_now(1); 
            % acc_gain_mat = diag(agb_now(2:4)); 
            acc_bias = agb_now(5:7); 
            % gyro_gain_mat = diag(agb_now(8:10)); 
            gyro_bias = agb_now(11:13); 
            params = [agb_now([2:4,8:10]);agb_now(21)*obj.downsampling/10;vel_odo_gain]; 
            % q0 = obj.best_initial_orientation + agb_now(14:17); 
            q0 = rotm2quat(rotx(obj.start_gps(2))*roty(obj.start_gps(1))*quat2rotm(obj.best_initial_orientation'))'...
                 + agb_now(14:17); 
            v0 = agb_now(18:20); 
            dT = agb_now(21)*(indices(2)-indices(1))*obj.downsampling/10; 
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
            p_gen(:,1) = obj.start_gps'; 
            % 
            for ix=2:noindices 
                indx = indices(ix-1); 
                old_q = obj.best_quaternion_orientation_trajectory(:,indx); 
                new_q = epsilon*old_q + (1-epsilon)*q(:,ix-1); 
                new_q = new_q/norm(new_q); 
                % dT = obj.downsampling*(indices(ix)-indices(ix-1))/obj.sampling_frequency; 
                t = dT*(ix-2); 
                % 
                x = [odo_gen(:,ix-1);p_gen(:,ix-1);new_q;v(:,ix-1);acc_bias;gyro_bias]; 
                u = [odo_all(:,ix-1);w_all(:,ix-1)]; 
                x = f(x) + g(t,x,u,params); 
                odo_gen(:,ix) = x(1); p_gen(:,ix) = x(2:4); q(:,ix) = x(5:8); v(:,ix) = x(9:11); 
                % 
                q_dot(:,ix) = (q(:,ix) - q(:,ix-1))/dT; 
                v_dot(:,ix) = (v(:,ix) - v(:,ix-1))/dT; 
                acc_ef(:,ix) = transpose(C_nb(dT*(ix-1),p_gen(:,ix),q(:,ix),v(:,ix)))...
                    *[0;0;obj.earth_gravity]; 
            end 
            % odo_gen = odo_gain*dT*cumsum(sqrt(sum(v.*v,1))); 
        end 
        function [f,g,h,h_ext,f_guess,g_guess,... % get_full_dynamics_manifold
                h_guess,h_ext_guess,A,B,C,C_ext,n_omega_ie,n_omega_en,...
                Sx,Qx,C_nb,gl,G_func,f_s,f_p,q_gen,f_q,f_v,f_sns] = get_full_dynamics_manifold(obj) 
            dT = obj.downsampling/obj.sampling_frequency; 
            % 
            Af = @(a1,a2,a3,ba1,ba2,ba3,bw1,bw2,bw3,ka1,ka2,ka3,kw1,kw2,kw3,p1,p2,p3,q0,q1,q2,q3,t,v1,v2,v3,w1,w2,w3)reshape([0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,(v2.*sin((p1.*pi)./1.8e+2))./((sin((p1.*pi)./1.8e+2).^2-1.0).*(p3+6.3781e+6)),0.0,0.0,0.0,0.0,0.0,v2.*(pi.*cos((p1.*pi)./1.8e+2).*8.10235e-7-(v2.*pi.*(tan((p1.*pi)./1.8e+2).^2+1.0))./(p3.*1.8e+2+1.148058e+9))+(ba1+a1.*ka1).*(pi.*sin((p1.*pi)./1.8e+2).*(q0.^2.*2.0+q1.^2.*2.0-1.0).*(-1.0./1.8e+2)+(pi.*cos((p1.*pi)./1.8e+2).*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q2.*2.0-q1.*q3.*2.0))./1.8e+2+(pi.*cos((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q3.*2.0+q1.*q2.*2.0))./1.8e+2)+(ba2+a2.*ka2).*((pi.*sin((p1.*pi)./1.8e+2).*(q0.*q3.*2.0-q1.*q2.*2.0))./1.8e+2+(pi.*cos((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.^2.*2.0+q2.^2.*2.0-1.0))./1.8e+2-(pi.*cos((p1.*pi)./1.8e+2).*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q1.*2.0+q2.*q3.*2.0))./1.8e+2)-(ba3+a3.*ka3).*((pi.*sin((p1.*pi)./1.8e+2).*(q0.*q2.*2.0+q1.*q3.*2.0))./1.8e+2+(pi.*cos((p1.*pi)./1.8e+2).*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.^2.*2.0+q3.^2.*2.0-1.0))./1.8e+2+(pi.*cos((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q1.*2.0-q2.*q3.*2.0))./1.8e+2)-pi.*cos((p1.*pi)./1.8e+2).^2.*(p3+6.3781e+6).*2.9541633985125e-11+pi.*sin((p1.*pi)./1.8e+2).^2.*(p3+6.3781e+6).*2.9541633985125e-11,-v1.*(pi.*cos((p1.*pi)./1.8e+2).*8.10235e-7-(v2.*pi.*(tan((p1.*pi)./1.8e+2).^2+1.0))./(p3.*1.8e+2+1.148058e+9))-v3.*pi.*sin((p1.*pi)./1.8e+2).*8.10235e-7,(ba1+a1.*ka1).*((pi.*cos((p1.*pi)./1.8e+2).*(q0.^2.*2.0+q1.^2.*2.0-1.0))./1.8e+2+(pi.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*(q0.*q2.*2.0-q1.*q3.*2.0))./1.8e+2+(pi.*sin((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q3.*2.0+q1.*q2.*2.0))./1.8e+2)-(ba2+a2.*ka2).*((pi.*cos((p1.*pi)./1.8e+2).*(q0.*q3.*2.0-q1.*q2.*2.0))./1.8e+2-(pi.*sin((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.^2.*2.0+q2.^2.*2.0-1.0))./1.8e+2+(pi.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*(q0.*q1.*2.0+q2.*q3.*2.0))./1.8e+2)-(ba3+a3.*ka3).*(pi.*cos((p1.*pi)./1.8e+2).*(q0.*q2.*2.0+q1.*q3.*2.0).*(-1.0./1.8e+2)+(pi.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*(q0.^2.*2.0+q3.^2.*2.0-1.0))./1.8e+2+(pi.*sin((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q1.*2.0-q2.*q3.*2.0))./1.8e+2)+v2.*pi.*sin((p1.*pi)./1.8e+2).*8.10235e-7-pi.*cos((p1.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*(p3+6.3781e+6).*5.908326797025e-11,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,((pi.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*(q0.*q3.*2.0+q1.*q2.*2.0))./1.8e+2-(pi.*sin((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q2.*2.0-q1.*q3.*2.0))./1.8e+2).*(ba1+a1.*ka1)+((pi.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*(q0.^2.*2.0+q2.^2.*2.0-1.0))./1.8e+2+(pi.*sin((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q1.*2.0+q2.*q3.*2.0))./1.8e+2).*(ba2+a2.*ka2)+((pi.*sin((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.^2.*2.0+q3.^2.*2.0-1.0))./1.8e+2-(pi.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*(q0.*q1.*2.0-q2.*q3.*2.0))./1.8e+2).*(ba3+a3.*ka3),-((pi.*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.^2.*2.0+q2.^2.*2.0-1.0))./1.8e+2-(pi.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q1.*2.0+q2.*q3.*2.0))./1.8e+2).*(ba2+a2.*ka2)+((pi.*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q1.*2.0-q2.*q3.*2.0))./1.8e+2+(pi.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.^2.*2.0+q3.^2.*2.0-1.0))./1.8e+2).*(ba3+a3.*ka3)-((pi.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q2.*2.0-q1.*q3.*2.0))./1.8e+2+(pi.*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q3.*2.0+q1.*q2.*2.0))./1.8e+2).*(ba1+a1.*ka1),-((pi.*cos((p1.*pi)./1.8e+2).*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.^2.*2.0+q2.^2.*2.0-1.0))./1.8e+2+(pi.*cos((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q1.*2.0+q2.*q3.*2.0))./1.8e+2).*(ba2+a2.*ka2)-((pi.*cos((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.^2.*2.0+q3.^2.*2.0-1.0))./1.8e+2-(pi.*cos((p1.*pi)./1.8e+2).*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q1.*2.0-q2.*q3.*2.0))./1.8e+2).*(ba3+a3.*ka3)-((pi.*cos((p1.*pi)./1.8e+2).*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q3.*2.0+q1.*q2.*2.0))./1.8e+2-(pi.*cos((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q2.*2.0-q1.*q3.*2.0))./1.8e+2).*(ba1+a1.*ka1),0.0,0.0,0.0,0.0,0.0,0.0,0.0,(v1.*1.0./(p3+6.3568e+6).^2.*-1.8e+2)./pi,(v2.*1.0./(p3+6.3781e+6).^2.*1.8e+2)./(pi.*cos((p1.*pi)./1.8e+2)),0.0,0.0,0.0,0.0,0.0,sin((p1.*pi)./9.0e+1).*(-2.65874705866125e-9)+v1.*v3.*1.0./(p3+6.3568e+6).^2+v2.^2.*tan((p1.*pi)./1.8e+2).*1.0./(p3+6.3781e+6).^2,v2.*(v3-v1.*tan((p1.*pi)./1.8e+2)).*1.0./(p3+6.3781e+6).^2,-v1.^2.*1.0./(p3+6.3568e+6).^2-v2.^2.*1.0./(p3+6.3781e+6).^2+cos((p1.*pi)./1.8e+2).^2.*5.3174941173225e-9,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,bw1./2.0+(kw1.*w1)./2.0,bw2./2.0+(kw2.*w2)./2.0,bw3./2.0+(kw3.*w3)./2.0,(ba1+a1.*ka1).*(q2.*(cos(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2)-sin(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)).*2.0+q3.*(cos(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2)).*2.0+q0.*cos((p1.*pi)./1.8e+2).*4.0)-(ba2+a2.*ka2).*(q0.*(cos(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2)).*-4.0+q1.*(cos(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2)-sin(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)).*2.0+q3.*cos((p1.*pi)./1.8e+2).*2.0)-(ba3+a3.*ka3).*(q0.*(cos(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2)-sin(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)).*4.0+q1.*(cos(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2)).*2.0-q2.*cos((p1.*pi)./1.8e+2).*2.0),(q3.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*2.0-q2.*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*2.0).*(ba1+a1.*ka1)+(q0.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*4.0+q1.*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*2.0).*(ba2+a2.*ka2)-(q1.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*2.0-q0.*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*4.0).*(ba3+a3.*ka3),-(ba1+a1.*ka1).*(q2.*(cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2)-sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)).*2.0+q3.*(cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2)).*2.0-q0.*sin((p1.*pi)./1.8e+2).*4.0)-(ba2+a2.*ka2).*(q0.*(cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2)).*4.0-q1.*(cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2)-sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)).*2.0+q3.*sin((p1.*pi)./1.8e+2).*2.0)+(ba3+a3.*ka3).*(q0.*(cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2)-sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)).*4.0+q1.*(cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2)).*2.0+q2.*sin((p1.*pi)./1.8e+2).*2.0),0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,bw1.*(-1.0./2.0)-(kw1.*w1)./2.0,0.0,bw3.*(-1.0./2.0)-(kw3.*w3)./2.0,bw2./2.0+(kw2.*w2)./2.0,-(ba2+a2.*ka2).*(q0.*(cos(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2)-sin(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)).*2.0-q2.*cos((p1.*pi)./1.8e+2).*2.0)-(ba3+a3.*ka3).*(q0.*(cos(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2)).*2.0-q3.*cos((p1.*pi)./1.8e+2).*2.0)+(ba1+a1.*ka1).*(q2.*(cos(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2)).*2.0-q3.*(cos(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2)-sin(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)).*2.0+q1.*cos((p1.*pi)./1.8e+2).*4.0),(q2.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*2.0+q3.*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*2.0).*(ba1+a1.*ka1)-q0.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(ba3+a3.*ka3).*2.0+q0.*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(ba2+a2.*ka2).*2.0,(ba2+a2.*ka2).*(q0.*(cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2)-sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)).*2.0+q2.*sin((p1.*pi)./1.8e+2).*2.0)+(ba3+a3.*ka3).*(q0.*(cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2)).*2.0+q3.*sin((p1.*pi)./1.8e+2).*2.0)+(ba1+a1.*ka1).*(q2.*(cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2)).*-2.0+q3.*(cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2)-sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)).*2.0+q1.*sin((p1.*pi)./1.8e+2).*4.0),0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,bw2.*(-1.0./2.0)-(kw2.*w2)./2.0,bw3./2.0+(kw3.*w3)./2.0,0.0,bw1.*(-1.0./2.0)-(kw1.*w1)./2.0,(ba2+a2.*ka2).*(q1.*cos((p1.*pi)./1.8e+2).*2.0+q3.*sin(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2).*2.0-q3.*cos(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*2.0+q2.*cos(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2).*4.0+q2.*sin(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*4.0)+(ba3+a3.*ka3).*(q0.*cos((p1.*pi)./1.8e+2).*2.0+q3.*cos(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2).*2.0+q3.*sin(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*2.0)+sin((p1.*pi)./1.8e+2).*(q0.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2)+q1.*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2)).*(ba1.*2.0+a1.*ka1.*2.0),(q1.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*2.0-q0.*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*2.0).*(ba1+a1.*ka1)+(q2.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*4.0+q3.*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*2.0).*(ba2+a2.*ka2)+q3.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(ba3+a3.*ka3).*2.0,-(ba2+a2.*ka2).*(q1.*sin((p1.*pi)./1.8e+2).*-2.0-q3.*cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2).*2.0+q2.*cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2).*4.0+q2.*sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2).*4.0+q3.*sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2).*2.0)-(ba3+a3.*ka3).*(q0.*sin((p1.*pi)./1.8e+2).*-2.0+q3.*cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2).*2.0+q3.*sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2).*2.0)-cos((p1.*pi)./1.8e+2).*(q0.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2)+q1.*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2)).*(ba1.*2.0+a1.*ka1.*2.0),0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,bw3.*(-1.0./2.0)-(kw3.*w3)./2.0,bw2.*(-1.0./2.0)-(kw2.*w2)./2.0,bw1./2.0+(kw1.*w1)./2.0,0.0,(ba3+a3.*ka3).*(q1.*cos((p1.*pi)./1.8e+2).*2.0+q3.*sin(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2).*4.0-q3.*cos(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*4.0+q2.*cos(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2).*2.0+q2.*sin(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*2.0)-(ba2+a2.*ka2).*(q0.*cos((p1.*pi)./1.8e+2).*2.0-q2.*sin(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2).*2.0+q2.*cos(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*2.0)-sin((p1.*pi)./1.8e+2).*(q1.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2)-q0.*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2)).*(ba1.*2.0+a1.*ka1.*2.0),(q0.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*2.0+q1.*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*2.0).*(ba1+a1.*ka1)+(q2.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*2.0+q3.*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*4.0).*(ba3+a3.*ka3)+q2.*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(ba2+a2.*ka2).*2.0,-(ba3+a3.*ka3).*(q1.*sin((p1.*pi)./1.8e+2).*-2.0-q3.*cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2).*4.0+q2.*cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2).*2.0+q2.*sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2).*2.0+q3.*sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2).*4.0)-(ba2+a2.*ka2).*(q0.*sin((p1.*pi)./1.8e+2).*2.0-q2.*cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2).*2.0+q2.*sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2).*2.0)+cos((p1.*pi)./1.8e+2).*(q1.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2)-q0.*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2)).*(ba1.*2.0+a1.*ka1.*2.0),0.0,0.0,0.0,0.0,0.0,0.0,v1.*1.0./sqrt(v1.^2+v2.^2+v3.^2),1.8e+2./(pi.*(p3+6.3568e+6)),0.0,0.0,0.0,0.0,0.0,0.0,-v3./(p3+6.3568e+6),sin((p1.*pi)./1.8e+2).*(-1.458423e-4)+(v2.*tan((p1.*pi)./1.8e+2))./(p3+6.3781e+6),(v1.*2.0)./(p3+6.3568e+6),0.0,0.0,0.0,0.0,0.0,0.0,v2.*1.0./sqrt(v1.^2+v2.^2+v3.^2),0.0,-1.8e+2./(pi.*cos((p1.*pi)./1.8e+2).*(p3+6.3781e+6)),0.0,0.0,0.0,0.0,0.0,sin((p1.*pi)./1.8e+2).*1.458423e-4-(v2.*tan((p1.*pi)./1.8e+2).*2.0)./(p3+6.3781e+6),-(v3-v1.*tan((p1.*pi)./1.8e+2))./(p3+6.3781e+6),cos((p1.*pi)./1.8e+2).*(-1.458423e-4)+(v2.*2.0)./(p3+6.3781e+6),0.0,0.0,0.0,0.0,0.0,0.0,v3.*1.0./sqrt(v1.^2+v2.^2+v3.^2),0.0,0.0,1.0,0.0,0.0,0.0,0.0,-v1./(p3+6.3568e+6),cos((p1.*pi)./1.8e+2).*1.458423e-4-v2./(p3+6.3781e+6),0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,cos((p1.*pi)./1.8e+2).*(q0.^2.*2.0+q1.^2.*2.0-1.0)+cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*(q0.*q2.*2.0-q1.*q3.*2.0)+sin((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q3.*2.0+q1.*q2.*2.0),cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q3.*2.0+q1.*q2.*2.0)-sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q2.*2.0-q1.*q3.*2.0),sin((p1.*pi)./1.8e+2).*(q0.^2.*2.0+q1.^2.*2.0-1.0)-cos((p1.*pi)./1.8e+2).*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q2.*2.0-q1.*q3.*2.0)-cos((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q3.*2.0+q1.*q2.*2.0),0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,-cos((p1.*pi)./1.8e+2).*(q0.*q3.*2.0-q1.*q2.*2.0)+sin((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.^2.*2.0+q2.^2.*2.0-1.0)-cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*(q0.*q1.*2.0+q2.*q3.*2.0),cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.^2.*2.0+q2.^2.*2.0-1.0)+sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q1.*2.0+q2.*q3.*2.0),-sin((p1.*pi)./1.8e+2).*(q0.*q3.*2.0-q1.*q2.*2.0)-cos((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.^2.*2.0+q2.^2.*2.0-1.0)+cos((p1.*pi)./1.8e+2).*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q1.*2.0+q2.*q3.*2.0),0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,cos((p1.*pi)./1.8e+2).*(q0.*q2.*2.0+q1.*q3.*2.0)-cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*(q0.^2.*2.0+q3.^2.*2.0-1.0)-sin((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q1.*2.0-q2.*q3.*2.0),sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.^2.*2.0+q3.^2.*2.0-1.0)-cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q1.*2.0-q2.*q3.*2.0),sin((p1.*pi)./1.8e+2).*(q0.*q2.*2.0+q1.*q3.*2.0)+cos((p1.*pi)./1.8e+2).*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.^2.*2.0+q3.^2.*2.0-1.0)+cos((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q1.*2.0-q2.*q3.*2.0),0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,q1.*(-1.0./2.0),q0./2.0,q3./2.0,q2.*(-1.0./2.0),0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,q2.*(-1.0./2.0),q3.*(-1.0./2.0),q0./2.0,q1./2.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,q3.*(-1.0./2.0),q2./2.0,q1.*(-1.0./2.0),q0./2.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0],[17,17]); 
            A = @(t,x,u,prms) eye(17) + dT*Af(u(1),u(2),u(3),x(12),x(13),x(14),x(15),x(16),x(17),...
                prms(1),prms(2),prms(3),prms(4),prms(5),prms(6),x(2),x(3),x(4),x(5),x(6),x(7),x(8),...
                t,x(9),x(10),x(11),u(4),u(5),u(6)); 
            Bf = @(ka1,ka2,ka3,kw1,kw2,kw3,p1,p2,q0,q1,q2,q3,t)reshape([0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,ka1.*(cos((p1.*pi)./1.8e+2).*(q0.^2.*2.0+q1.^2.*2.0-1.0)+cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*(q0.*q2.*2.0-q1.*q3.*2.0)+sin((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q3.*2.0+q1.*q2.*2.0)),ka1.*(cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q3.*2.0+q1.*q2.*2.0)-sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q2.*2.0-q1.*q3.*2.0)),-ka1.*(-sin((p1.*pi)./1.8e+2).*(q0.^2.*2.0+q1.^2.*2.0-1.0)+cos((p1.*pi)./1.8e+2).*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q2.*2.0-q1.*q3.*2.0)+cos((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q3.*2.0+q1.*q2.*2.0)),0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,-ka2.*(cos((p1.*pi)./1.8e+2).*(q0.*q3.*2.0-q1.*q2.*2.0)-sin((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.^2.*2.0+q2.^2.*2.0-1.0)+cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*(q0.*q1.*2.0+q2.*q3.*2.0)),ka2.*(cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.^2.*2.0+q2.^2.*2.0-1.0)+sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q1.*2.0+q2.*q3.*2.0)),-ka2.*(sin((p1.*pi)./1.8e+2).*(q0.*q3.*2.0-q1.*q2.*2.0)+cos((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.^2.*2.0+q2.^2.*2.0-1.0)-cos((p1.*pi)./1.8e+2).*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q1.*2.0+q2.*q3.*2.0)),0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,-ka3.*(-cos((p1.*pi)./1.8e+2).*(q0.*q2.*2.0+q1.*q3.*2.0)+cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*(q0.^2.*2.0+q3.^2.*2.0-1.0)+sin((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q1.*2.0-q2.*q3.*2.0)),ka3.*(sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.^2.*2.0+q3.^2.*2.0-1.0)-cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q1.*2.0-q2.*q3.*2.0)),ka3.*(sin((p1.*pi)./1.8e+2).*(q0.*q2.*2.0+q1.*q3.*2.0)+cos((p1.*pi)./1.8e+2).*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.^2.*2.0+q3.^2.*2.0-1.0)+cos((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q1.*2.0-q2.*q3.*2.0)),0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,kw1.*q1.*(-1.0./2.0),(kw1.*q0)./2.0,(kw1.*q3)./2.0,kw1.*q2.*(-1.0./2.0),0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,kw2.*q2.*(-1.0./2.0),kw2.*q3.*(-1.0./2.0),(kw2.*q0)./2.0,(kw2.*q1)./2.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,kw3.*q3.*(-1.0./2.0),(kw3.*q2)./2.0,kw3.*q1.*(-1.0./2.0),(kw3.*q0)./2.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0],[17,6]); 
            B = @(t,x,u,prms) Bf(prms(1),prms(2),prms(3),prms(4),prms(5),prms(6),x(2),x(3),x(5),x(6),x(7),x(8),t); 
            H1 = [1/obj.odo_gain_guess,zeros(1,10),zeros(1,6)]; 
            H2 = [zeros(3,1),eye(3),zeros(3,4),zeros(3),zeros(3,6)]; 
            C = [H1; 0*H2]; 
            C_ext = [H1; H2]; 

            % Init 
            n_omega_ie = @(p) obj.rotn_factr*[obj.rot_rate_of_earth*cosd(p(1));0;obj.rot_rate_of_earth*sind(p(1))]; 
            n_omega_en = @(p,v) obj.manifld_factr*[-v(2)/((obj.east_radius_of_earth+p(3)));v(1)/(obj.north_radius_of_earth+p(3));-v(2)*tand(p(1))/(obj.east_radius_of_earth+p(3))]; 
            % n_omega_en = @(p,v) [-v(2)/((obj.east_radius_of_earth+p(3))*cosd(p(1)));-v(1)/(obj.north_radius_of_earth+p(3));0]; 
            Sx = @(w) [0,-w(3),w(2);w(3),0,-w(1);-w(2),w(1),0]; 
            Qx = @(w) 0.5*[0,-w(1),-w(2),-w(3);w(1),0,w(3),-w(2);w(2),-w(3),0,w(1);w(3),w(2),-w(1),0]; 
%             C_nb = @(t,p,q,v) quat2rotm(eul2quat([0,-p(1),-p(2)]*pi/180))'...
%                 *eul2rotm(-flip(omega_ie(p)')*t)*quat2rotm(q'); 
%             C_nb = @(t,p,q,v) rotx(-p(2))*axang2rotm([[0,1,0]*rotx(p(2))',-p(1)*pi/180])...
%                 *rotx(-t*obj.rot_rate_of_earth*180/pi)*quat2rotm(q'); % eul2rotm(flip(omega_ie(p)')*t)
            C_nb = @(t,p,q,v) roty(-p(1))*rotx(-p(2))...
                *rotx(-t*obj.rot_rate_of_earth*180/pi)*quat2rotm(q'); % eul2rotm(flip(omega_ie(p)')*t)
            % rotx(t/2) --> its a triangle not a square while integrating 
            gl = @(p) -Sx(n_omega_ie(p))*Sx(n_omega_ie(p))*[0;0;(obj.east_radius_of_earth+p(3))]+[0;0;-obj.earth_gravity]; 

            % dynamics and fix 
%             Fdyn = @(t,p,q,v,a,w) [...
%                 180*v(1)/(pi*(obj.north_radius_of_earth+p(3)));-180*v(2)/(pi*(obj.east_radius_of_earth+p(3))*cosd(p(1)));v(3);...
%                 (expm(Qx(w)*Ts)-eye(4))*q/Ts;... % Qx(w)*q;... % 
%                 (C_nb(t,p,q,v)*a-Sx(2*n_omega_ie(p)+n_omega_en(p,v))*v+gl(p))]; 
% %             imu_fix = @(t,p,q,v,a,w) [w-[v(2)/((obj.east_radius_of_earth+p(3))*cosd(p(1)));v(1)/(obj.north_radius_of_earth+p(3));0];...
% %                 a+C_nb(t,p,q,v)'*(Sx(n_omega_en(p,v))*v-gl(p))]; % w and a 
%             imu_fix = @(t,p,q,v,a,w) [w+C_nb(t,p,q,v)'*(n_omega_en(p,v) + n_omega_ie(p));...
%                 a+C_nb(t,p,q,v)'*(Sx(2*n_omega_ie(p)+n_omega_en(p,v))*v-gl(p))]; % w and a 
% %             imu_fix = @(t,p,q,v,a,w) [w+C_nb(t,p,q,v)'*(n_omega_ie(p)+n_omega_en(p,v));...
% %                 a+C_nb(t,p,q,v)'*(Sx(n_omega_en(p,v))*v-gl(p))]; % w and a 
            G_func = @(p,v) [180*v(1)/(pi*(obj.north_radius_of_earth+p(3)));...
                -180*v(2)/(pi*(obj.east_radius_of_earth+p(3))*cosd(p(1)));v(3)]; 
            f_s = @(s,v) s + dT*norm(v); 
            f_p = @(p,v) p + dT*G_func(p,v); 
            q_gen = @(q,bs,imu_w,prms) expm(Qx(prms(4:6).*imu_w + bs(4:6))*dT)*q; 
            f_q = @(q,bs,imu_w,prms) q_gen(q,bs,imu_w,prms); % [not needed] /norm(q_gen(q,bs,imu_w)); 
            f_v = @(t,p,q,v,bs,imu_a,prms) v + dT*(C_nb(t,p,q,v)*(prms(1:3).*imu_a + bs(1:3))...
                -Sx(2*n_omega_ie(p)+n_omega_en(p,v))*v+gl(p)); 
            % f_sym_tst = @(a1,a2,a3,ba1,ba2,ba3,bw1,bw2,bw3,ka1,ka2,ka3,kw1,kw2,kw3,p1,p2,p3,q0,q1,q2,q3,v1,v2,v3,w1,w2,w3)[sqrt(abs(v1).^2+abs(v2).^2+abs(v3).^2);(v1.*1.8e+2)./(pi.*(p3+6.3568e+6));(v2.*-1.8e+2)./(pi.*cos((p1.*pi)./1.8e+2).*(p3+6.3781e+6));v3;-q1.*(bw1./2.0+(kw1.*w1)./2.0)-q2.*(bw2./2.0+(kw2.*w2)./2.0)-q3.*(bw3./2.0+(kw3.*w3)./2.0);q0.*(bw1./2.0+(kw1.*w1)./2.0)-q3.*(bw2./2.0+(kw2.*w2)./2.0)+q2.*(bw3./2.0+(kw3.*w3)./2.0);q0.*(bw2./2.0+(kw2.*w2)./2.0)+q3.*(bw1./2.0+(kw1.*w1)./2.0)-q1.*(bw3./2.0+(kw3.*w3)./2.0);-q2.*(bw1./2.0+(kw1.*w1)./2.0)+q1.*(bw2./2.0+(kw2.*w2)./2.0)+q0.*(bw3./2.0+(kw3.*w3)./2.0);(ba1+a1.*ka1).*(cos((p1.*pi)./1.8e+2).*(q0.^2.*2.0+q1.^2.*2.0-1.0)+cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*(q0.*q2.*2.0-q1.*q3.*2.0)+sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2).*(q0.*q3.*2.0+q1.*q2.*2.0))-(ba2+a2.*ka2).*(cos((p1.*pi)./1.8e+2).*(q0.*q3.*2.0-q1.*q2.*2.0)-sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2).*(q0.^2.*2.0+q2.^2.*2.0-1.0)+cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*(q0.*q1.*2.0+q2.*q3.*2.0))-(ba3+a3.*ka3).*(-cos((p1.*pi)./1.8e+2).*(q0.*q2.*2.0+q1.*q3.*2.0)+cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*(q0.^2.*2.0+q3.^2.*2.0-1.0)+sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2).*(q0.*q1.*2.0-q2.*q3.*2.0));(cos((p2.*pi)./1.8e+2).*(q0.^2.*2.0+q2.^2.*2.0-1.0)+sin((p2.*pi)./1.8e+2).*(q0.*q1.*2.0+q2.*q3.*2.0)).*(ba2+a2.*ka2)+(sin((p2.*pi)./1.8e+2).*(q0.^2.*2.0+q3.^2.*2.0-1.0)-cos((p2.*pi)./1.8e+2).*(q0.*q1.*2.0-q2.*q3.*2.0)).*(ba3+a3.*ka3)+(ba1+a1.*ka1).*(cos((p2.*pi)./1.8e+2).*(q0.*q3.*2.0+q1.*q2.*2.0)-sin((p2.*pi)./1.8e+2).*(q0.*q2.*2.0-q1.*q3.*2.0));-(ba1+a1.*ka1).*(-sin((p1.*pi)./1.8e+2).*(q0.^2.*2.0+q1.^2.*2.0-1.0)+cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2).*(q0.*q2.*2.0-q1.*q3.*2.0)+cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2).*(q0.*q3.*2.0+q1.*q2.*2.0))-(ba2+a2.*ka2).*(sin((p1.*pi)./1.8e+2).*(q0.*q3.*2.0-q1.*q2.*2.0)+cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2).*(q0.^2.*2.0+q2.^2.*2.0-1.0)-cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2).*(q0.*q1.*2.0+q2.*q3.*2.0))+(ba3+a3.*ka3).*(sin((p1.*pi)./1.8e+2).*(q0.*q2.*2.0+q1.*q3.*2.0)+cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2).*(q0.^2.*2.0+q3.^2.*2.0-1.0)+cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2).*(q0.*q1.*2.0-q2.*q3.*2.0))-9.81e+2./1.0e+2;0.0;0.0;0.0;0.0;0.0;0.0]; 
            fsym = @(a1,a2,a3,ba1,ba2,ba3,bw1,bw2,bw3,ka1,ka2,ka3,kw1,kw2,kw3,p1,p2,p3,q0,q1,q2,q3,t,v1,v2,v3,w1,w2,w3)...
                [sqrt(abs(v1).^2+abs(v2).^2+abs(v3).^2);(v1.*1.8e+2)./(pi.*(p3+6.3568e+6));(v2.*-1.8e+2)./(pi.*cos((p1.*pi)./1.8e+2).*(p3+6.3781e+6));v3;-q1.*(bw1./2.0+(kw1.*w1)./2.0)-q2.*(bw2./2.0+(kw2.*w2)./2.0)-q3.*(bw3./2.0+(kw3.*w3)./2.0);q0.*(bw1./2.0+(kw1.*w1)./2.0)-q3.*(bw2./2.0+(kw2.*w2)./2.0)+q2.*(bw3./2.0+(kw3.*w3)./2.0);q0.*(bw2./2.0+(kw2.*w2)./2.0)+q3.*(bw1./2.0+(kw1.*w1)./2.0)-q1.*(bw3./2.0+(kw3.*w3)./2.0);-q2.*(bw1./2.0+(kw1.*w1)./2.0)+q1.*(bw2./2.0+(kw2.*w2)./2.0)+q0.*(bw3./2.0+(kw3.*w3)./2.0);v2.*(sin((p1.*pi)./1.8e+2).*1.458423e-4-(v2.*tan((p1.*pi)./1.8e+2))./(p3+6.3781e+6))+(ba1+a1.*ka1).*(cos((p1.*pi)./1.8e+2).*(q0.^2.*2.0+q1.^2.*2.0-1.0)+(cos(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2)).*(q0.*q3.*2.0+q1.*q2.*2.0)+(cos(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2)-sin(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)).*(q0.*q2.*2.0-q1.*q3.*2.0))-(ba2+a2.*ka2).*(-(cos(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2)).*(q0.^2.*2.0+q2.^2.*2.0-1.0)+(cos(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2)-sin(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)).*(q0.*q1.*2.0+q2.*q3.*2.0)+cos((p1.*pi)./1.8e+2).*(q0.*q3.*2.0-q1.*q2.*2.0))-(ba3+a3.*ka3).*((cos(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2)-sin(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)).*(q0.^2.*2.0+q3.^2.*2.0-1.0)+(cos(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2)).*(q0.*q1.*2.0-q2.*q3.*2.0)-cos((p1.*pi)./1.8e+2).*(q0.*q2.*2.0+q1.*q3.*2.0))-cos((p1.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*(p3+6.3781e+6).*5.3174941173225e-9-(v1.*v3)./(p3+6.3568e+6);-v1.*(sin((p1.*pi)./1.8e+2).*1.458423e-4-(v2.*tan((p1.*pi)./1.8e+2))./(p3+6.3781e+6))-((sin(t.*7.292115e-5).*sin((p2.*pi)./1.8e+2)-cos(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2)).*(q0.^2.*2.0+q2.^2.*2.0-1.0)-(cos(t.*7.292115e-5).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2)).*(q0.*q1.*2.0+q2.*q3.*2.0)).*(ba2+a2.*ka2)+((cos(t.*7.292115e-5).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2)).*(q0.^2.*2.0+q3.^2.*2.0-1.0)+(sin(t.*7.292115e-5).*sin((p2.*pi)./1.8e+2)-cos(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2)).*(q0.*q1.*2.0-q2.*q3.*2.0)).*(ba3+a3.*ka3)-((cos(t.*7.292115e-5).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2)).*(q0.*q2.*2.0-q1.*q3.*2.0)+(sin(t.*7.292115e-5).*sin((p2.*pi)./1.8e+2)-cos(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2)).*(q0.*q3.*2.0+q1.*q2.*2.0)).*(ba1+a1.*ka1)+v3.*(cos((p1.*pi)./1.8e+2).*1.458423e-4-v2./(p3+6.3781e+6));cos((p1.*pi)./1.8e+2).^2.*(p3+6.3781e+6).*5.3174941173225e-9+v1.^2./(p3+6.3568e+6)-(ba1+a1.*ka1).*((cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2)).*(q0.*q3.*2.0+q1.*q2.*2.0)+(cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2)-sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)).*(q0.*q2.*2.0-q1.*q3.*2.0)-sin((p1.*pi)./1.8e+2).*(q0.^2.*2.0+q1.^2.*2.0-1.0))-(ba2+a2.*ka2).*((cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2)).*(q0.^2.*2.0+q2.^2.*2.0-1.0)-(cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2)-sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)).*(q0.*q1.*2.0+q2.*q3.*2.0)+sin((p1.*pi)./1.8e+2).*(q0.*q3.*2.0-q1.*q2.*2.0))+(ba3+a3.*ka3).*((cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2)-sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)).*(q0.^2.*2.0+q3.^2.*2.0-1.0)+(cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2)).*(q0.*q1.*2.0-q2.*q3.*2.0)+sin((p1.*pi)./1.8e+2).*(q0.*q2.*2.0+q1.*q3.*2.0))-v2.*(cos((p1.*pi)./1.8e+2).*1.458423e-4-v2./(p3+6.3781e+6))-9.81e+2./1.0e+2;0.0;0.0;0.0;0.0;0.0;0.0];  
            f_sns = @(t,x,u,prm) x + dT*fsym(u(1),u(2),u(3),x(12),x(13),x(14),x(15),x(16),x(17),...
                prm(1),prm(2),prm(3),prm(4),prm(5),prm(6),x(2),x(3),x(4),x(5),x(6),x(7),x(8),...
                t,x(9),x(10),x(11),u(4),u(5),u(6)); 

            % o <--x(1) | p <--x(2:4) | q <--x(5:8) | v <--x(9:11) | bs <--x(12:17) [+] imu_a <--u(1:3) | imu_w <--u(4:6)  
            f = @(x) [f_s(x(1),x(9:11));f_p(x(2:4),x(9:11));zeros(7,1);x(12:17,1)]; 
            g = @(t,x,u,prms) [zeros(4,1);f_q(x(5:8),x(12:17),u(4:6),prms);f_v(t,x(2:4),x(5:8),x(9:11),x(12:17),u(1:3),prms);zeros(6,1)]; 
            h = @(x) C*x; h_ext = @(x) C_ext*x; 
            f_guess = @(x) [f_s(x(1),x(9:11));f_p(x(2:4),x(9:11));zeros(7,1);x(12:17,1)]; 
            g_guess = @(t,x,u,prms) [zeros(4,1);f_q(x(5:8),x(12:17),u(4:6),prms);f_v(t,x(2:4),x(5:8),x(9:11),x(12:17),u(1:3),prms);zeros(6,1)]; 
            h_guess = @(x) C*x; h_ext_guess = @(x) C_ext*x; 
        end 
        function [f,g,h,h_ext,... % get_full_dynamics_manifold_unknown_sampling_odovelmag 
                f_guess,g_guess,h_guess,h_ext_guess,A,B,C,C_ext,... 
                n_omega_ie,n_omega_en,Sx,Qx,C_nb,gl,G_func,f_s,f_p,q_gen,f_q,f_v,f_sns] ...
                = get_full_dynamics_manifold_unknown_sampling_odovelmag(obj) 
            % dT = obj.downsampling/obj.sampling_frequency; 
            % 
            Af = @(a1,a2,a3,ba1,ba2,ba3,bw1,bw2,bw3,ka1,ka2,ka3,kw1,kw2,kw3,p1,p2,p3,q0,q1,q2,q3,t,v1,v2,v3,w1,w2,w3)reshape([0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,(v2.*sin((p1.*pi)./1.8e+2))./((sin((p1.*pi)./1.8e+2).^2-1.0).*(p3+6.3781e+6)),0.0,0.0,0.0,0.0,0.0,v2.*(pi.*cos((p1.*pi)./1.8e+2).*8.10235e-7-(v2.*pi.*(tan((p1.*pi)./1.8e+2).^2+1.0))./(p3.*1.8e+2+1.148058e+9))+(ba1+a1.*ka1).*(pi.*sin((p1.*pi)./1.8e+2).*(q0.^2.*2.0+q1.^2.*2.0-1.0).*(-1.0./1.8e+2)+(pi.*cos((p1.*pi)./1.8e+2).*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q2.*2.0-q1.*q3.*2.0))./1.8e+2+(pi.*cos((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q3.*2.0+q1.*q2.*2.0))./1.8e+2)+(ba2+a2.*ka2).*((pi.*sin((p1.*pi)./1.8e+2).*(q0.*q3.*2.0-q1.*q2.*2.0))./1.8e+2+(pi.*cos((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.^2.*2.0+q2.^2.*2.0-1.0))./1.8e+2-(pi.*cos((p1.*pi)./1.8e+2).*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q1.*2.0+q2.*q3.*2.0))./1.8e+2)-(ba3+a3.*ka3).*((pi.*sin((p1.*pi)./1.8e+2).*(q0.*q2.*2.0+q1.*q3.*2.0))./1.8e+2+(pi.*cos((p1.*pi)./1.8e+2).*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.^2.*2.0+q3.^2.*2.0-1.0))./1.8e+2+(pi.*cos((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q1.*2.0-q2.*q3.*2.0))./1.8e+2)-pi.*cos((p1.*pi)./1.8e+2).^2.*(p3+6.3781e+6).*2.9541633985125e-11+pi.*sin((p1.*pi)./1.8e+2).^2.*(p3+6.3781e+6).*2.9541633985125e-11,-v1.*(pi.*cos((p1.*pi)./1.8e+2).*8.10235e-7-(v2.*pi.*(tan((p1.*pi)./1.8e+2).^2+1.0))./(p3.*1.8e+2+1.148058e+9))-v3.*pi.*sin((p1.*pi)./1.8e+2).*8.10235e-7,(ba1+a1.*ka1).*((pi.*cos((p1.*pi)./1.8e+2).*(q0.^2.*2.0+q1.^2.*2.0-1.0))./1.8e+2+(pi.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*(q0.*q2.*2.0-q1.*q3.*2.0))./1.8e+2+(pi.*sin((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q3.*2.0+q1.*q2.*2.0))./1.8e+2)-(ba2+a2.*ka2).*((pi.*cos((p1.*pi)./1.8e+2).*(q0.*q3.*2.0-q1.*q2.*2.0))./1.8e+2-(pi.*sin((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.^2.*2.0+q2.^2.*2.0-1.0))./1.8e+2+(pi.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*(q0.*q1.*2.0+q2.*q3.*2.0))./1.8e+2)-(ba3+a3.*ka3).*(pi.*cos((p1.*pi)./1.8e+2).*(q0.*q2.*2.0+q1.*q3.*2.0).*(-1.0./1.8e+2)+(pi.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*(q0.^2.*2.0+q3.^2.*2.0-1.0))./1.8e+2+(pi.*sin((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q1.*2.0-q2.*q3.*2.0))./1.8e+2)+v2.*pi.*sin((p1.*pi)./1.8e+2).*8.10235e-7-pi.*cos((p1.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*(p3+6.3781e+6).*5.908326797025e-11,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,((pi.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*(q0.*q3.*2.0+q1.*q2.*2.0))./1.8e+2-(pi.*sin((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q2.*2.0-q1.*q3.*2.0))./1.8e+2).*(ba1+a1.*ka1)+((pi.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*(q0.^2.*2.0+q2.^2.*2.0-1.0))./1.8e+2+(pi.*sin((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q1.*2.0+q2.*q3.*2.0))./1.8e+2).*(ba2+a2.*ka2)+((pi.*sin((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.^2.*2.0+q3.^2.*2.0-1.0))./1.8e+2-(pi.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*(q0.*q1.*2.0-q2.*q3.*2.0))./1.8e+2).*(ba3+a3.*ka3),-((pi.*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.^2.*2.0+q2.^2.*2.0-1.0))./1.8e+2-(pi.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q1.*2.0+q2.*q3.*2.0))./1.8e+2).*(ba2+a2.*ka2)+((pi.*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q1.*2.0-q2.*q3.*2.0))./1.8e+2+(pi.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.^2.*2.0+q3.^2.*2.0-1.0))./1.8e+2).*(ba3+a3.*ka3)-((pi.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q2.*2.0-q1.*q3.*2.0))./1.8e+2+(pi.*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q3.*2.0+q1.*q2.*2.0))./1.8e+2).*(ba1+a1.*ka1),-((pi.*cos((p1.*pi)./1.8e+2).*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.^2.*2.0+q2.^2.*2.0-1.0))./1.8e+2+(pi.*cos((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q1.*2.0+q2.*q3.*2.0))./1.8e+2).*(ba2+a2.*ka2)-((pi.*cos((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.^2.*2.0+q3.^2.*2.0-1.0))./1.8e+2-(pi.*cos((p1.*pi)./1.8e+2).*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q1.*2.0-q2.*q3.*2.0))./1.8e+2).*(ba3+a3.*ka3)-((pi.*cos((p1.*pi)./1.8e+2).*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q3.*2.0+q1.*q2.*2.0))./1.8e+2-(pi.*cos((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q2.*2.0-q1.*q3.*2.0))./1.8e+2).*(ba1+a1.*ka1),0.0,0.0,0.0,0.0,0.0,0.0,0.0,(v1.*1.0./(p3+6.3568e+6).^2.*-1.8e+2)./pi,(v2.*1.0./(p3+6.3781e+6).^2.*1.8e+2)./(pi.*cos((p1.*pi)./1.8e+2)),0.0,0.0,0.0,0.0,0.0,sin((p1.*pi)./9.0e+1).*(-2.65874705866125e-9)+v1.*v3.*1.0./(p3+6.3568e+6).^2+v2.^2.*tan((p1.*pi)./1.8e+2).*1.0./(p3+6.3781e+6).^2,v2.*(v3-v1.*tan((p1.*pi)./1.8e+2)).*1.0./(p3+6.3781e+6).^2,-v1.^2.*1.0./(p3+6.3568e+6).^2-v2.^2.*1.0./(p3+6.3781e+6).^2+cos((p1.*pi)./1.8e+2).^2.*5.3174941173225e-9,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,bw1./2.0+(kw1.*w1)./2.0,bw2./2.0+(kw2.*w2)./2.0,bw3./2.0+(kw3.*w3)./2.0,(ba1+a1.*ka1).*(q2.*(cos(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2)-sin(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)).*2.0+q3.*(cos(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2)).*2.0+q0.*cos((p1.*pi)./1.8e+2).*4.0)-(ba2+a2.*ka2).*(q0.*(cos(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2)).*-4.0+q1.*(cos(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2)-sin(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)).*2.0+q3.*cos((p1.*pi)./1.8e+2).*2.0)-(ba3+a3.*ka3).*(q0.*(cos(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2)-sin(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)).*4.0+q1.*(cos(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2)).*2.0-q2.*cos((p1.*pi)./1.8e+2).*2.0),(q3.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*2.0-q2.*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*2.0).*(ba1+a1.*ka1)+(q0.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*4.0+q1.*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*2.0).*(ba2+a2.*ka2)-(q1.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*2.0-q0.*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*4.0).*(ba3+a3.*ka3),-(ba1+a1.*ka1).*(q2.*(cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2)-sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)).*2.0+q3.*(cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2)).*2.0-q0.*sin((p1.*pi)./1.8e+2).*4.0)-(ba2+a2.*ka2).*(q0.*(cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2)).*4.0-q1.*(cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2)-sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)).*2.0+q3.*sin((p1.*pi)./1.8e+2).*2.0)+(ba3+a3.*ka3).*(q0.*(cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2)-sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)).*4.0+q1.*(cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2)).*2.0+q2.*sin((p1.*pi)./1.8e+2).*2.0),0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,bw1.*(-1.0./2.0)-(kw1.*w1)./2.0,0.0,bw3.*(-1.0./2.0)-(kw3.*w3)./2.0,bw2./2.0+(kw2.*w2)./2.0,-(ba2+a2.*ka2).*(q0.*(cos(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2)-sin(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)).*2.0-q2.*cos((p1.*pi)./1.8e+2).*2.0)-(ba3+a3.*ka3).*(q0.*(cos(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2)).*2.0-q3.*cos((p1.*pi)./1.8e+2).*2.0)+(ba1+a1.*ka1).*(q2.*(cos(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2)).*2.0-q3.*(cos(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2)-sin(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)).*2.0+q1.*cos((p1.*pi)./1.8e+2).*4.0),(q2.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*2.0+q3.*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*2.0).*(ba1+a1.*ka1)-q0.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(ba3+a3.*ka3).*2.0+q0.*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(ba2+a2.*ka2).*2.0,(ba2+a2.*ka2).*(q0.*(cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2)-sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)).*2.0+q2.*sin((p1.*pi)./1.8e+2).*2.0)+(ba3+a3.*ka3).*(q0.*(cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2)).*2.0+q3.*sin((p1.*pi)./1.8e+2).*2.0)+(ba1+a1.*ka1).*(q2.*(cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2)).*-2.0+q3.*(cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2)-sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)).*2.0+q1.*sin((p1.*pi)./1.8e+2).*4.0),0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,bw2.*(-1.0./2.0)-(kw2.*w2)./2.0,bw3./2.0+(kw3.*w3)./2.0,0.0,bw1.*(-1.0./2.0)-(kw1.*w1)./2.0,(ba2+a2.*ka2).*(q1.*cos((p1.*pi)./1.8e+2).*2.0+q3.*sin(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2).*2.0-q3.*cos(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*2.0+q2.*cos(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2).*4.0+q2.*sin(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*4.0)+(ba3+a3.*ka3).*(q0.*cos((p1.*pi)./1.8e+2).*2.0+q3.*cos(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2).*2.0+q3.*sin(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*2.0)+sin((p1.*pi)./1.8e+2).*(q0.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2)+q1.*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2)).*(ba1.*2.0+a1.*ka1.*2.0),(q1.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*2.0-q0.*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*2.0).*(ba1+a1.*ka1)+(q2.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*4.0+q3.*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*2.0).*(ba2+a2.*ka2)+q3.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(ba3+a3.*ka3).*2.0,-(ba2+a2.*ka2).*(q1.*sin((p1.*pi)./1.8e+2).*-2.0-q3.*cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2).*2.0+q2.*cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2).*4.0+q2.*sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2).*4.0+q3.*sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2).*2.0)-(ba3+a3.*ka3).*(q0.*sin((p1.*pi)./1.8e+2).*-2.0+q3.*cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2).*2.0+q3.*sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2).*2.0)-cos((p1.*pi)./1.8e+2).*(q0.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2)+q1.*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2)).*(ba1.*2.0+a1.*ka1.*2.0),0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,bw3.*(-1.0./2.0)-(kw3.*w3)./2.0,bw2.*(-1.0./2.0)-(kw2.*w2)./2.0,bw1./2.0+(kw1.*w1)./2.0,0.0,(ba3+a3.*ka3).*(q1.*cos((p1.*pi)./1.8e+2).*2.0+q3.*sin(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2).*4.0-q3.*cos(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*4.0+q2.*cos(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2).*2.0+q2.*sin(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*2.0)-(ba2+a2.*ka2).*(q0.*cos((p1.*pi)./1.8e+2).*2.0-q2.*sin(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2).*2.0+q2.*cos(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*2.0)-sin((p1.*pi)./1.8e+2).*(q1.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2)-q0.*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2)).*(ba1.*2.0+a1.*ka1.*2.0),(q0.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*2.0+q1.*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*2.0).*(ba1+a1.*ka1)+(q2.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*2.0+q3.*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*4.0).*(ba3+a3.*ka3)+q2.*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(ba2+a2.*ka2).*2.0,-(ba3+a3.*ka3).*(q1.*sin((p1.*pi)./1.8e+2).*-2.0-q3.*cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2).*4.0+q2.*cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2).*2.0+q2.*sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2).*2.0+q3.*sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2).*4.0)-(ba2+a2.*ka2).*(q0.*sin((p1.*pi)./1.8e+2).*2.0-q2.*cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2).*2.0+q2.*sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2).*2.0)+cos((p1.*pi)./1.8e+2).*(q1.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2)-q0.*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2)).*(ba1.*2.0+a1.*ka1.*2.0),0.0,0.0,0.0,0.0,0.0,0.0,v1.*1.0./sqrt(v1.^2+v2.^2+v3.^2),1.8e+2./(pi.*(p3+6.3568e+6)),0.0,0.0,0.0,0.0,0.0,0.0,-v3./(p3+6.3568e+6),sin((p1.*pi)./1.8e+2).*(-1.458423e-4)+(v2.*tan((p1.*pi)./1.8e+2))./(p3+6.3781e+6),(v1.*2.0)./(p3+6.3568e+6),0.0,0.0,0.0,0.0,0.0,0.0,v2.*1.0./sqrt(v1.^2+v2.^2+v3.^2),0.0,-1.8e+2./(pi.*cos((p1.*pi)./1.8e+2).*(p3+6.3781e+6)),0.0,0.0,0.0,0.0,0.0,sin((p1.*pi)./1.8e+2).*1.458423e-4-(v2.*tan((p1.*pi)./1.8e+2).*2.0)./(p3+6.3781e+6),-(v3-v1.*tan((p1.*pi)./1.8e+2))./(p3+6.3781e+6),cos((p1.*pi)./1.8e+2).*(-1.458423e-4)+(v2.*2.0)./(p3+6.3781e+6),0.0,0.0,0.0,0.0,0.0,0.0,v3.*1.0./sqrt(v1.^2+v2.^2+v3.^2),0.0,0.0,1.0,0.0,0.0,0.0,0.0,-v1./(p3+6.3568e+6),cos((p1.*pi)./1.8e+2).*1.458423e-4-v2./(p3+6.3781e+6),0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,cos((p1.*pi)./1.8e+2).*(q0.^2.*2.0+q1.^2.*2.0-1.0)+cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*(q0.*q2.*2.0-q1.*q3.*2.0)+sin((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q3.*2.0+q1.*q2.*2.0),cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q3.*2.0+q1.*q2.*2.0)-sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q2.*2.0-q1.*q3.*2.0),sin((p1.*pi)./1.8e+2).*(q0.^2.*2.0+q1.^2.*2.0-1.0)-cos((p1.*pi)./1.8e+2).*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q2.*2.0-q1.*q3.*2.0)-cos((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q3.*2.0+q1.*q2.*2.0),0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,-cos((p1.*pi)./1.8e+2).*(q0.*q3.*2.0-q1.*q2.*2.0)+sin((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.^2.*2.0+q2.^2.*2.0-1.0)-cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*(q0.*q1.*2.0+q2.*q3.*2.0),cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.^2.*2.0+q2.^2.*2.0-1.0)+sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q1.*2.0+q2.*q3.*2.0),-sin((p1.*pi)./1.8e+2).*(q0.*q3.*2.0-q1.*q2.*2.0)-cos((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.^2.*2.0+q2.^2.*2.0-1.0)+cos((p1.*pi)./1.8e+2).*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q1.*2.0+q2.*q3.*2.0),0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,cos((p1.*pi)./1.8e+2).*(q0.*q2.*2.0+q1.*q3.*2.0)-cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*(q0.^2.*2.0+q3.^2.*2.0-1.0)-sin((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q1.*2.0-q2.*q3.*2.0),sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.^2.*2.0+q3.^2.*2.0-1.0)-cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q1.*2.0-q2.*q3.*2.0),sin((p1.*pi)./1.8e+2).*(q0.*q2.*2.0+q1.*q3.*2.0)+cos((p1.*pi)./1.8e+2).*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.^2.*2.0+q3.^2.*2.0-1.0)+cos((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q1.*2.0-q2.*q3.*2.0),0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,q1.*(-1.0./2.0),q0./2.0,q3./2.0,q2.*(-1.0./2.0),0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,q2.*(-1.0./2.0),q3.*(-1.0./2.0),q0./2.0,q1./2.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,q3.*(-1.0./2.0),q2./2.0,q1.*(-1.0./2.0),q0./2.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0],[17,17]); 
            A = @(t,x,u,prms) eye(17) + prms(7)*Af(u(1),u(2),u(3),x(12),x(13),x(14),x(15),x(16),x(17),...
                prms(1),prms(2),prms(3),prms(4),prms(5),prms(6),x(2),x(3),x(4),x(5),x(6),x(7),x(8),...
                t,x(9),x(10),x(11),u(4),u(5),u(6)); 
            Bf = @(ka1,ka2,ka3,kw1,kw2,kw3,p1,p2,q0,q1,q2,q3,t)reshape([0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,ka1.*(cos((p1.*pi)./1.8e+2).*(q0.^2.*2.0+q1.^2.*2.0-1.0)+cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*(q0.*q2.*2.0-q1.*q3.*2.0)+sin((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q3.*2.0+q1.*q2.*2.0)),ka1.*(cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q3.*2.0+q1.*q2.*2.0)-sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q2.*2.0-q1.*q3.*2.0)),-ka1.*(-sin((p1.*pi)./1.8e+2).*(q0.^2.*2.0+q1.^2.*2.0-1.0)+cos((p1.*pi)./1.8e+2).*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q2.*2.0-q1.*q3.*2.0)+cos((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q3.*2.0+q1.*q2.*2.0)),0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,-ka2.*(cos((p1.*pi)./1.8e+2).*(q0.*q3.*2.0-q1.*q2.*2.0)-sin((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.^2.*2.0+q2.^2.*2.0-1.0)+cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*(q0.*q1.*2.0+q2.*q3.*2.0)),ka2.*(cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.^2.*2.0+q2.^2.*2.0-1.0)+sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q1.*2.0+q2.*q3.*2.0)),-ka2.*(sin((p1.*pi)./1.8e+2).*(q0.*q3.*2.0-q1.*q2.*2.0)+cos((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.^2.*2.0+q2.^2.*2.0-1.0)-cos((p1.*pi)./1.8e+2).*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q1.*2.0+q2.*q3.*2.0)),0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,-ka3.*(-cos((p1.*pi)./1.8e+2).*(q0.*q2.*2.0+q1.*q3.*2.0)+cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*(q0.^2.*2.0+q3.^2.*2.0-1.0)+sin((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q1.*2.0-q2.*q3.*2.0)),ka3.*(sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.^2.*2.0+q3.^2.*2.0-1.0)-cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q1.*2.0-q2.*q3.*2.0)),ka3.*(sin((p1.*pi)./1.8e+2).*(q0.*q2.*2.0+q1.*q3.*2.0)+cos((p1.*pi)./1.8e+2).*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.^2.*2.0+q3.^2.*2.0-1.0)+cos((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q1.*2.0-q2.*q3.*2.0)),0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,kw1.*q1.*(-1.0./2.0),(kw1.*q0)./2.0,(kw1.*q3)./2.0,kw1.*q2.*(-1.0./2.0),0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,kw2.*q2.*(-1.0./2.0),kw2.*q3.*(-1.0./2.0),(kw2.*q0)./2.0,(kw2.*q1)./2.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,kw3.*q3.*(-1.0./2.0),(kw3.*q2)./2.0,kw3.*q1.*(-1.0./2.0),(kw3.*q0)./2.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0],[17,6]); 
            B = @(t,x,u,prms) Bf(prms(1),prms(2),prms(3),prms(4),prms(5),prms(6),x(2),x(3),x(5),x(6),x(7),x(8),t); 
            H1 = [1/obj.odo_gain_guess,zeros(1,10),zeros(1,6)]; 
            H2 = [zeros(3,1),eye(3),zeros(3,4),zeros(3),zeros(3,6)]; 
            C = [H1; 0*H2]; 
            C_ext = [H1; H2]; 

            % Init 
            n_omega_ie = @(p) obj.rotn_factr*[obj.rot_rate_of_earth*cosd(p(1));0;obj.rot_rate_of_earth*sind(p(1))]; 
            n_omega_en = @(p,v) obj.manifld_factr*[-v(2)/((obj.east_radius_of_earth+p(3)));v(1)/(obj.north_radius_of_earth+p(3));-v(2)*tand(p(1))/(obj.east_radius_of_earth+p(3))]; 
            % n_omega_en = @(p,v) [-v(2)/((obj.east_radius_of_earth+p(3))*cosd(p(1)));-v(1)/(obj.north_radius_of_earth+p(3));0]; 
            Sx = @(w) [0,-w(3),w(2);w(3),0,-w(1);-w(2),w(1),0]; 
            Qx = @(w) 0.5*[0,-w(1),-w(2),-w(3);w(1),0,w(3),-w(2);w(2),-w(3),0,w(1);w(3),w(2),-w(1),0]; 
%             C_nb = @(t,p,q,v) quat2rotm(eul2quat([0,-p(1),-p(2)]*pi/180))'...
%                 *eul2rotm(-flip(omega_ie(p)')*t)*quat2rotm(q'); 
%             C_nb = @(t,p,q,v) rotx(-p(2))*axang2rotm([[0,1,0]*rotx(p(2))',-p(1)*pi/180])...
%                 *rotx(-t*obj.rot_rate_of_earth*180/pi)*quat2rotm(q'); % eul2rotm(flip(omega_ie(p)')*t)
            C_nb = @(t,p,q,v) roty(-p(1))*rotx(-p(2))...
                *rotx(-t*obj.rot_rate_of_earth*180/pi)*quat2rotm(q'); % eul2rotm(flip(omega_ie(p)')*t)
            % rotx(t/2) --> its a triangle not a square while integrating 
            gl = @(p) -Sx(n_omega_ie(p))*Sx(n_omega_ie(p))*[0;0;(obj.east_radius_of_earth+p(3))]+[0;0;-obj.earth_gravity]; 

            % dynamics and fix 
%             Fdyn = @(t,p,q,v,a,w) [...
%                 180*v(1)/(pi*(obj.north_radius_of_earth+p(3)));-180*v(2)/(pi*(obj.east_radius_of_earth+p(3))*cosd(p(1)));v(3);...
%                 (expm(Qx(w)*Ts)-eye(4))*q/Ts;... % Qx(w)*q;... % 
%                 (C_nb(t,p,q,v)*a-Sx(2*n_omega_ie(p)+n_omega_en(p,v))*v+gl(p))]; 
% %             imu_fix = @(t,p,q,v,a,w) [w-[v(2)/((obj.east_radius_of_earth+p(3))*cosd(p(1)));v(1)/(obj.north_radius_of_earth+p(3));0];...
% %                 a+C_nb(t,p,q,v)'*(Sx(n_omega_en(p,v))*v-gl(p))]; % w and a 
%             imu_fix = @(t,p,q,v,a,w) [w+C_nb(t,p,q,v)'*(n_omega_en(p,v) + n_omega_ie(p));...
%                 a+C_nb(t,p,q,v)'*(Sx(2*n_omega_ie(p)+n_omega_en(p,v))*v-gl(p))]; % w and a 
% %             imu_fix = @(t,p,q,v,a,w) [w+C_nb(t,p,q,v)'*(n_omega_ie(p)+n_omega_en(p,v));...
% %                 a+C_nb(t,p,q,v)'*(Sx(n_omega_en(p,v))*v-gl(p))]; % w and a 
            G_func = @(p,v) [180*v(1)/(pi*(obj.north_radius_of_earth+p(3)));...
                -180*v(2)/(pi*(obj.east_radius_of_earth+p(3))*cosd(p(1)));v(3)]; 
            f_s = @(s,~,dT) s + dT*obj.mean_odo_velocity; 
            f_p = @(p,v,dT) p + dT*G_func(p,obj.mean_odo_velocity*(v/(norm(v)+1e-3))); 
            %f_s = @(s,v,dT) s + dT*norm(v); 
            %f_p = @(p,v,dT) p + dT*G_func(p,v); 
            q_gen = @(q,bs,imu_w,prms) expm(Qx(prms(4:6).*imu_w + bs(4:6))*prms(7))*q; 
            f_q = @(q,bs,imu_w,prms) q_gen(q,bs,imu_w,prms); % [not needed] /norm(q_gen(q,bs,imu_w)); 
            f_v = @(t,p,q,v,bs,imu_a,prms) v + prms(7)*(C_nb(t,p,q,v)*(prms(1:3).*imu_a + bs(1:3))...
                -Sx(2*n_omega_ie(p)+n_omega_en(p,v))*v+gl(p)); 
            % f_sym_tst = @(a1,a2,a3,ba1,ba2,ba3,bw1,bw2,bw3,ka1,ka2,ka3,kw1,kw2,kw3,p1,p2,p3,q0,q1,q2,q3,v1,v2,v3,w1,w2,w3)[sqrt(abs(v1).^2+abs(v2).^2+abs(v3).^2);(v1.*1.8e+2)./(pi.*(p3+6.3568e+6));(v2.*-1.8e+2)./(pi.*cos((p1.*pi)./1.8e+2).*(p3+6.3781e+6));v3;-q1.*(bw1./2.0+(kw1.*w1)./2.0)-q2.*(bw2./2.0+(kw2.*w2)./2.0)-q3.*(bw3./2.0+(kw3.*w3)./2.0);q0.*(bw1./2.0+(kw1.*w1)./2.0)-q3.*(bw2./2.0+(kw2.*w2)./2.0)+q2.*(bw3./2.0+(kw3.*w3)./2.0);q0.*(bw2./2.0+(kw2.*w2)./2.0)+q3.*(bw1./2.0+(kw1.*w1)./2.0)-q1.*(bw3./2.0+(kw3.*w3)./2.0);-q2.*(bw1./2.0+(kw1.*w1)./2.0)+q1.*(bw2./2.0+(kw2.*w2)./2.0)+q0.*(bw3./2.0+(kw3.*w3)./2.0);(ba1+a1.*ka1).*(cos((p1.*pi)./1.8e+2).*(q0.^2.*2.0+q1.^2.*2.0-1.0)+cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*(q0.*q2.*2.0-q1.*q3.*2.0)+sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2).*(q0.*q3.*2.0+q1.*q2.*2.0))-(ba2+a2.*ka2).*(cos((p1.*pi)./1.8e+2).*(q0.*q3.*2.0-q1.*q2.*2.0)-sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2).*(q0.^2.*2.0+q2.^2.*2.0-1.0)+cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*(q0.*q1.*2.0+q2.*q3.*2.0))-(ba3+a3.*ka3).*(-cos((p1.*pi)./1.8e+2).*(q0.*q2.*2.0+q1.*q3.*2.0)+cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*(q0.^2.*2.0+q3.^2.*2.0-1.0)+sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2).*(q0.*q1.*2.0-q2.*q3.*2.0));(cos((p2.*pi)./1.8e+2).*(q0.^2.*2.0+q2.^2.*2.0-1.0)+sin((p2.*pi)./1.8e+2).*(q0.*q1.*2.0+q2.*q3.*2.0)).*(ba2+a2.*ka2)+(sin((p2.*pi)./1.8e+2).*(q0.^2.*2.0+q3.^2.*2.0-1.0)-cos((p2.*pi)./1.8e+2).*(q0.*q1.*2.0-q2.*q3.*2.0)).*(ba3+a3.*ka3)+(ba1+a1.*ka1).*(cos((p2.*pi)./1.8e+2).*(q0.*q3.*2.0+q1.*q2.*2.0)-sin((p2.*pi)./1.8e+2).*(q0.*q2.*2.0-q1.*q3.*2.0));-(ba1+a1.*ka1).*(-sin((p1.*pi)./1.8e+2).*(q0.^2.*2.0+q1.^2.*2.0-1.0)+cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2).*(q0.*q2.*2.0-q1.*q3.*2.0)+cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2).*(q0.*q3.*2.0+q1.*q2.*2.0))-(ba2+a2.*ka2).*(sin((p1.*pi)./1.8e+2).*(q0.*q3.*2.0-q1.*q2.*2.0)+cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2).*(q0.^2.*2.0+q2.^2.*2.0-1.0)-cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2).*(q0.*q1.*2.0+q2.*q3.*2.0))+(ba3+a3.*ka3).*(sin((p1.*pi)./1.8e+2).*(q0.*q2.*2.0+q1.*q3.*2.0)+cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2).*(q0.^2.*2.0+q3.^2.*2.0-1.0)+cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2).*(q0.*q1.*2.0-q2.*q3.*2.0))-9.81e+2./1.0e+2;0.0;0.0;0.0;0.0;0.0;0.0]; 
            fsym = @(a1,a2,a3,ba1,ba2,ba3,bw1,bw2,bw3,ka1,ka2,ka3,kw1,kw2,kw3,p1,p2,p3,q0,q1,q2,q3,t,v1,v2,v3,w1,w2,w3)...
                [sqrt(abs(v1).^2+abs(v2).^2+abs(v3).^2);(v1.*1.8e+2)./(pi.*(p3+6.3568e+6));(v2.*-1.8e+2)./(pi.*cos((p1.*pi)./1.8e+2).*(p3+6.3781e+6));v3;-q1.*(bw1./2.0+(kw1.*w1)./2.0)-q2.*(bw2./2.0+(kw2.*w2)./2.0)-q3.*(bw3./2.0+(kw3.*w3)./2.0);q0.*(bw1./2.0+(kw1.*w1)./2.0)-q3.*(bw2./2.0+(kw2.*w2)./2.0)+q2.*(bw3./2.0+(kw3.*w3)./2.0);q0.*(bw2./2.0+(kw2.*w2)./2.0)+q3.*(bw1./2.0+(kw1.*w1)./2.0)-q1.*(bw3./2.0+(kw3.*w3)./2.0);-q2.*(bw1./2.0+(kw1.*w1)./2.0)+q1.*(bw2./2.0+(kw2.*w2)./2.0)+q0.*(bw3./2.0+(kw3.*w3)./2.0);v2.*(sin((p1.*pi)./1.8e+2).*1.458423e-4-(v2.*tan((p1.*pi)./1.8e+2))./(p3+6.3781e+6))+(ba1+a1.*ka1).*(cos((p1.*pi)./1.8e+2).*(q0.^2.*2.0+q1.^2.*2.0-1.0)+(cos(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2)).*(q0.*q3.*2.0+q1.*q2.*2.0)+(cos(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2)-sin(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)).*(q0.*q2.*2.0-q1.*q3.*2.0))-(ba2+a2.*ka2).*(-(cos(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2)).*(q0.^2.*2.0+q2.^2.*2.0-1.0)+(cos(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2)-sin(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)).*(q0.*q1.*2.0+q2.*q3.*2.0)+cos((p1.*pi)./1.8e+2).*(q0.*q3.*2.0-q1.*q2.*2.0))-(ba3+a3.*ka3).*((cos(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2)-sin(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)).*(q0.^2.*2.0+q3.^2.*2.0-1.0)+(cos(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2)).*(q0.*q1.*2.0-q2.*q3.*2.0)-cos((p1.*pi)./1.8e+2).*(q0.*q2.*2.0+q1.*q3.*2.0))-cos((p1.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*(p3+6.3781e+6).*5.3174941173225e-9-(v1.*v3)./(p3+6.3568e+6);-v1.*(sin((p1.*pi)./1.8e+2).*1.458423e-4-(v2.*tan((p1.*pi)./1.8e+2))./(p3+6.3781e+6))-((sin(t.*7.292115e-5).*sin((p2.*pi)./1.8e+2)-cos(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2)).*(q0.^2.*2.0+q2.^2.*2.0-1.0)-(cos(t.*7.292115e-5).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2)).*(q0.*q1.*2.0+q2.*q3.*2.0)).*(ba2+a2.*ka2)+((cos(t.*7.292115e-5).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2)).*(q0.^2.*2.0+q3.^2.*2.0-1.0)+(sin(t.*7.292115e-5).*sin((p2.*pi)./1.8e+2)-cos(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2)).*(q0.*q1.*2.0-q2.*q3.*2.0)).*(ba3+a3.*ka3)-((cos(t.*7.292115e-5).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2)).*(q0.*q2.*2.0-q1.*q3.*2.0)+(sin(t.*7.292115e-5).*sin((p2.*pi)./1.8e+2)-cos(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2)).*(q0.*q3.*2.0+q1.*q2.*2.0)).*(ba1+a1.*ka1)+v3.*(cos((p1.*pi)./1.8e+2).*1.458423e-4-v2./(p3+6.3781e+6));cos((p1.*pi)./1.8e+2).^2.*(p3+6.3781e+6).*5.3174941173225e-9+v1.^2./(p3+6.3568e+6)-(ba1+a1.*ka1).*((cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2)).*(q0.*q3.*2.0+q1.*q2.*2.0)+(cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2)-sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)).*(q0.*q2.*2.0-q1.*q3.*2.0)-sin((p1.*pi)./1.8e+2).*(q0.^2.*2.0+q1.^2.*2.0-1.0))-(ba2+a2.*ka2).*((cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2)).*(q0.^2.*2.0+q2.^2.*2.0-1.0)-(cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2)-sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)).*(q0.*q1.*2.0+q2.*q3.*2.0)+sin((p1.*pi)./1.8e+2).*(q0.*q3.*2.0-q1.*q2.*2.0))+(ba3+a3.*ka3).*((cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2)-sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)).*(q0.^2.*2.0+q3.^2.*2.0-1.0)+(cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2)).*(q0.*q1.*2.0-q2.*q3.*2.0)+sin((p1.*pi)./1.8e+2).*(q0.*q2.*2.0+q1.*q3.*2.0))-v2.*(cos((p1.*pi)./1.8e+2).*1.458423e-4-v2./(p3+6.3781e+6))-9.81e+2./1.0e+2;0.0;0.0;0.0;0.0;0.0;0.0];  
            f_sns = @(t,x,u,prms) x + prms(7)*fsym(u(1),u(2),u(3),x(12),x(13),x(14),x(15),x(16),x(17),...
                prms(1),prms(2),prms(3),prms(4),prms(5),prms(6),x(2),x(3),x(4),x(5),x(6),x(7),x(8),...
                t,x(9),x(10),x(11),u(4),u(5),u(6)); 

            % o <--x(1) | p <--x(2:4) | q <--x(5:8) | v <--x(9:11) | bs <--x(12:17) [+] imu_a <--u(1:3) | imu_w <--u(4:6)  
            % f = @(x) [f_s(x(1),x(9:11));f_p(x(2:4),x(9:11));zeros(7,1);x(12:17,1)]; 
            f = @(x) [zeros(11,1);x(12:17,1)]; 
            g = @(t,x,u,prms) [f_s(x(1),x(9:11),prms(7));f_p(x(2:4),x(9:11),prms(7));f_q(x(5:8),x(12:17),u(4:6),prms);f_v(t,x(2:4),x(5:8),x(9:11),x(12:17),u(1:3),prms);zeros(6,1)]; 
            h = @(x) C*x; h_ext = @(x) C_ext*x; 
            f_guess = @(x) [f_s(x(1),x(9:11));f_p(x(2:4),x(9:11));zeros(7,1);x(12:17,1)]; 
            g_guess = @(t,x,u,prms) [zeros(4,1);f_q(x(5:8),x(12:17),u(4:6),prms);f_v(t,x(2:4),x(5:8),x(9:11),x(12:17),u(1:3),prms);zeros(6,1)]; 
            h_guess = @(x) C*x; h_ext_guess = @(x) C_ext*x; 
        end 
        function [f,g,h,h_ext,... % get_full_dynamics_manifold_unknown_sampling_odovelmag_scaled 
                f_guess,g_guess,h_guess,h_ext_guess,A,B,C,C_ext,... 
                n_omega_ie,n_omega_en,Sx,Qx,C_nb,gl,G_func,f_s,f_p,q_gen,f_q,f_v,f_sns] ...
                = get_full_dynamics_manifold_unknown_sampling_odovelmag_scaled(obj) 
            % dT = obj.downsampling/obj.sampling_frequency; 
            % 
            Af = @(a1,a2,a3,ba1,ba2,ba3,bw1,bw2,bw3,ka1,ka2,ka3,kw1,kw2,kw3,p1,p2,p3,q0,q1,q2,q3,t,v1,v2,v3,w1,w2,w3)reshape([0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,(v2.*sin((p1.*pi)./1.8e+2))./((sin((p1.*pi)./1.8e+2).^2-1.0).*(p3+6.3781e+6)),0.0,0.0,0.0,0.0,0.0,v2.*(pi.*cos((p1.*pi)./1.8e+2).*8.10235e-7-(v2.*pi.*(tan((p1.*pi)./1.8e+2).^2+1.0))./(p3.*1.8e+2+1.148058e+9))+(ba1+a1.*ka1).*(pi.*sin((p1.*pi)./1.8e+2).*(q0.^2.*2.0+q1.^2.*2.0-1.0).*(-1.0./1.8e+2)+(pi.*cos((p1.*pi)./1.8e+2).*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q2.*2.0-q1.*q3.*2.0))./1.8e+2+(pi.*cos((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q3.*2.0+q1.*q2.*2.0))./1.8e+2)+(ba2+a2.*ka2).*((pi.*sin((p1.*pi)./1.8e+2).*(q0.*q3.*2.0-q1.*q2.*2.0))./1.8e+2+(pi.*cos((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.^2.*2.0+q2.^2.*2.0-1.0))./1.8e+2-(pi.*cos((p1.*pi)./1.8e+2).*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q1.*2.0+q2.*q3.*2.0))./1.8e+2)-(ba3+a3.*ka3).*((pi.*sin((p1.*pi)./1.8e+2).*(q0.*q2.*2.0+q1.*q3.*2.0))./1.8e+2+(pi.*cos((p1.*pi)./1.8e+2).*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.^2.*2.0+q3.^2.*2.0-1.0))./1.8e+2+(pi.*cos((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q1.*2.0-q2.*q3.*2.0))./1.8e+2)-pi.*cos((p1.*pi)./1.8e+2).^2.*(p3+6.3781e+6).*2.9541633985125e-11+pi.*sin((p1.*pi)./1.8e+2).^2.*(p3+6.3781e+6).*2.9541633985125e-11,-v1.*(pi.*cos((p1.*pi)./1.8e+2).*8.10235e-7-(v2.*pi.*(tan((p1.*pi)./1.8e+2).^2+1.0))./(p3.*1.8e+2+1.148058e+9))-v3.*pi.*sin((p1.*pi)./1.8e+2).*8.10235e-7,(ba1+a1.*ka1).*((pi.*cos((p1.*pi)./1.8e+2).*(q0.^2.*2.0+q1.^2.*2.0-1.0))./1.8e+2+(pi.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*(q0.*q2.*2.0-q1.*q3.*2.0))./1.8e+2+(pi.*sin((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q3.*2.0+q1.*q2.*2.0))./1.8e+2)-(ba2+a2.*ka2).*((pi.*cos((p1.*pi)./1.8e+2).*(q0.*q3.*2.0-q1.*q2.*2.0))./1.8e+2-(pi.*sin((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.^2.*2.0+q2.^2.*2.0-1.0))./1.8e+2+(pi.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*(q0.*q1.*2.0+q2.*q3.*2.0))./1.8e+2)-(ba3+a3.*ka3).*(pi.*cos((p1.*pi)./1.8e+2).*(q0.*q2.*2.0+q1.*q3.*2.0).*(-1.0./1.8e+2)+(pi.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*(q0.^2.*2.0+q3.^2.*2.0-1.0))./1.8e+2+(pi.*sin((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q1.*2.0-q2.*q3.*2.0))./1.8e+2)+v2.*pi.*sin((p1.*pi)./1.8e+2).*8.10235e-7-pi.*cos((p1.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*(p3+6.3781e+6).*5.908326797025e-11,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,((pi.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*(q0.*q3.*2.0+q1.*q2.*2.0))./1.8e+2-(pi.*sin((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q2.*2.0-q1.*q3.*2.0))./1.8e+2).*(ba1+a1.*ka1)+((pi.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*(q0.^2.*2.0+q2.^2.*2.0-1.0))./1.8e+2+(pi.*sin((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q1.*2.0+q2.*q3.*2.0))./1.8e+2).*(ba2+a2.*ka2)+((pi.*sin((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.^2.*2.0+q3.^2.*2.0-1.0))./1.8e+2-(pi.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*(q0.*q1.*2.0-q2.*q3.*2.0))./1.8e+2).*(ba3+a3.*ka3),-((pi.*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.^2.*2.0+q2.^2.*2.0-1.0))./1.8e+2-(pi.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q1.*2.0+q2.*q3.*2.0))./1.8e+2).*(ba2+a2.*ka2)+((pi.*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q1.*2.0-q2.*q3.*2.0))./1.8e+2+(pi.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.^2.*2.0+q3.^2.*2.0-1.0))./1.8e+2).*(ba3+a3.*ka3)-((pi.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q2.*2.0-q1.*q3.*2.0))./1.8e+2+(pi.*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q3.*2.0+q1.*q2.*2.0))./1.8e+2).*(ba1+a1.*ka1),-((pi.*cos((p1.*pi)./1.8e+2).*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.^2.*2.0+q2.^2.*2.0-1.0))./1.8e+2+(pi.*cos((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q1.*2.0+q2.*q3.*2.0))./1.8e+2).*(ba2+a2.*ka2)-((pi.*cos((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.^2.*2.0+q3.^2.*2.0-1.0))./1.8e+2-(pi.*cos((p1.*pi)./1.8e+2).*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q1.*2.0-q2.*q3.*2.0))./1.8e+2).*(ba3+a3.*ka3)-((pi.*cos((p1.*pi)./1.8e+2).*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q3.*2.0+q1.*q2.*2.0))./1.8e+2-(pi.*cos((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q2.*2.0-q1.*q3.*2.0))./1.8e+2).*(ba1+a1.*ka1),0.0,0.0,0.0,0.0,0.0,0.0,0.0,(v1.*1.0./(p3+6.3568e+6).^2.*-1.8e+2)./pi,(v2.*1.0./(p3+6.3781e+6).^2.*1.8e+2)./(pi.*cos((p1.*pi)./1.8e+2)),0.0,0.0,0.0,0.0,0.0,sin((p1.*pi)./9.0e+1).*(-2.65874705866125e-9)+v1.*v3.*1.0./(p3+6.3568e+6).^2+v2.^2.*tan((p1.*pi)./1.8e+2).*1.0./(p3+6.3781e+6).^2,v2.*(v3-v1.*tan((p1.*pi)./1.8e+2)).*1.0./(p3+6.3781e+6).^2,-v1.^2.*1.0./(p3+6.3568e+6).^2-v2.^2.*1.0./(p3+6.3781e+6).^2+cos((p1.*pi)./1.8e+2).^2.*5.3174941173225e-9,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,bw1./2.0+(kw1.*w1)./2.0,bw2./2.0+(kw2.*w2)./2.0,bw3./2.0+(kw3.*w3)./2.0,(ba1+a1.*ka1).*(q2.*(cos(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2)-sin(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)).*2.0+q3.*(cos(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2)).*2.0+q0.*cos((p1.*pi)./1.8e+2).*4.0)-(ba2+a2.*ka2).*(q0.*(cos(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2)).*-4.0+q1.*(cos(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2)-sin(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)).*2.0+q3.*cos((p1.*pi)./1.8e+2).*2.0)-(ba3+a3.*ka3).*(q0.*(cos(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2)-sin(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)).*4.0+q1.*(cos(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2)).*2.0-q2.*cos((p1.*pi)./1.8e+2).*2.0),(q3.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*2.0-q2.*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*2.0).*(ba1+a1.*ka1)+(q0.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*4.0+q1.*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*2.0).*(ba2+a2.*ka2)-(q1.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*2.0-q0.*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*4.0).*(ba3+a3.*ka3),-(ba1+a1.*ka1).*(q2.*(cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2)-sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)).*2.0+q3.*(cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2)).*2.0-q0.*sin((p1.*pi)./1.8e+2).*4.0)-(ba2+a2.*ka2).*(q0.*(cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2)).*4.0-q1.*(cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2)-sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)).*2.0+q3.*sin((p1.*pi)./1.8e+2).*2.0)+(ba3+a3.*ka3).*(q0.*(cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2)-sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)).*4.0+q1.*(cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2)).*2.0+q2.*sin((p1.*pi)./1.8e+2).*2.0),0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,bw1.*(-1.0./2.0)-(kw1.*w1)./2.0,0.0,bw3.*(-1.0./2.0)-(kw3.*w3)./2.0,bw2./2.0+(kw2.*w2)./2.0,-(ba2+a2.*ka2).*(q0.*(cos(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2)-sin(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)).*2.0-q2.*cos((p1.*pi)./1.8e+2).*2.0)-(ba3+a3.*ka3).*(q0.*(cos(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2)).*2.0-q3.*cos((p1.*pi)./1.8e+2).*2.0)+(ba1+a1.*ka1).*(q2.*(cos(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2)).*2.0-q3.*(cos(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2)-sin(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)).*2.0+q1.*cos((p1.*pi)./1.8e+2).*4.0),(q2.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*2.0+q3.*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*2.0).*(ba1+a1.*ka1)-q0.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(ba3+a3.*ka3).*2.0+q0.*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(ba2+a2.*ka2).*2.0,(ba2+a2.*ka2).*(q0.*(cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2)-sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)).*2.0+q2.*sin((p1.*pi)./1.8e+2).*2.0)+(ba3+a3.*ka3).*(q0.*(cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2)).*2.0+q3.*sin((p1.*pi)./1.8e+2).*2.0)+(ba1+a1.*ka1).*(q2.*(cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2)).*-2.0+q3.*(cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2)-sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)).*2.0+q1.*sin((p1.*pi)./1.8e+2).*4.0),0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,bw2.*(-1.0./2.0)-(kw2.*w2)./2.0,bw3./2.0+(kw3.*w3)./2.0,0.0,bw1.*(-1.0./2.0)-(kw1.*w1)./2.0,(ba2+a2.*ka2).*(q1.*cos((p1.*pi)./1.8e+2).*2.0+q3.*sin(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2).*2.0-q3.*cos(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*2.0+q2.*cos(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2).*4.0+q2.*sin(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*4.0)+(ba3+a3.*ka3).*(q0.*cos((p1.*pi)./1.8e+2).*2.0+q3.*cos(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2).*2.0+q3.*sin(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*2.0)+sin((p1.*pi)./1.8e+2).*(q0.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2)+q1.*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2)).*(ba1.*2.0+a1.*ka1.*2.0),(q1.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*2.0-q0.*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*2.0).*(ba1+a1.*ka1)+(q2.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*4.0+q3.*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*2.0).*(ba2+a2.*ka2)+q3.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(ba3+a3.*ka3).*2.0,-(ba2+a2.*ka2).*(q1.*sin((p1.*pi)./1.8e+2).*-2.0-q3.*cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2).*2.0+q2.*cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2).*4.0+q2.*sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2).*4.0+q3.*sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2).*2.0)-(ba3+a3.*ka3).*(q0.*sin((p1.*pi)./1.8e+2).*-2.0+q3.*cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2).*2.0+q3.*sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2).*2.0)-cos((p1.*pi)./1.8e+2).*(q0.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2)+q1.*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2)).*(ba1.*2.0+a1.*ka1.*2.0),0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,bw3.*(-1.0./2.0)-(kw3.*w3)./2.0,bw2.*(-1.0./2.0)-(kw2.*w2)./2.0,bw1./2.0+(kw1.*w1)./2.0,0.0,(ba3+a3.*ka3).*(q1.*cos((p1.*pi)./1.8e+2).*2.0+q3.*sin(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2).*4.0-q3.*cos(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*4.0+q2.*cos(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2).*2.0+q2.*sin(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*2.0)-(ba2+a2.*ka2).*(q0.*cos((p1.*pi)./1.8e+2).*2.0-q2.*sin(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2).*2.0+q2.*cos(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*2.0)-sin((p1.*pi)./1.8e+2).*(q1.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2)-q0.*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2)).*(ba1.*2.0+a1.*ka1.*2.0),(q0.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*2.0+q1.*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*2.0).*(ba1+a1.*ka1)+(q2.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*2.0+q3.*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*4.0).*(ba3+a3.*ka3)+q2.*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(ba2+a2.*ka2).*2.0,-(ba3+a3.*ka3).*(q1.*sin((p1.*pi)./1.8e+2).*-2.0-q3.*cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2).*4.0+q2.*cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2).*2.0+q2.*sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2).*2.0+q3.*sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2).*4.0)-(ba2+a2.*ka2).*(q0.*sin((p1.*pi)./1.8e+2).*2.0-q2.*cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2).*2.0+q2.*sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2).*2.0)+cos((p1.*pi)./1.8e+2).*(q1.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2)-q0.*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2)).*(ba1.*2.0+a1.*ka1.*2.0),0.0,0.0,0.0,0.0,0.0,0.0,v1.*1.0./sqrt(v1.^2+v2.^2+v3.^2),1.8e+2./(pi.*(p3+6.3568e+6)),0.0,0.0,0.0,0.0,0.0,0.0,-v3./(p3+6.3568e+6),sin((p1.*pi)./1.8e+2).*(-1.458423e-4)+(v2.*tan((p1.*pi)./1.8e+2))./(p3+6.3781e+6),(v1.*2.0)./(p3+6.3568e+6),0.0,0.0,0.0,0.0,0.0,0.0,v2.*1.0./sqrt(v1.^2+v2.^2+v3.^2),0.0,-1.8e+2./(pi.*cos((p1.*pi)./1.8e+2).*(p3+6.3781e+6)),0.0,0.0,0.0,0.0,0.0,sin((p1.*pi)./1.8e+2).*1.458423e-4-(v2.*tan((p1.*pi)./1.8e+2).*2.0)./(p3+6.3781e+6),-(v3-v1.*tan((p1.*pi)./1.8e+2))./(p3+6.3781e+6),cos((p1.*pi)./1.8e+2).*(-1.458423e-4)+(v2.*2.0)./(p3+6.3781e+6),0.0,0.0,0.0,0.0,0.0,0.0,v3.*1.0./sqrt(v1.^2+v2.^2+v3.^2),0.0,0.0,1.0,0.0,0.0,0.0,0.0,-v1./(p3+6.3568e+6),cos((p1.*pi)./1.8e+2).*1.458423e-4-v2./(p3+6.3781e+6),0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,cos((p1.*pi)./1.8e+2).*(q0.^2.*2.0+q1.^2.*2.0-1.0)+cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*(q0.*q2.*2.0-q1.*q3.*2.0)+sin((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q3.*2.0+q1.*q2.*2.0),cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q3.*2.0+q1.*q2.*2.0)-sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q2.*2.0-q1.*q3.*2.0),sin((p1.*pi)./1.8e+2).*(q0.^2.*2.0+q1.^2.*2.0-1.0)-cos((p1.*pi)./1.8e+2).*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q2.*2.0-q1.*q3.*2.0)-cos((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q3.*2.0+q1.*q2.*2.0),0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,-cos((p1.*pi)./1.8e+2).*(q0.*q3.*2.0-q1.*q2.*2.0)+sin((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.^2.*2.0+q2.^2.*2.0-1.0)-cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*(q0.*q1.*2.0+q2.*q3.*2.0),cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.^2.*2.0+q2.^2.*2.0-1.0)+sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q1.*2.0+q2.*q3.*2.0),-sin((p1.*pi)./1.8e+2).*(q0.*q3.*2.0-q1.*q2.*2.0)-cos((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.^2.*2.0+q2.^2.*2.0-1.0)+cos((p1.*pi)./1.8e+2).*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q1.*2.0+q2.*q3.*2.0),0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,cos((p1.*pi)./1.8e+2).*(q0.*q2.*2.0+q1.*q3.*2.0)-cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*(q0.^2.*2.0+q3.^2.*2.0-1.0)-sin((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q1.*2.0-q2.*q3.*2.0),sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.^2.*2.0+q3.^2.*2.0-1.0)-cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q1.*2.0-q2.*q3.*2.0),sin((p1.*pi)./1.8e+2).*(q0.*q2.*2.0+q1.*q3.*2.0)+cos((p1.*pi)./1.8e+2).*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.^2.*2.0+q3.^2.*2.0-1.0)+cos((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q1.*2.0-q2.*q3.*2.0),0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,q1.*(-1.0./2.0),q0./2.0,q3./2.0,q2.*(-1.0./2.0),0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,q2.*(-1.0./2.0),q3.*(-1.0./2.0),q0./2.0,q1./2.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,q3.*(-1.0./2.0),q2./2.0,q1.*(-1.0./2.0),q0./2.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0],[17,17]); 
            A = @(t,x,u,prms) eye(17) + prms(7)*Af(u(1),u(2),u(3),x(12),x(13),x(14),x(15),x(16),x(17),...
                prms(1),prms(2),prms(3),prms(4),prms(5),prms(6),x(2),x(3),x(4),x(5),x(6),x(7),x(8),...
                t,prms(8)*x(9),prms(8)*x(10),prms(8)*x(11),u(4),u(5),u(6)); 
            Bf = @(ka1,ka2,ka3,kw1,kw2,kw3,p1,p2,q0,q1,q2,q3,t)reshape([0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,ka1.*(cos((p1.*pi)./1.8e+2).*(q0.^2.*2.0+q1.^2.*2.0-1.0)+cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*(q0.*q2.*2.0-q1.*q3.*2.0)+sin((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q3.*2.0+q1.*q2.*2.0)),ka1.*(cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q3.*2.0+q1.*q2.*2.0)-sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q2.*2.0-q1.*q3.*2.0)),-ka1.*(-sin((p1.*pi)./1.8e+2).*(q0.^2.*2.0+q1.^2.*2.0-1.0)+cos((p1.*pi)./1.8e+2).*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q2.*2.0-q1.*q3.*2.0)+cos((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q3.*2.0+q1.*q2.*2.0)),0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,-ka2.*(cos((p1.*pi)./1.8e+2).*(q0.*q3.*2.0-q1.*q2.*2.0)-sin((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.^2.*2.0+q2.^2.*2.0-1.0)+cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*(q0.*q1.*2.0+q2.*q3.*2.0)),ka2.*(cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.^2.*2.0+q2.^2.*2.0-1.0)+sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q1.*2.0+q2.*q3.*2.0)),-ka2.*(sin((p1.*pi)./1.8e+2).*(q0.*q3.*2.0-q1.*q2.*2.0)+cos((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.^2.*2.0+q2.^2.*2.0-1.0)-cos((p1.*pi)./1.8e+2).*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q1.*2.0+q2.*q3.*2.0)),0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,-ka3.*(-cos((p1.*pi)./1.8e+2).*(q0.*q2.*2.0+q1.*q3.*2.0)+cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*(q0.^2.*2.0+q3.^2.*2.0-1.0)+sin((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q1.*2.0-q2.*q3.*2.0)),ka3.*(sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.^2.*2.0+q3.^2.*2.0-1.0)-cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q1.*2.0-q2.*q3.*2.0)),ka3.*(sin((p1.*pi)./1.8e+2).*(q0.*q2.*2.0+q1.*q3.*2.0)+cos((p1.*pi)./1.8e+2).*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.^2.*2.0+q3.^2.*2.0-1.0)+cos((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q1.*2.0-q2.*q3.*2.0)),0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,kw1.*q1.*(-1.0./2.0),(kw1.*q0)./2.0,(kw1.*q3)./2.0,kw1.*q2.*(-1.0./2.0),0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,kw2.*q2.*(-1.0./2.0),kw2.*q3.*(-1.0./2.0),(kw2.*q0)./2.0,(kw2.*q1)./2.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,kw3.*q3.*(-1.0./2.0),(kw3.*q2)./2.0,kw3.*q1.*(-1.0./2.0),(kw3.*q0)./2.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0],[17,6]); 
            B = @(t,x,u,prms) Bf(prms(1),prms(2),prms(3),prms(4),prms(5),prms(6),x(2),x(3),x(5),x(6),x(7),x(8),t); 
            H1 = [1/obj.odo_gain_guess,zeros(1,10),zeros(1,6)]; 
            H2 = [zeros(3,1),eye(3),zeros(3,4),zeros(3),zeros(3,6)]; 
            C = [H1; 0*H2]; 
            C_ext = [H1; H2]; 

            % Init 
            n_omega_ie = @(p) obj.rotn_factr*[obj.rot_rate_of_earth*cosd(p(1));0;obj.rot_rate_of_earth*sind(p(1))]; 
            n_omega_en = @(p,v) obj.manifld_factr*[-v(2)/((obj.east_radius_of_earth+p(3)));v(1)/(obj.north_radius_of_earth+p(3));-v(2)*tand(p(1))/(obj.east_radius_of_earth+p(3))]; 
            % n_omega_en = @(p,v) [-v(2)/((obj.east_radius_of_earth+p(3))*cosd(p(1)));-v(1)/(obj.north_radius_of_earth+p(3));0]; 
            Sx = @(w) [0,-w(3),w(2);w(3),0,-w(1);-w(2),w(1),0]; 
            Qx = @(w) 0.5*[0,-w(1),-w(2),-w(3);w(1),0,w(3),-w(2);w(2),-w(3),0,w(1);w(3),w(2),-w(1),0]; 
%             C_nb = @(t,p,q,v) quat2rotm(eul2quat([0,-p(1),-p(2)]*pi/180))'...
%                 *eul2rotm(-flip(omega_ie(p)')*t)*quat2rotm(q'); 
%             C_nb = @(t,p,q,v) rotx(-p(2))*axang2rotm([[0,1,0]*rotx(p(2))',-p(1)*pi/180])...
%                 *rotx(-t*obj.rot_rate_of_earth*180/pi)*quat2rotm(q'); % eul2rotm(flip(omega_ie(p)')*t)
            C_nb = @(t,p,q,v) roty(-p(1))*rotx(-p(2))...
                *rotx(-t*obj.rot_rate_of_earth*180/pi)*quat2rotm(q'); % eul2rotm(flip(omega_ie(p)')*t)
            % rotx(t/2) --> its a triangle not a square while integrating 
            gl = @(p) -Sx(n_omega_ie(p))*Sx(n_omega_ie(p))*[0;0;(obj.east_radius_of_earth+p(3))]+[0;0;-obj.earth_gravity]; 

            % dynamics and fix 
%             Fdyn = @(t,p,q,v,a,w) [...
%                 180*v(1)/(pi*(obj.north_radius_of_earth+p(3)));-180*v(2)/(pi*(obj.east_radius_of_earth+p(3))*cosd(p(1)));v(3);...
%                 (expm(Qx(w)*Ts)-eye(4))*q/Ts;... % Qx(w)*q;... % 
%                 (C_nb(t,p,q,v)*a-Sx(2*n_omega_ie(p)+n_omega_en(p,v))*v+gl(p))]; 
% %             imu_fix = @(t,p,q,v,a,w) [w-[v(2)/((obj.east_radius_of_earth+p(3))*cosd(p(1)));v(1)/(obj.north_radius_of_earth+p(3));0];...
% %                 a+C_nb(t,p,q,v)'*(Sx(n_omega_en(p,v))*v-gl(p))]; % w and a 
%             imu_fix = @(t,p,q,v,a,w) [w+C_nb(t,p,q,v)'*(n_omega_en(p,v) + n_omega_ie(p));...
%                 a+C_nb(t,p,q,v)'*(Sx(2*n_omega_ie(p)+n_omega_en(p,v))*v-gl(p))]; % w and a 
% %             imu_fix = @(t,p,q,v,a,w) [w+C_nb(t,p,q,v)'*(n_omega_ie(p)+n_omega_en(p,v));...
% %                 a+C_nb(t,p,q,v)'*(Sx(n_omega_en(p,v))*v-gl(p))]; % w and a 
            G_func = @(p,v) [180*v(1)/(pi*(obj.north_radius_of_earth+p(3)));...
                -180*v(2)/(pi*(obj.east_radius_of_earth+p(3))*cosd(p(1)));v(3)]; 
            f_s = @(s,~,dT) s + dT*obj.mean_odo_velocity; 
            f_p = @(p,v,dT) p + dT*G_func(p,obj.mean_odo_velocity*(v/(norm(v)+1e-3))); 
            q_gen = @(q,bs,imu_w,prms) expm(Qx(prms(4:6).*imu_w + bs(4:6))*prms(7))*q; 
            f_q = @(q,bs,imu_w,prms) q_gen(q,bs,imu_w,prms); % [not needed] /norm(q_gen(q,bs,imu_w)); 
            f_v = @(t,p,q,v,bs,imu_a,prms) v + prms(7)*(C_nb(t,p,q,v)*(prms(1:3).*imu_a + bs(1:3))...
                -Sx(2*n_omega_ie(p)+n_omega_en(p,v))*v+gl(p)); 
            % f_sym_tst = @(a1,a2,a3,ba1,ba2,ba3,bw1,bw2,bw3,ka1,ka2,ka3,kw1,kw2,kw3,p1,p2,p3,q0,q1,q2,q3,v1,v2,v3,w1,w2,w3)[sqrt(abs(v1).^2+abs(v2).^2+abs(v3).^2);(v1.*1.8e+2)./(pi.*(p3+6.3568e+6));(v2.*-1.8e+2)./(pi.*cos((p1.*pi)./1.8e+2).*(p3+6.3781e+6));v3;-q1.*(bw1./2.0+(kw1.*w1)./2.0)-q2.*(bw2./2.0+(kw2.*w2)./2.0)-q3.*(bw3./2.0+(kw3.*w3)./2.0);q0.*(bw1./2.0+(kw1.*w1)./2.0)-q3.*(bw2./2.0+(kw2.*w2)./2.0)+q2.*(bw3./2.0+(kw3.*w3)./2.0);q0.*(bw2./2.0+(kw2.*w2)./2.0)+q3.*(bw1./2.0+(kw1.*w1)./2.0)-q1.*(bw3./2.0+(kw3.*w3)./2.0);-q2.*(bw1./2.0+(kw1.*w1)./2.0)+q1.*(bw2./2.0+(kw2.*w2)./2.0)+q0.*(bw3./2.0+(kw3.*w3)./2.0);(ba1+a1.*ka1).*(cos((p1.*pi)./1.8e+2).*(q0.^2.*2.0+q1.^2.*2.0-1.0)+cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*(q0.*q2.*2.0-q1.*q3.*2.0)+sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2).*(q0.*q3.*2.0+q1.*q2.*2.0))-(ba2+a2.*ka2).*(cos((p1.*pi)./1.8e+2).*(q0.*q3.*2.0-q1.*q2.*2.0)-sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2).*(q0.^2.*2.0+q2.^2.*2.0-1.0)+cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*(q0.*q1.*2.0+q2.*q3.*2.0))-(ba3+a3.*ka3).*(-cos((p1.*pi)./1.8e+2).*(q0.*q2.*2.0+q1.*q3.*2.0)+cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*(q0.^2.*2.0+q3.^2.*2.0-1.0)+sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2).*(q0.*q1.*2.0-q2.*q3.*2.0));(cos((p2.*pi)./1.8e+2).*(q0.^2.*2.0+q2.^2.*2.0-1.0)+sin((p2.*pi)./1.8e+2).*(q0.*q1.*2.0+q2.*q3.*2.0)).*(ba2+a2.*ka2)+(sin((p2.*pi)./1.8e+2).*(q0.^2.*2.0+q3.^2.*2.0-1.0)-cos((p2.*pi)./1.8e+2).*(q0.*q1.*2.0-q2.*q3.*2.0)).*(ba3+a3.*ka3)+(ba1+a1.*ka1).*(cos((p2.*pi)./1.8e+2).*(q0.*q3.*2.0+q1.*q2.*2.0)-sin((p2.*pi)./1.8e+2).*(q0.*q2.*2.0-q1.*q3.*2.0));-(ba1+a1.*ka1).*(-sin((p1.*pi)./1.8e+2).*(q0.^2.*2.0+q1.^2.*2.0-1.0)+cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2).*(q0.*q2.*2.0-q1.*q3.*2.0)+cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2).*(q0.*q3.*2.0+q1.*q2.*2.0))-(ba2+a2.*ka2).*(sin((p1.*pi)./1.8e+2).*(q0.*q3.*2.0-q1.*q2.*2.0)+cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2).*(q0.^2.*2.0+q2.^2.*2.0-1.0)-cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2).*(q0.*q1.*2.0+q2.*q3.*2.0))+(ba3+a3.*ka3).*(sin((p1.*pi)./1.8e+2).*(q0.*q2.*2.0+q1.*q3.*2.0)+cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2).*(q0.^2.*2.0+q3.^2.*2.0-1.0)+cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2).*(q0.*q1.*2.0-q2.*q3.*2.0))-9.81e+2./1.0e+2;0.0;0.0;0.0;0.0;0.0;0.0]; 
            fsym = @(a1,a2,a3,ba1,ba2,ba3,bw1,bw2,bw3,ka1,ka2,ka3,kw1,kw2,kw3,p1,p2,p3,q0,q1,q2,q3,t,v1,v2,v3,w1,w2,w3)...
                [sqrt(abs(v1).^2+abs(v2).^2+abs(v3).^2);(v1.*1.8e+2)./(pi.*(p3+6.3568e+6));(v2.*-1.8e+2)./(pi.*cos((p1.*pi)./1.8e+2).*(p3+6.3781e+6));v3;-q1.*(bw1./2.0+(kw1.*w1)./2.0)-q2.*(bw2./2.0+(kw2.*w2)./2.0)-q3.*(bw3./2.0+(kw3.*w3)./2.0);q0.*(bw1./2.0+(kw1.*w1)./2.0)-q3.*(bw2./2.0+(kw2.*w2)./2.0)+q2.*(bw3./2.0+(kw3.*w3)./2.0);q0.*(bw2./2.0+(kw2.*w2)./2.0)+q3.*(bw1./2.0+(kw1.*w1)./2.0)-q1.*(bw3./2.0+(kw3.*w3)./2.0);-q2.*(bw1./2.0+(kw1.*w1)./2.0)+q1.*(bw2./2.0+(kw2.*w2)./2.0)+q0.*(bw3./2.0+(kw3.*w3)./2.0);v2.*(sin((p1.*pi)./1.8e+2).*1.458423e-4-(v2.*tan((p1.*pi)./1.8e+2))./(p3+6.3781e+6))+(ba1+a1.*ka1).*(cos((p1.*pi)./1.8e+2).*(q0.^2.*2.0+q1.^2.*2.0-1.0)+(cos(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2)).*(q0.*q3.*2.0+q1.*q2.*2.0)+(cos(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2)-sin(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)).*(q0.*q2.*2.0-q1.*q3.*2.0))-(ba2+a2.*ka2).*(-(cos(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2)).*(q0.^2.*2.0+q2.^2.*2.0-1.0)+(cos(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2)-sin(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)).*(q0.*q1.*2.0+q2.*q3.*2.0)+cos((p1.*pi)./1.8e+2).*(q0.*q3.*2.0-q1.*q2.*2.0))-(ba3+a3.*ka3).*((cos(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2)-sin(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)).*(q0.^2.*2.0+q3.^2.*2.0-1.0)+(cos(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2)).*(q0.*q1.*2.0-q2.*q3.*2.0)-cos((p1.*pi)./1.8e+2).*(q0.*q2.*2.0+q1.*q3.*2.0))-cos((p1.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*(p3+6.3781e+6).*5.3174941173225e-9-(v1.*v3)./(p3+6.3568e+6);-v1.*(sin((p1.*pi)./1.8e+2).*1.458423e-4-(v2.*tan((p1.*pi)./1.8e+2))./(p3+6.3781e+6))-((sin(t.*7.292115e-5).*sin((p2.*pi)./1.8e+2)-cos(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2)).*(q0.^2.*2.0+q2.^2.*2.0-1.0)-(cos(t.*7.292115e-5).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2)).*(q0.*q1.*2.0+q2.*q3.*2.0)).*(ba2+a2.*ka2)+((cos(t.*7.292115e-5).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2)).*(q0.^2.*2.0+q3.^2.*2.0-1.0)+(sin(t.*7.292115e-5).*sin((p2.*pi)./1.8e+2)-cos(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2)).*(q0.*q1.*2.0-q2.*q3.*2.0)).*(ba3+a3.*ka3)-((cos(t.*7.292115e-5).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2)).*(q0.*q2.*2.0-q1.*q3.*2.0)+(sin(t.*7.292115e-5).*sin((p2.*pi)./1.8e+2)-cos(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2)).*(q0.*q3.*2.0+q1.*q2.*2.0)).*(ba1+a1.*ka1)+v3.*(cos((p1.*pi)./1.8e+2).*1.458423e-4-v2./(p3+6.3781e+6));cos((p1.*pi)./1.8e+2).^2.*(p3+6.3781e+6).*5.3174941173225e-9+v1.^2./(p3+6.3568e+6)-(ba1+a1.*ka1).*((cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2)).*(q0.*q3.*2.0+q1.*q2.*2.0)+(cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2)-sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)).*(q0.*q2.*2.0-q1.*q3.*2.0)-sin((p1.*pi)./1.8e+2).*(q0.^2.*2.0+q1.^2.*2.0-1.0))-(ba2+a2.*ka2).*((cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2)).*(q0.^2.*2.0+q2.^2.*2.0-1.0)-(cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2)-sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)).*(q0.*q1.*2.0+q2.*q3.*2.0)+sin((p1.*pi)./1.8e+2).*(q0.*q3.*2.0-q1.*q2.*2.0))+(ba3+a3.*ka3).*((cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2)-sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)).*(q0.^2.*2.0+q3.^2.*2.0-1.0)+(cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2)).*(q0.*q1.*2.0-q2.*q3.*2.0)+sin((p1.*pi)./1.8e+2).*(q0.*q2.*2.0+q1.*q3.*2.0))-v2.*(cos((p1.*pi)./1.8e+2).*1.458423e-4-v2./(p3+6.3781e+6))-9.81e+2./1.0e+2;0.0;0.0;0.0;0.0;0.0;0.0];  
            f_sns = @(t,x,u,prms) x + prms(7)*fsym(u(1),u(2),u(3),x(12),x(13),x(14),x(15),x(16),x(17),...
                prms(1),prms(2),prms(3),prms(4),prms(5),prms(6),x(2),x(3),x(4),x(5),x(6),x(7),x(8),...
                t,x(9),x(10),x(11),u(4),u(5),u(6)); 

            % o <--x(1) | p <--x(2:4) | q <--x(5:8) | v <--x(9:11) | bs <--x(12:17) [+] imu_a <--u(1:3) | imu_w <--u(4:6)  
            % f = @(x) [f_s(x(1),x(9:11));f_p(x(2:4),x(9:11));zeros(7,1);x(12:17,1)]; 
            f = @(x) [zeros(11,1);x(12:17,1)]; 
            g = @(t,x,u,prms) [f_s(x(1),prms(8)*x(9:11),prms(7));f_p(x(2:4),prms(8)*x(9:11),prms(7));f_q(x(5:8),x(12:17),u(4:6),prms);f_v(t,x(2:4),x(5:8),x(9:11),x(12:17),u(1:3),prms);zeros(6,1)]; 
            h = @(x) C*x; h_ext = @(x) C_ext*x; 
            f_guess = @(x) [zeros(11,1);x(12:17,1)]; 
            g_guess = @(t,x,u,prms) [f_s(x(1),prms(8)*x(9:11),prms(7));f_p(x(2:4),prms(8)*x(9:11),prms(7));f_q(x(5:8),x(12:17),u(4:6),prms);f_v(t,x(2:4),x(5:8),x(9:11),x(12:17),u(1:3),prms);zeros(6,1)]; 
            h_guess = @(x) C*x; h_ext_guess = @(x) C_ext*x; 
        end 
        function [f,g,h,h_ext,... % get_full_dynamics_manifold_unknown_sampling_vel_scaled 
                f_guess,g_guess,h_guess,h_ext_guess,A,B,C,C_ext,... 
                n_omega_ie,n_omega_en,Sx,Qx,C_nb,gl,G_func,f_s,f_p,q_gen,f_q,f_v,f_sns] ...
                = get_full_dynamics_manifold_unknown_sampling_vel_scaled(obj) 
            % dT = obj.downsampling/obj.sampling_frequency; 
            % 
            Af = @(a1,a2,a3,ba1,ba2,ba3,bw1,bw2,bw3,ka1,ka2,ka3,kw1,kw2,kw3,p1,p2,p3,q0,q1,q2,q3,t,v1,v2,v3,w1,w2,w3)reshape([0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,(v2.*sin((p1.*pi)./1.8e+2))./((sin((p1.*pi)./1.8e+2).^2-1.0).*(p3+6.3781e+6)),0.0,0.0,0.0,0.0,0.0,v2.*(pi.*cos((p1.*pi)./1.8e+2).*8.10235e-7-(v2.*pi.*(tan((p1.*pi)./1.8e+2).^2+1.0))./(p3.*1.8e+2+1.148058e+9))+(ba1+a1.*ka1).*(pi.*sin((p1.*pi)./1.8e+2).*(q0.^2.*2.0+q1.^2.*2.0-1.0).*(-1.0./1.8e+2)+(pi.*cos((p1.*pi)./1.8e+2).*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q2.*2.0-q1.*q3.*2.0))./1.8e+2+(pi.*cos((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q3.*2.0+q1.*q2.*2.0))./1.8e+2)+(ba2+a2.*ka2).*((pi.*sin((p1.*pi)./1.8e+2).*(q0.*q3.*2.0-q1.*q2.*2.0))./1.8e+2+(pi.*cos((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.^2.*2.0+q2.^2.*2.0-1.0))./1.8e+2-(pi.*cos((p1.*pi)./1.8e+2).*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q1.*2.0+q2.*q3.*2.0))./1.8e+2)-(ba3+a3.*ka3).*((pi.*sin((p1.*pi)./1.8e+2).*(q0.*q2.*2.0+q1.*q3.*2.0))./1.8e+2+(pi.*cos((p1.*pi)./1.8e+2).*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.^2.*2.0+q3.^2.*2.0-1.0))./1.8e+2+(pi.*cos((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q1.*2.0-q2.*q3.*2.0))./1.8e+2)-pi.*cos((p1.*pi)./1.8e+2).^2.*(p3+6.3781e+6).*2.9541633985125e-11+pi.*sin((p1.*pi)./1.8e+2).^2.*(p3+6.3781e+6).*2.9541633985125e-11,-v1.*(pi.*cos((p1.*pi)./1.8e+2).*8.10235e-7-(v2.*pi.*(tan((p1.*pi)./1.8e+2).^2+1.0))./(p3.*1.8e+2+1.148058e+9))-v3.*pi.*sin((p1.*pi)./1.8e+2).*8.10235e-7,(ba1+a1.*ka1).*((pi.*cos((p1.*pi)./1.8e+2).*(q0.^2.*2.0+q1.^2.*2.0-1.0))./1.8e+2+(pi.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*(q0.*q2.*2.0-q1.*q3.*2.0))./1.8e+2+(pi.*sin((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q3.*2.0+q1.*q2.*2.0))./1.8e+2)-(ba2+a2.*ka2).*((pi.*cos((p1.*pi)./1.8e+2).*(q0.*q3.*2.0-q1.*q2.*2.0))./1.8e+2-(pi.*sin((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.^2.*2.0+q2.^2.*2.0-1.0))./1.8e+2+(pi.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*(q0.*q1.*2.0+q2.*q3.*2.0))./1.8e+2)-(ba3+a3.*ka3).*(pi.*cos((p1.*pi)./1.8e+2).*(q0.*q2.*2.0+q1.*q3.*2.0).*(-1.0./1.8e+2)+(pi.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*(q0.^2.*2.0+q3.^2.*2.0-1.0))./1.8e+2+(pi.*sin((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q1.*2.0-q2.*q3.*2.0))./1.8e+2)+v2.*pi.*sin((p1.*pi)./1.8e+2).*8.10235e-7-pi.*cos((p1.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*(p3+6.3781e+6).*5.908326797025e-11,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,((pi.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*(q0.*q3.*2.0+q1.*q2.*2.0))./1.8e+2-(pi.*sin((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q2.*2.0-q1.*q3.*2.0))./1.8e+2).*(ba1+a1.*ka1)+((pi.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*(q0.^2.*2.0+q2.^2.*2.0-1.0))./1.8e+2+(pi.*sin((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q1.*2.0+q2.*q3.*2.0))./1.8e+2).*(ba2+a2.*ka2)+((pi.*sin((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.^2.*2.0+q3.^2.*2.0-1.0))./1.8e+2-(pi.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*(q0.*q1.*2.0-q2.*q3.*2.0))./1.8e+2).*(ba3+a3.*ka3),-((pi.*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.^2.*2.0+q2.^2.*2.0-1.0))./1.8e+2-(pi.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q1.*2.0+q2.*q3.*2.0))./1.8e+2).*(ba2+a2.*ka2)+((pi.*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q1.*2.0-q2.*q3.*2.0))./1.8e+2+(pi.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.^2.*2.0+q3.^2.*2.0-1.0))./1.8e+2).*(ba3+a3.*ka3)-((pi.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q2.*2.0-q1.*q3.*2.0))./1.8e+2+(pi.*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q3.*2.0+q1.*q2.*2.0))./1.8e+2).*(ba1+a1.*ka1),-((pi.*cos((p1.*pi)./1.8e+2).*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.^2.*2.0+q2.^2.*2.0-1.0))./1.8e+2+(pi.*cos((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q1.*2.0+q2.*q3.*2.0))./1.8e+2).*(ba2+a2.*ka2)-((pi.*cos((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.^2.*2.0+q3.^2.*2.0-1.0))./1.8e+2-(pi.*cos((p1.*pi)./1.8e+2).*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q1.*2.0-q2.*q3.*2.0))./1.8e+2).*(ba3+a3.*ka3)-((pi.*cos((p1.*pi)./1.8e+2).*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q3.*2.0+q1.*q2.*2.0))./1.8e+2-(pi.*cos((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q2.*2.0-q1.*q3.*2.0))./1.8e+2).*(ba1+a1.*ka1),0.0,0.0,0.0,0.0,0.0,0.0,0.0,(v1.*1.0./(p3+6.3568e+6).^2.*-1.8e+2)./pi,(v2.*1.0./(p3+6.3781e+6).^2.*1.8e+2)./(pi.*cos((p1.*pi)./1.8e+2)),0.0,0.0,0.0,0.0,0.0,sin((p1.*pi)./9.0e+1).*(-2.65874705866125e-9)+v1.*v3.*1.0./(p3+6.3568e+6).^2+v2.^2.*tan((p1.*pi)./1.8e+2).*1.0./(p3+6.3781e+6).^2,v2.*(v3-v1.*tan((p1.*pi)./1.8e+2)).*1.0./(p3+6.3781e+6).^2,-v1.^2.*1.0./(p3+6.3568e+6).^2-v2.^2.*1.0./(p3+6.3781e+6).^2+cos((p1.*pi)./1.8e+2).^2.*5.3174941173225e-9,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,bw1./2.0+(kw1.*w1)./2.0,bw2./2.0+(kw2.*w2)./2.0,bw3./2.0+(kw3.*w3)./2.0,(ba1+a1.*ka1).*(q2.*(cos(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2)-sin(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)).*2.0+q3.*(cos(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2)).*2.0+q0.*cos((p1.*pi)./1.8e+2).*4.0)-(ba2+a2.*ka2).*(q0.*(cos(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2)).*-4.0+q1.*(cos(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2)-sin(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)).*2.0+q3.*cos((p1.*pi)./1.8e+2).*2.0)-(ba3+a3.*ka3).*(q0.*(cos(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2)-sin(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)).*4.0+q1.*(cos(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2)).*2.0-q2.*cos((p1.*pi)./1.8e+2).*2.0),(q3.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*2.0-q2.*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*2.0).*(ba1+a1.*ka1)+(q0.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*4.0+q1.*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*2.0).*(ba2+a2.*ka2)-(q1.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*2.0-q0.*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*4.0).*(ba3+a3.*ka3),-(ba1+a1.*ka1).*(q2.*(cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2)-sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)).*2.0+q3.*(cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2)).*2.0-q0.*sin((p1.*pi)./1.8e+2).*4.0)-(ba2+a2.*ka2).*(q0.*(cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2)).*4.0-q1.*(cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2)-sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)).*2.0+q3.*sin((p1.*pi)./1.8e+2).*2.0)+(ba3+a3.*ka3).*(q0.*(cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2)-sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)).*4.0+q1.*(cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2)).*2.0+q2.*sin((p1.*pi)./1.8e+2).*2.0),0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,bw1.*(-1.0./2.0)-(kw1.*w1)./2.0,0.0,bw3.*(-1.0./2.0)-(kw3.*w3)./2.0,bw2./2.0+(kw2.*w2)./2.0,-(ba2+a2.*ka2).*(q0.*(cos(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2)-sin(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)).*2.0-q2.*cos((p1.*pi)./1.8e+2).*2.0)-(ba3+a3.*ka3).*(q0.*(cos(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2)).*2.0-q3.*cos((p1.*pi)./1.8e+2).*2.0)+(ba1+a1.*ka1).*(q2.*(cos(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2)).*2.0-q3.*(cos(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2)-sin(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)).*2.0+q1.*cos((p1.*pi)./1.8e+2).*4.0),(q2.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*2.0+q3.*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*2.0).*(ba1+a1.*ka1)-q0.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(ba3+a3.*ka3).*2.0+q0.*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(ba2+a2.*ka2).*2.0,(ba2+a2.*ka2).*(q0.*(cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2)-sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)).*2.0+q2.*sin((p1.*pi)./1.8e+2).*2.0)+(ba3+a3.*ka3).*(q0.*(cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2)).*2.0+q3.*sin((p1.*pi)./1.8e+2).*2.0)+(ba1+a1.*ka1).*(q2.*(cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2)).*-2.0+q3.*(cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2)-sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)).*2.0+q1.*sin((p1.*pi)./1.8e+2).*4.0),0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,bw2.*(-1.0./2.0)-(kw2.*w2)./2.0,bw3./2.0+(kw3.*w3)./2.0,0.0,bw1.*(-1.0./2.0)-(kw1.*w1)./2.0,(ba2+a2.*ka2).*(q1.*cos((p1.*pi)./1.8e+2).*2.0+q3.*sin(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2).*2.0-q3.*cos(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*2.0+q2.*cos(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2).*4.0+q2.*sin(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*4.0)+(ba3+a3.*ka3).*(q0.*cos((p1.*pi)./1.8e+2).*2.0+q3.*cos(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2).*2.0+q3.*sin(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*2.0)+sin((p1.*pi)./1.8e+2).*(q0.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2)+q1.*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2)).*(ba1.*2.0+a1.*ka1.*2.0),(q1.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*2.0-q0.*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*2.0).*(ba1+a1.*ka1)+(q2.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*4.0+q3.*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*2.0).*(ba2+a2.*ka2)+q3.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(ba3+a3.*ka3).*2.0,-(ba2+a2.*ka2).*(q1.*sin((p1.*pi)./1.8e+2).*-2.0-q3.*cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2).*2.0+q2.*cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2).*4.0+q2.*sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2).*4.0+q3.*sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2).*2.0)-(ba3+a3.*ka3).*(q0.*sin((p1.*pi)./1.8e+2).*-2.0+q3.*cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2).*2.0+q3.*sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2).*2.0)-cos((p1.*pi)./1.8e+2).*(q0.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2)+q1.*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2)).*(ba1.*2.0+a1.*ka1.*2.0),0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,bw3.*(-1.0./2.0)-(kw3.*w3)./2.0,bw2.*(-1.0./2.0)-(kw2.*w2)./2.0,bw1./2.0+(kw1.*w1)./2.0,0.0,(ba3+a3.*ka3).*(q1.*cos((p1.*pi)./1.8e+2).*2.0+q3.*sin(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2).*4.0-q3.*cos(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*4.0+q2.*cos(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2).*2.0+q2.*sin(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*2.0)-(ba2+a2.*ka2).*(q0.*cos((p1.*pi)./1.8e+2).*2.0-q2.*sin(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2).*2.0+q2.*cos(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*2.0)-sin((p1.*pi)./1.8e+2).*(q1.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2)-q0.*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2)).*(ba1.*2.0+a1.*ka1.*2.0),(q0.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*2.0+q1.*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*2.0).*(ba1+a1.*ka1)+(q2.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*2.0+q3.*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*4.0).*(ba3+a3.*ka3)+q2.*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(ba2+a2.*ka2).*2.0,-(ba3+a3.*ka3).*(q1.*sin((p1.*pi)./1.8e+2).*-2.0-q3.*cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2).*4.0+q2.*cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2).*2.0+q2.*sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2).*2.0+q3.*sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2).*4.0)-(ba2+a2.*ka2).*(q0.*sin((p1.*pi)./1.8e+2).*2.0-q2.*cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2).*2.0+q2.*sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2).*2.0)+cos((p1.*pi)./1.8e+2).*(q1.*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2)-q0.*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2)).*(ba1.*2.0+a1.*ka1.*2.0),0.0,0.0,0.0,0.0,0.0,0.0,v1.*1.0./sqrt(v1.^2+v2.^2+v3.^2),1.8e+2./(pi.*(p3+6.3568e+6)),0.0,0.0,0.0,0.0,0.0,0.0,-v3./(p3+6.3568e+6),sin((p1.*pi)./1.8e+2).*(-1.458423e-4)+(v2.*tan((p1.*pi)./1.8e+2))./(p3+6.3781e+6),(v1.*2.0)./(p3+6.3568e+6),0.0,0.0,0.0,0.0,0.0,0.0,v2.*1.0./sqrt(v1.^2+v2.^2+v3.^2),0.0,-1.8e+2./(pi.*cos((p1.*pi)./1.8e+2).*(p3+6.3781e+6)),0.0,0.0,0.0,0.0,0.0,sin((p1.*pi)./1.8e+2).*1.458423e-4-(v2.*tan((p1.*pi)./1.8e+2).*2.0)./(p3+6.3781e+6),-(v3-v1.*tan((p1.*pi)./1.8e+2))./(p3+6.3781e+6),cos((p1.*pi)./1.8e+2).*(-1.458423e-4)+(v2.*2.0)./(p3+6.3781e+6),0.0,0.0,0.0,0.0,0.0,0.0,v3.*1.0./sqrt(v1.^2+v2.^2+v3.^2),0.0,0.0,1.0,0.0,0.0,0.0,0.0,-v1./(p3+6.3568e+6),cos((p1.*pi)./1.8e+2).*1.458423e-4-v2./(p3+6.3781e+6),0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,cos((p1.*pi)./1.8e+2).*(q0.^2.*2.0+q1.^2.*2.0-1.0)+cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*(q0.*q2.*2.0-q1.*q3.*2.0)+sin((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q3.*2.0+q1.*q2.*2.0),cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q3.*2.0+q1.*q2.*2.0)-sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q2.*2.0-q1.*q3.*2.0),sin((p1.*pi)./1.8e+2).*(q0.^2.*2.0+q1.^2.*2.0-1.0)-cos((p1.*pi)./1.8e+2).*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q2.*2.0-q1.*q3.*2.0)-cos((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q3.*2.0+q1.*q2.*2.0),0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,-cos((p1.*pi)./1.8e+2).*(q0.*q3.*2.0-q1.*q2.*2.0)+sin((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.^2.*2.0+q2.^2.*2.0-1.0)-cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*(q0.*q1.*2.0+q2.*q3.*2.0),cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.^2.*2.0+q2.^2.*2.0-1.0)+sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q1.*2.0+q2.*q3.*2.0),-sin((p1.*pi)./1.8e+2).*(q0.*q3.*2.0-q1.*q2.*2.0)-cos((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.^2.*2.0+q2.^2.*2.0-1.0)+cos((p1.*pi)./1.8e+2).*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q1.*2.0+q2.*q3.*2.0),0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,cos((p1.*pi)./1.8e+2).*(q0.*q2.*2.0+q1.*q3.*2.0)-cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*(q0.^2.*2.0+q3.^2.*2.0-1.0)-sin((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q1.*2.0-q2.*q3.*2.0),sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.^2.*2.0+q3.^2.*2.0-1.0)-cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q1.*2.0-q2.*q3.*2.0),sin((p1.*pi)./1.8e+2).*(q0.*q2.*2.0+q1.*q3.*2.0)+cos((p1.*pi)./1.8e+2).*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.^2.*2.0+q3.^2.*2.0-1.0)+cos((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q1.*2.0-q2.*q3.*2.0),0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,q1.*(-1.0./2.0),q0./2.0,q3./2.0,q2.*(-1.0./2.0),0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,q2.*(-1.0./2.0),q3.*(-1.0./2.0),q0./2.0,q1./2.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,q3.*(-1.0./2.0),q2./2.0,q1.*(-1.0./2.0),q0./2.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0],[17,17]); 
            A = @(t,x,u,prms) eye(17) + prms(7)*Af(u(1),u(2),u(3),x(12),x(13),x(14),x(15),x(16),x(17),...
                prms(1),prms(2),prms(3),prms(4),prms(5),prms(6),x(2),x(3),x(4),x(5),x(6),x(7),x(8),...
                t,prms(8)*x(9),prms(8)*x(10),prms(8)*x(11),u(4),u(5),u(6)); 
            Bf = @(ka1,ka2,ka3,kw1,kw2,kw3,p1,p2,q0,q1,q2,q3,t)reshape([0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,ka1.*(cos((p1.*pi)./1.8e+2).*(q0.^2.*2.0+q1.^2.*2.0-1.0)+cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*(q0.*q2.*2.0-q1.*q3.*2.0)+sin((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q3.*2.0+q1.*q2.*2.0)),ka1.*(cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q3.*2.0+q1.*q2.*2.0)-sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q2.*2.0-q1.*q3.*2.0)),-ka1.*(-sin((p1.*pi)./1.8e+2).*(q0.^2.*2.0+q1.^2.*2.0-1.0)+cos((p1.*pi)./1.8e+2).*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q2.*2.0-q1.*q3.*2.0)+cos((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q3.*2.0+q1.*q2.*2.0)),0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,-ka2.*(cos((p1.*pi)./1.8e+2).*(q0.*q3.*2.0-q1.*q2.*2.0)-sin((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.^2.*2.0+q2.^2.*2.0-1.0)+cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*(q0.*q1.*2.0+q2.*q3.*2.0)),ka2.*(cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.^2.*2.0+q2.^2.*2.0-1.0)+sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q1.*2.0+q2.*q3.*2.0)),-ka2.*(sin((p1.*pi)./1.8e+2).*(q0.*q3.*2.0-q1.*q2.*2.0)+cos((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.^2.*2.0+q2.^2.*2.0-1.0)-cos((p1.*pi)./1.8e+2).*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q1.*2.0+q2.*q3.*2.0)),0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,-ka3.*(-cos((p1.*pi)./1.8e+2).*(q0.*q2.*2.0+q1.*q3.*2.0)+cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*(q0.^2.*2.0+q3.^2.*2.0-1.0)+sin((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q1.*2.0-q2.*q3.*2.0)),ka3.*(sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.^2.*2.0+q3.^2.*2.0-1.0)-cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q1.*2.0-q2.*q3.*2.0)),ka3.*(sin((p1.*pi)./1.8e+2).*(q0.*q2.*2.0+q1.*q3.*2.0)+cos((p1.*pi)./1.8e+2).*cos(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.^2.*2.0+q3.^2.*2.0-1.0)+cos((p1.*pi)./1.8e+2).*sin(t.*7.292115e-5+(p2.*pi)./1.8e+2).*(q0.*q1.*2.0-q2.*q3.*2.0)),0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,kw1.*q1.*(-1.0./2.0),(kw1.*q0)./2.0,(kw1.*q3)./2.0,kw1.*q2.*(-1.0./2.0),0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,kw2.*q2.*(-1.0./2.0),kw2.*q3.*(-1.0./2.0),(kw2.*q0)./2.0,(kw2.*q1)./2.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,kw3.*q3.*(-1.0./2.0),(kw3.*q2)./2.0,kw3.*q1.*(-1.0./2.0),(kw3.*q0)./2.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0],[17,6]); 
            B = @(t,x,u,prms) Bf(prms(1),prms(2),prms(3),prms(4),prms(5),prms(6),x(2),x(3),x(5),x(6),x(7),x(8),t); 
            H1 = [1/obj.odo_gain_guess,zeros(1,10),zeros(1,6)]; 
            H2 = [zeros(3,1),eye(3),zeros(3,4),zeros(3),zeros(3,6)]; 
            C = [H1; 0*H2]; 
            C_ext = [H1; H2]; 

            % Init 
            n_omega_ie = @(p) obj.rotn_factr*[obj.rot_rate_of_earth*cosd(p(1));0;obj.rot_rate_of_earth*sind(p(1))]; 
            n_omega_en = @(p,v) obj.manifld_factr*[-v(2)/((obj.east_radius_of_earth+p(3)));v(1)/(obj.north_radius_of_earth+p(3));-v(2)*tand(p(1))/(obj.east_radius_of_earth+p(3))]; 
            % n_omega_en = @(p,v) [-v(2)/((obj.east_radius_of_earth+p(3))*cosd(p(1)));-v(1)/(obj.north_radius_of_earth+p(3));0]; 
            Sx = @(w) [0,-w(3),w(2);w(3),0,-w(1);-w(2),w(1),0]; 
            Qx = @(w) 0.5*[0,-w(1),-w(2),-w(3);w(1),0,w(3),-w(2);w(2),-w(3),0,w(1);w(3),w(2),-w(1),0]; 
%             C_nb = @(t,p,q,v) quat2rotm(eul2quat([0,-p(1),-p(2)]*pi/180))'...
%                 *eul2rotm(-flip(omega_ie(p)')*t)*quat2rotm(q'); 
%             C_nb = @(t,p,q,v) rotx(-p(2))*axang2rotm([[0,1,0]*rotx(p(2))',-p(1)*pi/180])...
%                 *rotx(-t*obj.rot_rate_of_earth*180/pi)*quat2rotm(q'); % eul2rotm(flip(omega_ie(p)')*t)
            C_nb = @(t,p,q,v) roty(-p(1))*rotx(-p(2))...
                *rotx(-t*obj.rot_rate_of_earth*180/pi)*quat2rotm(q'); % eul2rotm(flip(omega_ie(p)')*t)
            % rotx(t/2) --> its a triangle not a square while integrating 
            gl = @(p) -Sx(n_omega_ie(p))*Sx(n_omega_ie(p))*[0;0;(obj.east_radius_of_earth+p(3))]+[0;0;-obj.earth_gravity]; 

            % dynamics and fix 
%             Fdyn = @(t,p,q,v,a,w) [...
%                 180*v(1)/(pi*(obj.north_radius_of_earth+p(3)));-180*v(2)/(pi*(obj.east_radius_of_earth+p(3))*cosd(p(1)));v(3);...
%                 (expm(Qx(w)*Ts)-eye(4))*q/Ts;... % Qx(w)*q;... % 
%                 (C_nb(t,p,q,v)*a-Sx(2*n_omega_ie(p)+n_omega_en(p,v))*v+gl(p))]; 
% %             imu_fix = @(t,p,q,v,a,w) [w-[v(2)/((obj.east_radius_of_earth+p(3))*cosd(p(1)));v(1)/(obj.north_radius_of_earth+p(3));0];...
% %                 a+C_nb(t,p,q,v)'*(Sx(n_omega_en(p,v))*v-gl(p))]; % w and a 
%             imu_fix = @(t,p,q,v,a,w) [w+C_nb(t,p,q,v)'*(n_omega_en(p,v) + n_omega_ie(p));...
%                 a+C_nb(t,p,q,v)'*(Sx(2*n_omega_ie(p)+n_omega_en(p,v))*v-gl(p))]; % w and a 
% %             imu_fix = @(t,p,q,v,a,w) [w+C_nb(t,p,q,v)'*(n_omega_ie(p)+n_omega_en(p,v));...
% %                 a+C_nb(t,p,q,v)'*(Sx(n_omega_en(p,v))*v-gl(p))]; % w and a 
            G_func = @(p,v) [180*v(1)/(pi*(obj.north_radius_of_earth+p(3)));...
                -180*v(2)/(pi*(obj.east_radius_of_earth+p(3))*cosd(p(1)));v(3)]; 
            f_s = @(s,v,dT) s + dT*norm(v); 
            f_p = @(p,v,dT) p + dT*G_func(p,v); 
            q_gen = @(q,bs,imu_w,prms) expm(Qx(prms(4:6).*imu_w + bs(4:6))*prms(7))*q; 
            f_q = @(q,bs,imu_w,prms) q_gen(q,bs,imu_w,prms); % [not needed] /norm(q_gen(q,bs,imu_w)); 
            f_v = @(t,p,q,v,bs,imu_a,prms) v + prms(7)*(C_nb(t,p,q,v)*(prms(1:3).*imu_a + bs(1:3))...
                -Sx(2*n_omega_ie(p)+n_omega_en(p,v))*v+gl(p)); 
            % f_sym_tst = @(a1,a2,a3,ba1,ba2,ba3,bw1,bw2,bw3,ka1,ka2,ka3,kw1,kw2,kw3,p1,p2,p3,q0,q1,q2,q3,v1,v2,v3,w1,w2,w3)[sqrt(abs(v1).^2+abs(v2).^2+abs(v3).^2);(v1.*1.8e+2)./(pi.*(p3+6.3568e+6));(v2.*-1.8e+2)./(pi.*cos((p1.*pi)./1.8e+2).*(p3+6.3781e+6));v3;-q1.*(bw1./2.0+(kw1.*w1)./2.0)-q2.*(bw2./2.0+(kw2.*w2)./2.0)-q3.*(bw3./2.0+(kw3.*w3)./2.0);q0.*(bw1./2.0+(kw1.*w1)./2.0)-q3.*(bw2./2.0+(kw2.*w2)./2.0)+q2.*(bw3./2.0+(kw3.*w3)./2.0);q0.*(bw2./2.0+(kw2.*w2)./2.0)+q3.*(bw1./2.0+(kw1.*w1)./2.0)-q1.*(bw3./2.0+(kw3.*w3)./2.0);-q2.*(bw1./2.0+(kw1.*w1)./2.0)+q1.*(bw2./2.0+(kw2.*w2)./2.0)+q0.*(bw3./2.0+(kw3.*w3)./2.0);(ba1+a1.*ka1).*(cos((p1.*pi)./1.8e+2).*(q0.^2.*2.0+q1.^2.*2.0-1.0)+cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*(q0.*q2.*2.0-q1.*q3.*2.0)+sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2).*(q0.*q3.*2.0+q1.*q2.*2.0))-(ba2+a2.*ka2).*(cos((p1.*pi)./1.8e+2).*(q0.*q3.*2.0-q1.*q2.*2.0)-sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2).*(q0.^2.*2.0+q2.^2.*2.0-1.0)+cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*(q0.*q1.*2.0+q2.*q3.*2.0))-(ba3+a3.*ka3).*(-cos((p1.*pi)./1.8e+2).*(q0.*q2.*2.0+q1.*q3.*2.0)+cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*(q0.^2.*2.0+q3.^2.*2.0-1.0)+sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2).*(q0.*q1.*2.0-q2.*q3.*2.0));(cos((p2.*pi)./1.8e+2).*(q0.^2.*2.0+q2.^2.*2.0-1.0)+sin((p2.*pi)./1.8e+2).*(q0.*q1.*2.0+q2.*q3.*2.0)).*(ba2+a2.*ka2)+(sin((p2.*pi)./1.8e+2).*(q0.^2.*2.0+q3.^2.*2.0-1.0)-cos((p2.*pi)./1.8e+2).*(q0.*q1.*2.0-q2.*q3.*2.0)).*(ba3+a3.*ka3)+(ba1+a1.*ka1).*(cos((p2.*pi)./1.8e+2).*(q0.*q3.*2.0+q1.*q2.*2.0)-sin((p2.*pi)./1.8e+2).*(q0.*q2.*2.0-q1.*q3.*2.0));-(ba1+a1.*ka1).*(-sin((p1.*pi)./1.8e+2).*(q0.^2.*2.0+q1.^2.*2.0-1.0)+cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2).*(q0.*q2.*2.0-q1.*q3.*2.0)+cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2).*(q0.*q3.*2.0+q1.*q2.*2.0))-(ba2+a2.*ka2).*(sin((p1.*pi)./1.8e+2).*(q0.*q3.*2.0-q1.*q2.*2.0)+cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2).*(q0.^2.*2.0+q2.^2.*2.0-1.0)-cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2).*(q0.*q1.*2.0+q2.*q3.*2.0))+(ba3+a3.*ka3).*(sin((p1.*pi)./1.8e+2).*(q0.*q2.*2.0+q1.*q3.*2.0)+cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2).*(q0.^2.*2.0+q3.^2.*2.0-1.0)+cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2).*(q0.*q1.*2.0-q2.*q3.*2.0))-9.81e+2./1.0e+2;0.0;0.0;0.0;0.0;0.0;0.0]; 
            fsym = @(a1,a2,a3,ba1,ba2,ba3,bw1,bw2,bw3,ka1,ka2,ka3,kw1,kw2,kw3,p1,p2,p3,q0,q1,q2,q3,t,v1,v2,v3,w1,w2,w3)...
                [sqrt(abs(v1).^2+abs(v2).^2+abs(v3).^2);(v1.*1.8e+2)./(pi.*(p3+6.3568e+6));(v2.*-1.8e+2)./(pi.*cos((p1.*pi)./1.8e+2).*(p3+6.3781e+6));v3;-q1.*(bw1./2.0+(kw1.*w1)./2.0)-q2.*(bw2./2.0+(kw2.*w2)./2.0)-q3.*(bw3./2.0+(kw3.*w3)./2.0);q0.*(bw1./2.0+(kw1.*w1)./2.0)-q3.*(bw2./2.0+(kw2.*w2)./2.0)+q2.*(bw3./2.0+(kw3.*w3)./2.0);q0.*(bw2./2.0+(kw2.*w2)./2.0)+q3.*(bw1./2.0+(kw1.*w1)./2.0)-q1.*(bw3./2.0+(kw3.*w3)./2.0);-q2.*(bw1./2.0+(kw1.*w1)./2.0)+q1.*(bw2./2.0+(kw2.*w2)./2.0)+q0.*(bw3./2.0+(kw3.*w3)./2.0);v2.*(sin((p1.*pi)./1.8e+2).*1.458423e-4-(v2.*tan((p1.*pi)./1.8e+2))./(p3+6.3781e+6))+(ba1+a1.*ka1).*(cos((p1.*pi)./1.8e+2).*(q0.^2.*2.0+q1.^2.*2.0-1.0)+(cos(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2)).*(q0.*q3.*2.0+q1.*q2.*2.0)+(cos(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2)-sin(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)).*(q0.*q2.*2.0-q1.*q3.*2.0))-(ba2+a2.*ka2).*(-(cos(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2)).*(q0.^2.*2.0+q2.^2.*2.0-1.0)+(cos(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2)-sin(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)).*(q0.*q1.*2.0+q2.*q3.*2.0)+cos((p1.*pi)./1.8e+2).*(q0.*q3.*2.0-q1.*q2.*2.0))-(ba3+a3.*ka3).*((cos(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2)-sin(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)).*(q0.^2.*2.0+q3.^2.*2.0-1.0)+(cos(t.*7.292115e-5).*sin((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2)).*(q0.*q1.*2.0-q2.*q3.*2.0)-cos((p1.*pi)./1.8e+2).*(q0.*q2.*2.0+q1.*q3.*2.0))-cos((p1.*pi)./1.8e+2).*sin((p1.*pi)./1.8e+2).*(p3+6.3781e+6).*5.3174941173225e-9-(v1.*v3)./(p3+6.3568e+6);-v1.*(sin((p1.*pi)./1.8e+2).*1.458423e-4-(v2.*tan((p1.*pi)./1.8e+2))./(p3+6.3781e+6))-((sin(t.*7.292115e-5).*sin((p2.*pi)./1.8e+2)-cos(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2)).*(q0.^2.*2.0+q2.^2.*2.0-1.0)-(cos(t.*7.292115e-5).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2)).*(q0.*q1.*2.0+q2.*q3.*2.0)).*(ba2+a2.*ka2)+((cos(t.*7.292115e-5).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2)).*(q0.^2.*2.0+q3.^2.*2.0-1.0)+(sin(t.*7.292115e-5).*sin((p2.*pi)./1.8e+2)-cos(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2)).*(q0.*q1.*2.0-q2.*q3.*2.0)).*(ba3+a3.*ka3)-((cos(t.*7.292115e-5).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2)).*(q0.*q2.*2.0-q1.*q3.*2.0)+(sin(t.*7.292115e-5).*sin((p2.*pi)./1.8e+2)-cos(t.*7.292115e-5).*cos((p2.*pi)./1.8e+2)).*(q0.*q3.*2.0+q1.*q2.*2.0)).*(ba1+a1.*ka1)+v3.*(cos((p1.*pi)./1.8e+2).*1.458423e-4-v2./(p3+6.3781e+6));cos((p1.*pi)./1.8e+2).^2.*(p3+6.3781e+6).*5.3174941173225e-9+v1.^2./(p3+6.3568e+6)-(ba1+a1.*ka1).*((cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2)).*(q0.*q3.*2.0+q1.*q2.*2.0)+(cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2)-sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)).*(q0.*q2.*2.0-q1.*q3.*2.0)-sin((p1.*pi)./1.8e+2).*(q0.^2.*2.0+q1.^2.*2.0-1.0))-(ba2+a2.*ka2).*((cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2)).*(q0.^2.*2.0+q2.^2.*2.0-1.0)-(cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2)-sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)).*(q0.*q1.*2.0+q2.*q3.*2.0)+sin((p1.*pi)./1.8e+2).*(q0.*q3.*2.0-q1.*q2.*2.0))+(ba3+a3.*ka3).*((cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2)-sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)).*(q0.^2.*2.0+q3.^2.*2.0-1.0)+(cos(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*sin((p2.*pi)./1.8e+2)+sin(t.*7.292115e-5).*cos((p1.*pi)./1.8e+2).*cos((p2.*pi)./1.8e+2)).*(q0.*q1.*2.0-q2.*q3.*2.0)+sin((p1.*pi)./1.8e+2).*(q0.*q2.*2.0+q1.*q3.*2.0))-v2.*(cos((p1.*pi)./1.8e+2).*1.458423e-4-v2./(p3+6.3781e+6))-9.81e+2./1.0e+2;0.0;0.0;0.0;0.0;0.0;0.0];  
            f_sns = @(t,x,u,prms) x + prms(7)*fsym(u(1),u(2),u(3),x(12),x(13),x(14),x(15),x(16),x(17),...
                prms(1),prms(2),prms(3),prms(4),prms(5),prms(6),x(2),x(3),x(4),x(5),x(6),x(7),x(8),...
                t,x(9),x(10),x(11),u(4),u(5),u(6)); 

            % o <--x(1) | p <--x(2:4) | q <--x(5:8) | v <--x(9:11) | bs <--x(12:17) [+] imu_a <--u(1:3) | imu_w <--u(4:6)  
            % f = @(x) [f_s(x(1),x(9:11));f_p(x(2:4),x(9:11));zeros(7,1);x(12:17,1)]; 
            f = @(x) [zeros(11,1);x(12:17,1)]; 
            g = @(t,x,u,prms) [f_s(x(1),prms(8)*x(9:11),prms(7));f_p(x(2:4),prms(8)*x(9:11),prms(7));f_q(x(5:8),x(12:17),u(4:6),prms);f_v(t,x(2:4),x(5:8),x(9:11),x(12:17),u(1:3),prms);zeros(6,1)]; 
            h = @(x) C*x; h_ext = @(x) C_ext*x; 
            f_guess = @(x) [zeros(11,1);x(12:17,1)]; 
            g_guess = @(t,x,u,prms) [f_s(x(1),prms(8)*x(9:11),prms(7));f_p(x(2:4),prms(8)*x(9:11),prms(7));f_q(x(5:8),x(12:17),u(4:6),prms);f_v(t,x(2:4),x(5:8),x(9:11),x(12:17),u(1:3),prms);zeros(6,1)]; 
            h_guess = @(x) C*x; h_ext_guess = @(x) C_ext*x; 
        end 
        % Set methods: set_ 
        function set_sampling_and_resample_data(varargin) 
            obj = varargin{1}; 
            % Settings 
            if nargin==2 
                obj.downsampling = varargin{2}; % Downsampling 
            elseif nargin==3 
                obj.downsampling = varargin{2}; % Downsampling 
                obj.sampling_frequency = varargin{3}; % Sampling Frequency (Hz) 
            end 
            obj.sample_static_data();
            obj.sample_all_data();
            obj.set_data_subset(); 
            obj.sample_vendor_and_ref_data(); 
        end 
        % Load methods: load_ 
        function load_WB_trajectroy(obj) 
            for i=1:length(obj.selected_marker_indices)-1
                filename = [sim_ig.marker_data.name{i},'_',sim_ig.marker_data.name{i+1},'.csv']; 
            end 
        end 
        function load_best(obj) 
            try % orient_now 
                load('settings/best_orientation_so_far.mat'); 
                obj.best_initial_orientation = orient_now; 
            catch 
                obj.best_initial_orientation = [1;0;0;0]; 
            end 
            try % orient_final 
                obj.best_final_orientation = orient_final; 
            catch 
                obj.best_final_orientation = [1;0;0;0]; 
            end 
            try % orient_traj 
                obj.best_quaternion_orientation_trajectory = orient_traj; 
            catch 
                obj.best_quaternion_orientation_trajectory = zeros(4,size(obj.all_datapoints,2)); 
                obj.best_quaternion_orientation_trajectory(1,:) = 1; 
            end 
            try % orient_traj_eul 
                obj.best_euler_orientation_trajectory = orient_traj_eul; 
            catch 
                obj.best_euler_orientation_trajectory = zeros(0,size(obj.all_datapoints,2)); 
            end 
            try % best_IMUgain_so_far 
                load('settings/best_IMUgain_so_far.mat');
                % obj.best_gain = gains_now; 
                load('settings/best_imu_gain.mat')
                obj.best_gain = new_best_gain(:, 4:6)';
                obj.best_gain(4:6, :) = new_best_gain(:, 1:3)'; 
                
            catch err
                disp(newline)
                warning('IGNORED ERROR WARNING::')
                warning(getReport(err,'extended'));
                disp(newline)
            end 
        end 
        % Save methods: save_ 
        % Others 
        function var = initialize_simulink_data(obj) 
            % For simulink 
            var.time = obj.timepoints'; 
            var.signals.values = obj.datapoints'; 
            var.signals.dimensions = size(obj.datapoints,1); 
        end 
    end 
    methods % Copy of the 2-7 steps + new ones 
        %% Steps 
        function S2_main_best_initial_orientation(obj) 


            %% Step 1: testingv 
            testf = 50; 
            usegyrodata = 1; 
            % theta = rand*pi; 
            % vec = randn(3,1); 
            % orient_quat = [cos(theta/2);sin(theta/2)*vec/norm(vec)]; 
            max_steps = 300; 

            % Initialization 
            theta = -2.3*pi/4; 
            vec = [0;0;1]; 
            orient_quat = [cos(theta/2);sin(theta/2)*vec/norm(vec)]; 
            
            %% Step 3: Sort data into control singals 
            len_data = length(obj.datapoints(1,:)); 
            disp(['Length of dataset = ', num2str(len_data)]) 
            
            %% Step 4: Create gravity and rotation inline function  
            g_init = obj.get_gravity_at_fraction_or_index(obj.start_index); 
            C_q = @(q) quat2rotm(q'); 
            try 
                load('settings/best_orientation_so_far.mat'); 
                [~] = orient_now; 
            catch 
                % gains_now = obj.imu_device_obj.get_gains(); 
                orient_now = orient_quat; 
            end 

            %% Step 2: Optimize the orientation quaternion 
            number_of_directions = 50; 
            grad_bounds = diag([1e-0*ones(1,4)]); 
            Q = diag([1e0,1e0,1e3]); % weight on the norm of final state 
            Q_y = 1; 
            length_of_orient_vector = length(grad_bounds); 
            accleration_factor = 0.1; 
            pig_orient = 0*atan2(obj.start_gps(2)-obj.end_gps(2),obj.start_gps(1)-obj.end_gps(1)); 
            for i=1:max_steps 
                % Sub-step 2a: Choose gradients at uniformly random 
                random_orient_grads = [zeros(length_of_orient_vector,1), ...
                    2*(0.5-rand(length_of_orient_vector, number_of_directions-1))]; 

                % Sub-step 2b: Find new points along the random gradients 
                new_orients = repmat(orient_now,1,number_of_directions) + accleration_factor*random_orient_grads; 

                % Sub-step 2c: Evaluate end gps point for all new states 
                all_costs = inf(1,number_of_directions); 
                for j=1:number_of_directions 
                    new_q = new_orients(:,j)/norm(new_orients(:,j)); 
                    gravity_orientation_error = ([0;0;obj.earth_gravity] - C_q(new_q)*g_init); 
                    gravity_orientation_cost = gravity_orientation_error'*Q*gravity_orientation_error; 
                    eul_init = quat2eul(new_q'); 
                    yaw_orientation_error = eul_init(1) - pig_orient; 
                    yaw_orientation_cost = Q_y*yaw_orientation_error^2; 
                    all_costs(1,j) = gravity_orientation_cost + yaw_orientation_cost; 
                end 

                % Sub-step 2d: Choose the best and set it as new gain 
                [~,best_arg] = min(all_costs); 
                orient_now = new_orients(:,best_arg); 
                obj.best_initial_orientation = orient_now/norm(orient_now); 
                if obj.auto_mode 
                    if obj.auto_inputs.S2.en_pause 
                        pause(obj.auto_inputs.S2.pause_timing) 
                    end 
                else 
                    pause(0.5) 
                end 
                try 
                    if obj.auto_mode % don't save orientation 
                        if obj.auto_inputs.S2.dont_save_orient
                            error('prevent saving init orientation!'); 
                        end 
                    end 
                    save('settings/best_orientation_so_far.mat','orient_now','-append'); 
                catch 
                    if ~obj.auto_mode; warning('Not saved! '); end 
                end 

                % Sub-step 2e: Progres bar 
                percent_done = i*100/max_steps; 
                
                if obj.auto_inputs.en_plot(i); clc; disp(['Progress: <', repmat('||',1,floor(percent_done/3 )), '> ', num2str(percent_done), ' % ']); end  
            end 
            
            if obj.auto_mode; return; end 
            %% Step 2: Compare 
            disp('Effect of orientation on gravity: ') 
            disp(C_q(obj.best_initial_orientation)*g_init) 
            
            %% Final step: 
            disp('  ') 
            disp('<<<< All STEPS completed! >>>>') 
            if pause_dbug_fcn3(); keyboard; end; clc 
        end 
        function S2_main_compute_initial_orientation(obj) 


            %% Step 1: testingv 
            testf = 50; 
            usegyrodata = 1; 
            % theta = rand*pi; 
            % vec = randn(3,1); 
            % orient_quat = [cos(theta/2);sin(theta/2)*vec/norm(vec)]; 
            max_steps = 300; 

            % Initialization 
            theta = -2.3*pi/4; 
            vec = [0;0;1]; 
            orient_quat = [cos(theta/2);sin(theta/2)*vec/norm(vec)]; 
            
            %% Step 3: Sort data into control singals 
            len_data = length(obj.datapoints(1,:)); 
            disp(['Length of dataset = ', num2str(len_data)]) 
            
            %% Step 4: Create gravity and rotation inline function  
            g_init = obj.get_gravity_at_fraction_or_index(obj.start_index); 
            C_q = @(q) quat2rotm(q'); 
            try 
                load('settings/best_orientation_so_far.mat'); 
                [~] = orient_now; 
            catch 
                % gains_now = obj.imu_device_obj.get_gains(); 
                orient_now = orient_quat; 
            end 

            disp(['The acceleration vector -->    ',num2str(g_init')]); 
            roll_angle = atan2(g_init(2),g_init(3)); 
            disp(['The roll angle is ',num2str(roll_angle*180/pi),' degrees']); 
            disp(['Cross check -->   ', num2str(9.81*[sin(roll_angle),cos(roll_angle)])])
            pitch_angle = - asin(g_init(1)/9.81); % 0; % not looking down or up
            try 
                yaw_angle = aip.auto_inputs.yaw_angle; 
            catch 
                yaw_angle = atan2(-obj.end_gps(2)+obj.start_gps(2),obj.end_gps(1)-obj.start_gps(1)); 
            end 
            disp(['Assuming zero pitch and ',num2str(round(yaw_angle*180/pi)),' degree yaw'])
            quat_angle = angle2quat(yaw_angle,pitch_angle,roll_angle); 
            obj.best_initial_orientation = quat_angle'; 

            try 
                if obj.auto_mode % don't save orientation 
                    if obj.auto_inputs.S2.dont_save_orient
                        error('prevent saving init orientation!'); 
                    end 
                end 
                save('settings/best_orientation_so_far.mat','orient_now','-append'); 
            catch 
                if ~obj.auto_mode; warning('Not saved! '); end 
            end 
            
            if obj.auto_mode; return; end 
            %% Step 2: Compare 
            disp('Effect of orientation on gravity: ') 
            disp(C_q(obj.best_initial_orientation)*g_init) 
            
            %% Final step: 
            disp('  ') 
            disp('<<<< All STEPS completed! >>>>') 
            if pause_dbug_fcn3(); keyboard; end; clc 
        end 
        % Sxa/b lagrangian 
        function S6b_mbf_mnfld_dyn_unkwn_smple_odovelmag_scld_odovelcst_gd_lagr(obj) 
            obj.init_lagrangians(); 

            figure(1) 
            clf 
            pause(0.1) 
            figure(2) 
            clf 
            pause(0.1) 
            figure(3) 
            clf 
            pause(0.1) 
            %% Step-0 [New] 
%             obj.dlgrngn_diter = 5; 

            %% Step 1: testingv 
            testf = 50; 
            usegyrodata = 1; 
            % theta = rand*pi; 
            % vec = randn(3,1); 
            % orient_quat = [cos(theta/2);sin(theta/2)*vec/norm(vec)]; 
            max_steps = 4000; 

            % Initialization 
            theta = -2.3*pi/4; 
            vec = [0;0;1]; 
            orient_quat = [cos(theta/2);sin(theta/2)*vec/norm(vec)]; 
            
            %% Step 3: Sort data into control singals 
            len_data = length(obj.datapoints(1,:)); 
            disp(['Length of dataset = ', num2str(len_data)]) 
            gyr = obj.datapoints(1:3,1:min(len_data,end))'; 
            acc = obj.datapoints(4:6,1:min(len_data,end))'; 

            % Load 
            try 
                load(['../OUTPUT', obj.auto_inputs.path_suffix, '/to_continue_unkwn_dT.mat']) 
                [~] = agb_now2; 
            catch 
                % init of tuning parameters 
                dT0 = 10/obj.sampling_frequency; % dT0 = (obj.downsampling/10)/obj.sampling_frequency; % % dT0 = obj.downsampling/obj.sampling_frequency; 
                agb_now2 = [1;1;1;1;0;0;0;1;1;1;0;0;0;0;0;0;0;0;0;0;dT0]; % odo_gain, (imu gains, bias) X 2, q0  
            end 
            
            %% Step 4: Optimize the angle, gains and bias 
            number_of_directions = 50; 
            %             old_grad_bounds = 1e-1*diag([1e-2,1e-3*ones(1,3),1e2*[1e-5,1e-5,1e-5],...
            %                 1e-3*ones(1,3),1e2*[1e-5,1e-5,1e-5],1e-2*ones(1,4),1e-2*ones(1,3)]); %,1e7*1e-6]); 
            grad_bounds = 1e-2*diag([1e-2,1e-3*ones(1,3),1e2*[1e-5,1e-5,1e-5],...
                1e-3*ones(1,3),1e-2*[1e-5,1e-5,1e-5],1e-3*ones(1,4),1e-1*ones(1,3),...
                1e-4]); %,1e7*1e-6]); 
            % Q = diag([1e6,1e6,1e-5]); % weight on the norm of final state 
            Q = diag([2e7,2e7,1e-3]); % 1km error x-y plane & z axis produces ~1e3 
            Div_odo = 5e5; 
            length_of_gain_vector = length(grad_bounds); 
            accleration_factor = 0.4; 
            eps_factr = 0.995; 
            eps_ifactr = 40; 
            epsilon = eps_factr^0; % 1 --> generated q  | 0 --> q from gyro data 
            try % test epsilon=0 
%                 [~] = uncomment_to_disable; 
                epsilon = 0; 
                warning('epsilon is set as ZERO! ') 
            catch err
                disp(newline)
                warning('IGNORED ERROR WARNING::')
                warning(getReport(err,'extended'));
                disp(newline)
            end
            % for dynamics 
            indices = obj.start_index:obj.end_index; 
            odo_all = obj.odo_gain_guess*repmat([diff(obj.odometer_max(indices)')', 0],3,1); 
            w_all = diag(obj.best_gain(4:end))*obj.all_datapoints(1:3,indices); 
            odo_data = obj.get_odometer_distance(indices); 
            % C_q = @(q) quat2rotm(q'); 
            noindices = length(indices); 
            % S_w = @(w) [0,-w(1),-w(2),-w(3);w(1),0,w(3),-w(2);w(2),-w(3),0,w(1);w(3),w(2),-w(1),0]; 
            % G_matrix = @(p) diag([(180/pi)/(obj.north_radius_of_earth + p(3)), ...
            %     -(180/pi)/((obj.east_radius_of_earth + p(3))*cosd(p(1))), 1]); % Lat Lon Up 
            % 
            try 
                load(['../OUTPUT', obj.auto_inputs.path_suffix, '/to_continue_unkwn_dT_vel_scld.mat']) 
                if epsilon~=0; epsilon = eps_factr^floor(start_iter/eps_ifactr); end 
            catch 
                start_iter = 1; 
            end 
            [f,g,h,h_ext,f_guess,g_guess,h_guess,h_ext_guess,A,B,C,C_ext,... % get_full_dynamics_manifold
                n_omega_ie,n_omega_en,Sx,Qx,C_nb,gl,G_func,f_s,f_p,q_gen,f_q,f_v,f_sns] ...
                = obj.get_full_dynamics_manifold_unknown_sampling_odovelmag_scaled(); 
            
            % perturbation check 
            stvar_name = {'Velocity gain 4 odoadjust','Accel-x gain','Accel-y gain','Accel-z gain','Accel-x bias','Accel-y bias','Accel-z bias',...
                'Gyro-x gain','Gyro-y gain','Gyro-z gain','Gyro-x bias','Gyro-y bias','Gyro-z bias','Init Quaternion-0',...
                'Init Quaternion-x','Init Quaternion-y','Init Quaternion-z','Init Velocity-x','Init Velocity-y','Init Velocity-z','Sampling Time'}; 
            if obj.auto_mode 
                en_grad_chk = 1; 
            else 
                en_grad_chk = input('Press `1` to enable graident tuning (press ENTER to skip): '); 
            end 
            if ~isempty(en_grad_chk) % check grad_bounds 
%                 [~,~,~,v,p_gen_basecase] = obj.get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld(agb_now2,...
%                     epsilon,indices,odo_all,w_all,f,g,C_nb); 
                [~,~,~,v,p_gen_basecase] = get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld_mex(agb_now2,...
                    indices,odo_all,w_all,obj.downsampling,obj.start_gps,...
                    obj.best_initial_orientation);
                final_state_basecase = p_gen_basecase(:,end); 
                report_perturbation = nan(4,length_of_gain_vector); 
                report_perturbation(1,1) = 0; 
                for i=1:length_of_gain_vector 
                    new_agb_now2 = agb_now2; 
                    for j=0:number_of_directions 
                        new_agb_now2(i) = new_agb_now2(i) + (3^j)*accleration_factor*grad_bounds(i,i); 
%                         [~,~,~,~,p_gen,odo_gen] = obj.get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld(new_agb_now2,...
%                             epsilon,indices,odo_all,w_all,f,g,C_nb); 
                        [~,~,~,~,p_gen,odo_gen] = get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld_mex(new_agb_now2,...
                            indices,odo_all,w_all,obj.downsampling,obj.start_gps,...
                            obj.best_initial_orientation);
                        final_state_now = p_gen(:,end); 
                        report_perturbation(2:4,i) = (final_state_now-final_state_basecase).*diag(Q).*(final_state_now-final_state_basecase); 
%                         figure(1) % <-- testing 
%                         geoplot(p_gen(1,1)',p_gen(2,1)','x'); 
%                         hold on 
%                         geoplot(p_gen(1,:)',p_gen(2,:)'); 
%                         geoplot(p_gen_basecase(1,:)',p_gen_basecase(2,:)','-.'); 
%                         geoplot(obj.end_gps(1),obj.end_gps(2),'o'); 
%                         hold off 
%                         y_fulltraj = [transpose(odo_data(1)+odo_gen)/obj.odo_gain_guess,p_gen']; 
%                         [gstart,gfinish,~,gmrkd] = obj.odo_marker_hit(y_fulltraj);
%                         obj.marker_projection(gstart,gfinish,gmrkd); 
%                         title(['Tuning parameter: ', stvar_name{i}]) 
%                         pause 
                        if norm(report_perturbation(2:4,i))>1 % approx 1 meter in x-y OR z direction 
                            report_perturbation(1,i) = j; 
                            figure(1) % <-- testing 
                            geoplot(p_gen(1,1)',p_gen(2,1)','x'); 
                            hold on 
                            geoplot(p_gen(1,:)',p_gen(2,:)'); 
                            geoplot(p_gen_basecase(1,:)',p_gen_basecase(2,:)','-.'); 
                            geoplot(obj.end_gps(1),obj.end_gps(2),'o'); 
                            hold off 
                            y_fulltraj = [transpose(odo_data(1)+odo_gen)/obj.odo_gain_guess,p_gen']; 
                            [gstart,gfinish,~,gmrkd] = obj.odo_marker_hit(y_fulltraj);
                            obj.marker_NW_distance(gstart,gfinish,gmrkd); 
                            title(['Tuning parameter: ', stvar_name{i}]) 
                            pause(0.1) 
                            break 
                        end 
                    end 
                end 
                disp('Perturbation report: ') 
                disp(report_perturbation) 
                disp('Old grad bounds: ') 
                disp(diag(grad_bounds)') 
                disp('Modified grad bounds: ') 
                disp((3.^report_perturbation(1,:)).*diag(grad_bounds)') 
                if obj.auto_mode 
                    sentvty = obj.auto_inputs.S6.sentvty; 
                else 
                    sentvty = input('Enter sensitivity of graidents (press ENTER to skip): '); 
                end 
                if ~isempty(sentvty) % modify grad_bounds 
                    grad_bounds = sentvty*diag(3.^report_perturbation(1,:))*grad_bounds; 
                end 
            end 
            % disp('Press any key to continue ... ') 
            % pause 
            %             if sum(isnan(report_perturbation(1,:)))>0 
            %                 warning('Too small graidents! ') 
            %                 report_perturbation(1,isnan(report_perturbation(1,:))) = number_of_directions; 
            %             end 

            % main loop 
            no_of_elites = floor((50/100)*number_of_directions); 
            best_grad_bound_so_far = zeros(length_of_gain_vector,no_of_elites); 
            auto_tuning_start_iter = start_iter; 
            for i=start_iter:max_steps 
                % Sub-step 2a: Choose gradients at uniformly random 
                random_gain_grads = [zeros(length_of_gain_vector,1), best_grad_bound_so_far, ...
                    2*grad_bounds*(0.5-rand(length_of_gain_vector, number_of_directions-no_of_elites-1))]; 

                % Sub-step 2b: Find new points along the random gradients 
                %                 accleration_factor = 1/i; 
                new_agb = repmat(agb_now2,1,number_of_directions) + accleration_factor*random_gain_grads; 

                % Sub-step 2c: Evaluate end gps point for all new states 
                all_costs = inf(1,number_of_directions); 
                for j=1:number_of_directions 
                    % load parameters for forward run 
                    %                     [~,~,~,v,p_gen,odo_gen] = obj.get_full_dynamical_trajectory(new_agb(:,j),...
                    %                         epsilon,indices,odo_all,w_all); 
%                     [~,~,~,v,p_gen,odo_gen] = obj.get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld(new_agb(:,j),...
%                         epsilon,indices,odo_all,w_all,f,g,C_nb); 
                    
                    % nov 6 change
                    % scale the odo gains
                    obj.odo_gain_guess = obj.odo_gain_guess*new_agb(1,j);
                    obj.odo_gain_backcalc = obj.odo_gain_backcalc*new_agb(1,j);
                    odo_all = obj.odo_gain_guess*repmat([diff(obj.odometer_max(indices)')', 0],3,1); 
                    odo_data = obj.get_odometer_distance(indices); 
                    [~,~,~,v,p_gen,odo_gen] = get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld_mex(new_agb(:,j),...
                        indices,odo_all,w_all,obj.downsampling,obj.start_gps,...
                        obj.best_initial_orientation);
                    v_imu_magn = abs(new_agb(1,j))*sqrt(sum(v.*v,1)); 
                    [marker_costs,end_point_cost,straightning_cost,odo_cost,vel_odo_cost] ...
                        = obj.get_costs_mrkd_S6b_odovelcst_lagr(odo_gen,p_gen,v_imu_magn,odo_data,noindices); 
                    all_costs(1,j) = marker_costs + end_point_cost + straightning_cost ...
                        + odo_cost + vel_odo_cost; 
                    % start-1 < for testing > 
%                     figure(1) 
%                     geoplot(p_gen(1,1)',p_gen(2,1)','x'); 
%                     hold on 
%                     geoplot(p_gen(1,:)',p_gen(2,:)'); 
%                     geoplot(obj.end_gps(1),obj.end_gps(2),'o'); 
%                     hold off 
%                     title(['i = ', num2str(i), ' | elevation error = ', ...
%                         num2str(obj.end_gps(3)-p_gen(3,end))]) 
%                     figure(2) 
%                     clf; stem(all_costs); hold on; 
%                     plot(min(all_costs)*ones(1,number_of_directions), 'g--'); 
%                     plot(all_costs(1)*ones(1,number_of_directions), '-'); 
%                     hold off 
%                     figure(3) 
%                     plot(odo_gen); hold on; plot(odo_data-odo_data(1)); hold off 
%                     % disp(all_costs(1,1:j)) 
%                     % disp(straightning_cost) 
%                     disp('error components = ') 
%                     disp(transpose((final_state(1:3)-obj.end_gps').*diag(Q).*(final_state(1:3)-obj.end_gps'))) 
%                     disp(['end_cost = ', num2str(end_point_cost), ' & strtn_cost = ', num2str(straightning_cost), ...
%                         ' & odo_cost = ', num2str(odo_cost)]) 
                    % end-1 < for testing >
                end 

                % Sub-step 2d: Choose the best and set it as new gain 
                [~,best_arg] = sort(all_costs); 
                agb_now2 = new_agb(:,best_arg(1)); 
                best_grad_bound_so_far = random_gain_grads(:,best_arg(1:no_of_elites)); 
                best_grad_bound_so_far = obj.elite_selection(best_grad_bound_so_far,no_of_elites,...
                    [25,25,nan],0.5); % [old elites, scaled elites, crossover] 
                % see plots 
                %                 [~,~,~,v,p_gen,odo_gen] = obj.get_full_dynamical_trajectory(agb_now2,...
                %                     epsilon,indices,odo_all,w_all); 
%                 [q_dot,q,v_dot,v,p_gen,odo_gen,acc_generated_body] = obj.get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld(agb_now2,...
%                     epsilon,indices,odo_all,w_all,f,g,C_nb); 
                [q_dot,q,v_dot,v,p_gen,odo_gen,acc_generated_body] = get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld_mex(agb_now2,...
                    indices,odo_all,w_all,obj.downsampling,obj.start_gps,...
                    obj.best_initial_orientation);
                final_state = p_gen(:,end); 
                disp((final_state(1:3)-obj.end_gps').*diag(Q).*(final_state(1:3)-obj.end_gps')) 
                % lagrangian update 
                v_imu_magn = abs(agb_now2(1))*sqrt(sum(v.*v,1)); 
                obj.get_costs_mrkd_S6b_odovelcst_lagr(odo_gen,p_gen,v_imu_magn,odo_data,noindices,true); 
                
                if obj.auto_inputs.en_plot(i)
                    figure(1) % <-- testing 
                    geoplot(p_gen(1,1)',p_gen(2,1)','x'); 
                    hold on 
                    geoplot(p_gen(1,:)',p_gen(2,:)'); 
                    geoplot(obj.end_gps(1),obj.end_gps(2),'o'); 
                    hold off 
                    y_fulltraj = [transpose(odo_data(1)+odo_gen)/obj.odo_gain_guess,p_gen']; 
                    [gstart,gfinish,~,gmrkd] = obj.odo_marker_hit(y_fulltraj);
                    obj.marker_NW_distance(gstart,gfinish,gmrkd);
                    title(['vel mismatch = ',num2str(vel_odo_cost)])
                    figure(2) 
                    plot(odo_all') 
                    hold on 
                    plot(acc_generated_body') 
                    hold off 
                    xlabel('index --> ') 
                    ylabel('Acceleration --> ') 
                    legend('acc imu data-x', 'acc imu data-y', 'acc imu data-z', ...
                        'gyro rotated gravity data-x', 'gyro rotated gravity data-y',  ...
                        'gyro rotated gravity data-z', 'Location','best')
                    if best_arg(1)~=1 
                        title(['iter = ', num2str(i), ' | elevation error = ', ...
                            num2str(obj.end_gps(3)-p_gen(3,end)), ' <IMPROVED>']) 
                    else 
                        title(['iter = ', num2str(i), ' | elevation error = ', ...
                            num2str(obj.end_gps(3)-p_gen(3,end)), ' <No change>']) 
                    end 
                    figure(3) 
                    subplot(2,1,1)
                    plot(odo_gen); hold on; plot(odo_data-odo_data(1)); hold off 
                    subplot(2,1,2)
                    v_imu_magn = abs(new_agb(1,j))*sqrt(sum(v.*v,1));
                    v_odo_magn = obj.odo_gain_guess*diff(obj.odometer_max(obj.start_index:obj.end_index))...
                        *obj.sampling_frequency/obj.downsampling; 
                    plot(v_imu_magn); hold on; plot(v_odo_magn,'-.'); hold off 
                    pause(0.1) 
                end 

                % aip return now 
                return_enable = false; 
                if obj.auto_mode 
                    if (i-auto_tuning_start_iter+1)>=obj.auto_inputs.S6.breaking_iter 
                        try getcsv_venop(obj.auto_inputs.path_suffix, obj,odo_gen,p_gen,q,v,odo_all,w_all); getcsv_venop_using_refdata_forS6(obj.auto_inputs.path_suffix, obj,odo_gen,p_gen,q,v,odo_all,w_all); catch; try getcsv_venop_using_refdata_forS6(obj.auto_inputs.path_suffix, obj,odo_gen,p_gen,q,v,odo_all,w_all); catch; end; end; 
                        return_enable = true;  
                    end 
                end 

                % save 
                save(['../OUTPUT', obj.auto_inputs.path_suffix, '/best_agbgb_unkwn_dT_vel_scld.mat'], 'agb_now2', 'grad_bounds')  
                if mod(i,eps_ifactr)==0 || return_enable 
                    fname = [['../OUTPUT', obj.auto_inputs.path_suffix, '/best_agbgb_unkwn_dT_vel_scld eps '],num2str(eps_factr),'^',num2str(ceil(i/eps_ifactr)-1)]; 
                    save([fname,'.mat'], 'agb_now2', 'epsilon', 'grad_bounds') 
                    saveas(1,[fname,'.png']); saveas(2,[fname,'_imu.png']) 
                    saveas(3,[fname,'_odo.png']) 
                    saveas(1,[fname,'.fig']); saveas(2,[fname,'_imu.fig']) 
                    saveas(3,[fname,'_odo.fig']) 
                    save(['../OUTPUT', obj.auto_inputs.path_suffix, '/last_manual_settings.mat'], 'Q', 'Div_odo', 'agb_now2', 'epsilon', 'p_gen', 'grad_bounds')  
                    %
                    epsilon = eps_factr*epsilon;  
                    % 
                    start_iter = i+1; 
                    save(['../OUTPUT', obj.auto_inputs.path_suffix, '/to_continue_unkwn_dT_vel_scld.mat'], 'agb_now2', 'start_iter', 'grad_bounds')  
                    lag_vals = obj.lagrngns; 
                    save(['../OUTPUT', obj.auto_inputs.path_suffix, '/lagrangians.mat'],'lag_vals'); 
                    disp('Pause here if needed!'); try getcsv_venop(obj.auto_inputs.path_suffix, obj,odo_gen,p_gen,q,v,odo_all,w_all); getcsv_venop_using_refdata_forS6(obj.auto_inputs.path_suffix, obj,odo_gen,p_gen,q,v,odo_all,w_all); catch; try getcsv_venop_using_refdata_forS6(obj.auto_inputs.path_suffix, obj,odo_gen,p_gen,q,v,odo_all,w_all); catch; end; end
                end 

                % Sub-step 2e: Progres bar 
                percent_done = i*100/max_steps; 
                
                if obj.auto_inputs.en_plot(i); clc; disp(['Progress: <', repmat('||',1,floor(percent_done/3 )), '> ', num2str(percent_done), ' % ']); end  

                if obj.auto_mode 
                    if return_enable 
                        disp('Its over in auto_tuning!') 
                        save(['../OUTPUT', obj.auto_inputs.path_suffix, '/auto_outputs.mat'],'agb_now2','q_dot','q','v_dot','v',...
                            'p_gen','odo_gen','acc_generated_body','odo_all','w_all') 
                        return 
                    end 
                    if mod(i-auto_tuning_start_iter+1,obj.auto_inputs.S6.buzzer_on_iter)==0 
                        sound(sin(2*pi*2000*(0:0.5/8192:1))) 
                        % manual return 
                        return_now = false; 
                        warning('Manually break the code HERE! <--') 
                        % execute: return_now = true; 
                        if return_now 
                            return 
                        end 
                    end 
                end 
            end 
            
            %% Step 2: Render environment and IMU device best trajectory 
            figure(1) 
            % Create IMU object 
            obj.imu_device_obj = imu_device(obj.start_gps,orient_quat); 
            obj.show_markers_geoplot(); 
            obj.imu_device_obj.generate_traj_ode(acc,usegyrodata*gyr,obj.timepoints/testf); 
            obj.imu_device_obj.reset_state(); 
            obj.imu_device_obj.set_diag_gains(obj.best_gain); 
            obj.imu_device_obj.set_init_orient(orient_now/norm(orient_now)); 
            obj.imu_device_obj.generate_traj_ode(acc,usegyrodata*gyr,obj.timepoints/testf); 
            hold on 
            obj.imu_device_obj.geoplot_traj(); 
            hold off 
            
            %% Step 5: Print 
            disp('Started at location: ') 
            disp(obj.imu_device_obj.traj_table(1,2:4)) 
            disp('Now at location: ') 
            disp(obj.imu_device_obj.traj_table(end,2:4)) 
            disp('True end at location: ') 
            disp(obj.end_gps) 
            disp('Started at orientation: ') 
            disp(obj.imu_device_obj.traj_table(1,5:8)) 
            disp('Now at orientation: ') 
            disp(obj.imu_device_obj.traj_table(end,5:8)) 
            
            %% Final step: 
            disp('  ') 
            disp('<<<< All STEPS completed! >>>>') 
            if pause_dbug_fcn3(); keyboard; end; clc 
        end 
        function S6b_mbf_mnfld_dyn_unkwn_smple_vel_scaled_odovelcst_gd_lagr(obj) 
            obj.init_lagrangians(); 

            figure(1) 
            clf 
            pause(0.1) 
            figure(2) 
            clf 
            pause(0.1) 
            figure(3) 
            clf 
            pause(0.1) 
            %% Step 1: testingv 
            testf = 50; 
            usegyrodata = 1; 
            % theta = rand*pi; 
            % vec = randn(3,1); 
            % orient_quat = [cos(theta/2);sin(theta/2)*vec/norm(vec)]; 
            max_steps = 4000; 

            % Initialization 
            theta = -2.3*pi/4; 
            vec = [0;0;1]; 
            orient_quat = [cos(theta/2);sin(theta/2)*vec/norm(vec)]; 
            
            %% Step 3: Sort data into control singals 
            len_data = length(obj.datapoints(1,:)); 
            disp(['Length of dataset = ', num2str(len_data)]) 
            gyr = obj.datapoints(1:3,1:min(len_data,end))'; 
            acc = obj.datapoints(4:6,1:min(len_data,end))'; 

            % Load 
            try 
                load(['../OUTPUT', obj.auto_inputs.path_suffix, '/to_continue_unkwn_dT.mat']) 
                [~] = agb_now2; 
            catch 
                % init of tuning parameters 
                dT0 = 10/obj.sampling_frequency; % dT0 = (obj.downsampling/10)/obj.sampling_frequency; % % dT0 = obj.downsampling/obj.sampling_frequency; 
                agb_now2 = [1;1;1;1;0;0;0;1;1;1;0;0;0;0;0;0;0;0;0;0;dT0]; % odo_gain, (imu gains, bias) X 2, q0  
            end 
            
            %% Step 4: Optimize the angle, gains and bias 
            number_of_directions = 50; 
            %             old_grad_bounds = 1e-1*diag([1e-2,1e-3*ones(1,3),1e2*[1e-5,1e-5,1e-5],...
            %                 1e-3*ones(1,3),1e2*[1e-5,1e-5,1e-5],1e-2*ones(1,4),1e-2*ones(1,3)]); %,1e7*1e-6]); 
            grad_bounds = 1e-2*diag([1e-2,1e-3*ones(1,3),1e2*[1e-5,1e-5,1e-5],...
                1e-3*ones(1,3),1e-2*[1e-5,1e-5,1e-5],1e-3*ones(1,4),1e-1*ones(1,3),...
                1e-4]); %,1e7*1e-6]); 
            % Q = diag([1e6,1e6,1e-5]); % weight on the norm of final state 
            Q = diag([2e7,2e7,1e-3]); % 1km error x-y plane & z axis produces ~1e3 
            Div_odo = 5e5; 
            length_of_gain_vector = length(grad_bounds); 
            accleration_factor = 0.4; 
            eps_factr = 0.995; 
            eps_ifactr = 40; 
            epsilon = eps_factr^0; % 1 --> generated q  | 0 --> q from gyro data 
            try % test epsilon=0 
%                 [~] = uncomment_to_disable; 
                epsilon = 0; 
                warning('epsilon is set as ZERO! ') 
            catch err
                disp(newline)
                warning('IGNORED ERROR WARNING::')
                warning(getReport(err,'extended'));
                disp(newline)
            end
            % for dynamics 
            indices = obj.start_index:obj.end_index; 
            odo_all = obj.odo_gain_guess*repmat([diff(obj.odometer_max(indices)')', 0],3,1); 
            w_all = diag(obj.best_gain(4:end))*obj.all_datapoints(1:3,indices); 
            odo_data = obj.get_odometer_distance(indices); 
            % C_q = @(q) quat2rotm(q'); 
            noindices = length(indices); 
            % S_w = @(w) [0,-w(1),-w(2),-w(3);w(1),0,w(3),-w(2);w(2),-w(3),0,w(1);w(3),w(2),-w(1),0]; 
            % G_matrix = @(p) diag([(180/pi)/(obj.north_radius_of_earth + p(3)), ...
            %     -(180/pi)/((obj.east_radius_of_earth + p(3))*cosd(p(1))), 1]); % Lat Lon Up 
            % 
            try 
                load(['../OUTPUT', obj.auto_inputs.path_suffix, '/to_continue_unkwn_dT_vel_scld.mat']) 
                if epsilon~=0; epsilon = eps_factr^floor(start_iter/eps_ifactr); end 
            catch 
                start_iter = 1; 
            end 
            [f,g,h,h_ext,f_guess,g_guess,h_guess,h_ext_guess,A,B,C,C_ext,... % get_full_dynamics_manifold
                n_omega_ie,n_omega_en,Sx,Qx,C_nb,gl,G_func,f_s,f_p,q_gen,f_q,f_v,f_sns] ...
                = obj.get_full_dynamics_manifold_unknown_sampling_vel_scaled(); 
            
            % perturbation check 
            stvar_name = {'Velocity gain 4 odoadjust','Accel-x gain','Accel-y gain','Accel-z gain','Accel-x bias','Accel-y bias','Accel-z bias',...
                'Gyro-x gain','Gyro-y gain','Gyro-z gain','Gyro-x bias','Gyro-y bias','Gyro-z bias','Init Quaternion-0',...
                'Init Quaternion-x','Init Quaternion-y','Init Quaternion-z','Init Velocity-x','Init Velocity-y','Init Velocity-z','Sampling Time'}; 
            if obj.auto_mode 
                en_grad_chk = 1; 
            else 
                en_grad_chk = input('Press `1` to enable graident tuning (press ENTER to skip): '); 
            end 
            if ~isempty(en_grad_chk) % check grad_bounds 
%                 [~,~,~,v,p_gen_basecase] = obj.get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld(agb_now2,...
%                     epsilon,indices,odo_all,w_all,f,g,C_nb); 
                [~,~,~,v,p_gen_basecase] = get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld_mex(agb_now2,...
                    indices,odo_all,w_all,obj.downsampling,obj.start_gps,...
                    obj.best_initial_orientation);
                final_state_basecase = p_gen_basecase(:,end); 
                report_perturbation = nan(4,length_of_gain_vector); 
                report_perturbation(1,1) = 0; 
                for i=1:length_of_gain_vector 
                    new_agb_now2 = agb_now2; 
                    for j=0:number_of_directions 
                        new_agb_now2(i) = new_agb_now2(i) + (3^j)*accleration_factor*grad_bounds(i,i); 
%                         [~,~,~,~,p_gen,odo_gen] = obj.get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld(new_agb_now2,...
%                             epsilon,indices,odo_all,w_all,f,g,C_nb); 
                        [~,~,~,~,p_gen,odo_gen] = get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld_mex(new_agb_now2,...
                            indices,odo_all,w_all,obj.downsampling,obj.start_gps,...
                            obj.best_initial_orientation);
                        final_state_now = p_gen(:,end); 
                        report_perturbation(2:4,i) = (final_state_now-final_state_basecase).*diag(Q).*(final_state_now-final_state_basecase); 
%                         figure(1) % <-- testing 
%                         geoplot(p_gen(1,1)',p_gen(2,1)','x'); 
%                         hold on 
%                         geoplot(p_gen(1,:)',p_gen(2,:)'); 
%                         geoplot(p_gen_basecase(1,:)',p_gen_basecase(2,:)','-.'); 
%                         geoplot(obj.end_gps(1),obj.end_gps(2),'o'); 
%                         hold off 
%                         y_fulltraj = [transpose(odo_data(1)+odo_gen)/obj.odo_gain_guess,p_gen']; 
%                         [gstart,gfinish,~,gmrkd] = obj.odo_marker_hit(y_fulltraj);
%                         obj.marker_projection(gstart,gfinish,gmrkd); 
%                         title(['Tuning parameter: ', stvar_name{i}]) 
%                         pause 
                        if norm(report_perturbation(2:4,i))>1 % approx 1 meter in x-y OR z direction 
                            report_perturbation(1,i) = j; 
                            figure(1) % <-- testing 
                            geoplot(p_gen(1,1)',p_gen(2,1)','x'); 
                            hold on 
                            geoplot(p_gen(1,:)',p_gen(2,:)'); 
                            geoplot(p_gen_basecase(1,:)',p_gen_basecase(2,:)','-.'); 
                            geoplot(obj.end_gps(1),obj.end_gps(2),'o'); 
                            hold off 
                            y_fulltraj = [transpose(odo_data(1)+odo_gen)/obj.odo_gain_guess,p_gen']; 
                            [gstart,gfinish,~,gmrkd] = obj.odo_marker_hit(y_fulltraj);
                            obj.marker_NW_distance(gstart,gfinish,gmrkd); 
                            title(['Tuning parameter: ', stvar_name{i}]) 
                            pause(0.1) 
                            break 
                        end 
                    end 
                end 
                disp('Perturbation report: ') 
                disp(report_perturbation) 
                disp('Old grad bounds: ') 
                disp(diag(grad_bounds)') 
                disp('Modified grad bounds: ') 
                disp((3.^report_perturbation(1,:)).*diag(grad_bounds)') 
                if obj.auto_mode 
                    sentvty = obj.auto_inputs.S6.sentvty; 
                else 
                    sentvty = input('Enter sensitivity of graidents (press ENTER to skip): '); 
                end 
                if ~isempty(sentvty) % modify grad_bounds 
                    grad_bounds = sentvty*diag(3.^report_perturbation(1,:))*grad_bounds; 
                end 
            end 
            % disp('Press any key to continue ... ') 
            % pause 
            %             if sum(isnan(report_perturbation(1,:)))>0 
            %                 warning('Too small graidents! ') 
            %                 report_perturbation(1,isnan(report_perturbation(1,:))) = number_of_directions; 
            %             end 

            % main loop 
            no_of_elites = floor((50/100)*number_of_directions); 
            best_grad_bound_so_far = zeros(length_of_gain_vector,no_of_elites); 
            auto_tuning_start_iter = start_iter; 
            for i=start_iter:max_steps 
                % Sub-step 2a: Choose gradients at uniformly random 
                random_gain_grads = [zeros(length_of_gain_vector,1), best_grad_bound_so_far, ...
                    2*grad_bounds*(0.5-rand(length_of_gain_vector, number_of_directions-no_of_elites-1))]; 

                % Sub-step 2b: Find new points along the random gradients 
                %                 accleration_factor = 1/i; 
                new_agb = repmat(agb_now2,1,number_of_directions) + accleration_factor*random_gain_grads; 

                % Sub-step 2c: Evaluate end gps point for all new states 
                all_costs = inf(1,number_of_directions); 
                for j=1:number_of_directions 
                    % load parameters for forward run 
                    %                     [~,~,~,v,p_gen,odo_gen] = obj.get_full_dynamical_trajectory(new_agb(:,j),...
                    %                         epsilon,indices,odo_all,w_all); 
%                     [~,~,~,v,p_gen,odo_gen] = obj.get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld(new_agb(:,j),...
%                         epsilon,indices,odo_all,w_all,f,g,C_nb); 
                    [~,~,~,v,p_gen,odo_gen] = get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld_mex(new_agb(:,j),...
                        indices,odo_all,w_all,obj.downsampling,obj.start_gps,...
                        obj.best_initial_orientation);
                    v_imu_magn = abs(new_agb(1,j))*sqrt(sum(v.*v,1)); 
                    [marker_costs,end_point_cost,straightning_cost,odo_cost,vel_odo_cost] ...
                        = obj.get_costs_mrkd_S6b_odovelcst_lagr(odo_gen,p_gen,v_imu_magn,odo_data,noindices); 
                    all_costs(1,j) = marker_costs + end_point_cost + straightning_cost ...
                        + odo_cost + 0.2*vel_odo_cost; 
                    % start-1 < for testing > 
%                     figure(1) 
%                     geoplot(p_gen(1,1)',p_gen(2,1)','x'); 
%                     hold on 
%                     geoplot(p_gen(1,:)',p_gen(2,:)'); 
%                     geoplot(obj.end_gps(1),obj.end_gps(2),'o'); 
%                     hold off 
%                     title(['i = ', num2str(i), ' | elevation error = ', ...
%                         num2str(obj.end_gps(3)-p_gen(3,end))]) 
%                     figure(2) 
%                     clf; stem(all_costs); hold on; 
%                     plot(min(all_costs)*ones(1,number_of_directions), 'g--'); 
%                     plot(all_costs(1)*ones(1,number_of_directions), '-'); 
%                     hold off 
%                     figure(3) 
%                     plot(odo_gen); hold on; plot(odo_data-odo_data(1)); hold off 
%                     % disp(all_costs(1,1:j)) 
%                     % disp(straightning_cost) 
%                     disp('error components = ') 
%                     disp(transpose((final_state(1:3)-obj.end_gps').*diag(Q).*(final_state(1:3)-obj.end_gps'))) 
%                     disp(['end_cost = ', num2str(end_point_cost), ' & strtn_cost = ', num2str(straightning_cost), ...
%                         ' & odo_cost = ', num2str(odo_cost)]) 
                    % end-1 < for testing >
                end 

                % Sub-step 2d: Choose the best and set it as new gain 
                [~,best_arg] = sort(all_costs); 
                agb_now2 = new_agb(:,best_arg(1)); 
                best_grad_bound_so_far = random_gain_grads(:,best_arg(1:no_of_elites)); 
                best_grad_bound_so_far = obj.elite_selection(best_grad_bound_so_far,no_of_elites,...
                    [25,25,nan],0.5); % [old elites, scaled elites, crossover] 
                % see plots 
                %                 [~,~,~,v,p_gen,odo_gen] = obj.get_full_dynamical_trajectory(agb_now2,...
                %                     epsilon,indices,odo_all,w_all); 
%                 [q_dot,q,v_dot,v,p_gen,odo_gen,acc_generated_body] = obj.get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld(agb_now2,...
%                     epsilon,indices,odo_all,w_all,f,g,C_nb); 
                [q_dot,q,v_dot,v,p_gen,odo_gen,acc_generated_body] = get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld_mex(agb_now2,...
                    indices,odo_all,w_all,obj.downsampling,obj.start_gps,...
                    obj.best_initial_orientation);
                final_state = p_gen(:,end); 
                disp((final_state(1:3)-obj.end_gps').*diag(Q).*(final_state(1:3)-obj.end_gps')) 
                % lagrangian update 
                v_imu_magn = abs(agb_now2(1))*sqrt(sum(v.*v,1)); 
                obj.get_costs_mrkd_S6b_odovelcst_lagr(odo_gen,p_gen,v_imu_magn,odo_data,noindices,true); 
                
                if obj.auto_inputs.en_plot(i)
                    figure(1) % <-- testing 
                    geoplot(p_gen(1,1)',p_gen(2,1)','x'); 
                    hold on 
                    geoplot(p_gen(1,:)',p_gen(2,:)'); 
                    geoplot(obj.end_gps(1),obj.end_gps(2),'o'); 
                    hold off 
                    y_fulltraj = [transpose(odo_data(1)+odo_gen)/obj.odo_gain_guess,p_gen']; 
                    [gstart,gfinish,~,gmrkd] = obj.odo_marker_hit(y_fulltraj);
                    obj.marker_NW_distance(gstart,gfinish,gmrkd);
                    title(['vel mismatch = ',num2str(vel_odo_cost)])
                    figure(2) 
                    plot(odo_all') 
                    hold on 
                    plot(acc_generated_body') 
                    hold off 
                    xlabel('index --> ') 
                    ylabel('Acceleration --> ') 
                    legend('acc imu data-x', 'acc imu data-y', 'acc imu data-z', ...
                        'gyro rotated gravity data-x', 'gyro rotated gravity data-y',  ...
                        'gyro rotated gravity data-z', 'Location','best')
                    if best_arg(1)~=1 
                        title(['iter = ', num2str(i), ' | elevation error = ', ...
                            num2str(obj.end_gps(3)-p_gen(3,end)), ' <IMPROVED>']) 
                    else 
                        title(['iter = ', num2str(i), ' | elevation error = ', ...
                            num2str(obj.end_gps(3)-p_gen(3,end)), ' <No change>']) 
                    end 
                    figure(3) 
                    subplot(2,1,1)
                    plot(odo_gen); hold on; plot(odo_data-odo_data(1)); hold off 
                    subplot(2,1,2)
                    v_imu_magn = abs(new_agb(1,j))*sqrt(sum(v.*v,1));
                    v_odo_magn = obj.odo_gain_guess*diff(obj.odometer_max(obj.start_index:obj.end_index))...
                        *obj.sampling_frequency/obj.downsampling; 
                    plot(v_imu_magn); hold on; plot(v_odo_magn,'-.'); hold off 
                    pause(0.1) 
                end 

                % aip return now 
                return_enable = false; 
                if obj.auto_mode 
                    if (i-auto_tuning_start_iter+1)>=obj.auto_inputs.S6.breaking_iter 
                        try getcsv_venop(obj.auto_inputs.path_suffix, obj,odo_gen,p_gen,q,v,odo_all,w_all); getcsv_venop_using_refdata_forS6(obj.auto_inputs.path_suffix, obj,odo_gen,p_gen,q,v,odo_all,w_all); catch; try getcsv_venop_using_refdata_forS6(obj.auto_inputs.path_suffix, obj,odo_gen,p_gen,q,v,odo_all,w_all); catch; end; end; 
                        return_enable = true;  
                    end 
                end 

                % save 
                save(['../OUTPUT', obj.auto_inputs.path_suffix, '/best_agbgb_unkwn_dT_vel_scld.mat'], 'agb_now2', 'grad_bounds')  
                if mod(i,eps_ifactr)==0 || return_enable 
                    fname = [['../OUTPUT', obj.auto_inputs.path_suffix, '/best_agbgb_unkwn_dT_vel_scld eps '],num2str(eps_factr),'^',num2str(ceil(i/eps_ifactr)-1)]; 
                    save([fname,'.mat'], 'agb_now2', 'epsilon', 'grad_bounds') 
                    saveas(1,[fname,'.png']); saveas(2,[fname,'_imu.png']) 
                    saveas(3,[fname,'_odo.png']) 
                    saveas(1,[fname,'.fig']); saveas(2,[fname,'_imu.fig']) 
                    saveas(3,[fname,'_odo.fig']) 
                    save(['../OUTPUT', obj.auto_inputs.path_suffix, '/last_manual_settings.mat'], 'Q', 'Div_odo', 'agb_now2', 'epsilon', 'p_gen', 'grad_bounds')  
                    %
                    epsilon = eps_factr*epsilon;  
                    % 
                    start_iter = i+1; 
                    save(['../OUTPUT', obj.auto_inputs.path_suffix, '/to_continue_unkwn_dT_vel_scld.mat'], 'agb_now2', 'start_iter', 'grad_bounds')  
                    lag_vals = obj.lagrngns; 
                    save(['../OUTPUT', obj.auto_inputs.path_suffix, '/lagrangians.mat'],'lag_vals'); 
                    disp('Pause here if needed!'); try getcsv_venop(obj.auto_inputs.path_suffix, obj,odo_gen,p_gen,q,v,odo_all,w_all); getcsv_venop_using_refdata_forS6(obj.auto_inputs.path_suffix, obj,odo_gen,p_gen,q,v,odo_all,w_all); catch; try getcsv_venop_using_refdata_forS6(obj.auto_inputs.path_suffix, obj,odo_gen,p_gen,q,v,odo_all,w_all); catch; end; end
                end 

                % Sub-step 2e: Progres bar 
                percent_done = i*100/max_steps; 
                
                if obj.auto_inputs.en_plot(i); clc; disp(['Progress: <', repmat('||',1,floor(percent_done/3 )), '> ', num2str(percent_done), ' % ']); end  

                if obj.auto_mode 
                    if return_enable 
                        disp('Its over in auto_tuning!') 
                        save(['../OUTPUT', obj.auto_inputs.path_suffix, '/auto_outputs.mat'],'agb_now2','q_dot','q','v_dot','v',...
                            'p_gen','odo_gen','acc_generated_body','odo_all','w_all') 
                        return 
                    end 
                    if mod(i-auto_tuning_start_iter+1,obj.auto_inputs.S6.buzzer_on_iter)==0 
                        sound(sin(2*pi*2000*(0:0.5/8192:1))) 
                        % manual return 
                        return_now = false; 
                        warning('Manually break the code HERE! <--') 
                        % execute: return_now = true; 
                        if return_now 
                            return 
                        end 
                    end 
                end 
            end 
            
            %% Step 2: Render environment and IMU device best trajectory 
            figure(1) 
            % Create IMU object 
            obj.imu_device_obj = imu_device(obj.start_gps,orient_quat); 
            obj.show_markers_geoplot(); 
            obj.imu_device_obj.generate_traj_ode(acc,usegyrodata*gyr,obj.timepoints/testf); 
            obj.imu_device_obj.reset_state(); 
            obj.imu_device_obj.set_diag_gains(obj.best_gain); 
            obj.imu_device_obj.set_init_orient(orient_now/norm(orient_now)); 
            obj.imu_device_obj.generate_traj_ode(acc,usegyrodata*gyr,obj.timepoints/testf); 
            hold on 
            obj.imu_device_obj.geoplot_traj(); 
            hold off 
            
            %% Step 5: Print 
            disp('Started at location: ') 
            disp(obj.imu_device_obj.traj_table(1,2:4)) 
            disp('Now at location: ') 
            disp(obj.imu_device_obj.traj_table(end,2:4)) 
            disp('True end at location: ') 
            disp(obj.end_gps) 
            disp('Started at orientation: ') 
            disp(obj.imu_device_obj.traj_table(1,5:8)) 
            disp('Now at orientation: ') 
            disp(obj.imu_device_obj.traj_table(end,5:8)) 
            
            %% Final step: 
            disp('  ') 
            disp('<<<< All STEPS completed! >>>>') 
            if pause_dbug_fcn3(); keyboard; end; clc 
        end 
        function S6b_mbf_mnfld_dyn_unkwn_smple_vscl_ovcst_vscst_gd_lagr(obj) 
            obj.init_lagrangians(); 

            figure(1) 
            clf 
            pause(0.1) 
            figure(2) 
            clf 
            pause(0.1) 
            figure(3) 
            clf 
            pause(0.1) 
            %% Step 1: testingv 
            testf = 50; 
            usegyrodata = 1; 
            % theta = rand*pi; 
            % vec = randn(3,1); 
            % orient_quat = [cos(theta/2);sin(theta/2)*vec/norm(vec)]; 
            max_steps = 4000; 

            % Initialization 
            theta = -2.3*pi/4; 
            vec = [0;0;1]; 
            orient_quat = [cos(theta/2);sin(theta/2)*vec/norm(vec)]; 
            
            %% Step 3: Sort data into control singals 
            len_data = length(obj.datapoints(1,:)); 
            disp(['Length of dataset = ', num2str(len_data)]) 
            gyr = obj.datapoints(1:3,1:min(len_data,end))'; 
            acc = obj.datapoints(4:6,1:min(len_data,end))'; 

            % Load 
            try 
                load(['../OUTPUT', obj.auto_inputs.path_suffix, '/to_continue_unkwn_dT.mat']) 
                [~] = agb_now2; 
            catch 
                % init of tuning parameters 
                dT0 = 10/obj.sampling_frequency; % dT0 = (obj.downsampling/10)/obj.sampling_frequency; % % dT0 = obj.downsampling/obj.sampling_frequency; 
                agb_now2 = [1;1;1;1;0;0;0;1;1;1;0;0;0;0;0;0;0;0;0;0;dT0]; % odo_gain, (imu gains, bias) X 2, q0  
            end 
            
            %% Step 4: Optimize the angle, gains and bias 
            number_of_directions = 50; 
            %             old_grad_bounds = 1e-1*diag([1e-2,1e-3*ones(1,3),1e2*[1e-5,1e-5,1e-5],...
            %                 1e-3*ones(1,3),1e2*[1e-5,1e-5,1e-5],1e-2*ones(1,4),1e-2*ones(1,3)]); %,1e7*1e-6]); 
            grad_bounds = 1e-2*diag([1e-2,1e-3*ones(1,3),1e2*[1e-5,1e-5,1e-5],...
                1e-3*ones(1,3),1e-2*[1e-5,1e-5,1e-5],1e-3*ones(1,4),1e-1*ones(1,3),...
                1e-4]); %,1e7*1e-6]); 
            % Q = diag([1e6,1e6,1e-5]); % weight on the norm of final state 
            Q = diag([2e7,2e7,1e-3]); % 1km error x-y plane & z axis produces ~1e3 
            Div_odo = 5e5; 
            length_of_gain_vector = length(grad_bounds); 
            accleration_factor = 0.4; 
            eps_factr = 0.995; 
            eps_ifactr = 40; 
            epsilon = eps_factr^0; % 1 --> generated q  | 0 --> q from gyro data 
            try % test epsilon=0 
%                 [~] = uncomment_to_disable; 
                epsilon = 0; 
                warning('epsilon is set as ZERO! ') 
            catch err
                disp(newline)
                warning('IGNORED ERROR WARNING::')
                warning(getReport(err,'extended'));
                disp(newline)
            end
            % for dynamics 
            indices = obj.start_index:obj.end_index; 
            odo_all = obj.odo_gain_guess*repmat([diff(obj.odometer_max(indices)')', 0],3,1); 
            w_all = diag(obj.best_gain(4:end))*obj.all_datapoints(1:3,indices); 
            odo_data = obj.get_odometer_distance(indices); 
            % C_q = @(q) quat2rotm(q'); 
            noindices = length(indices); 
            % S_w = @(w) [0,-w(1),-w(2),-w(3);w(1),0,w(3),-w(2);w(2),-w(3),0,w(1);w(3),w(2),-w(1),0]; 
            % G_matrix = @(p) diag([(180/pi)/(obj.north_radius_of_earth + p(3)), ...
            %     -(180/pi)/((obj.east_radius_of_earth + p(3))*cosd(p(1))), 1]); % Lat Lon Up 
            % 
            try 
                load(['../OUTPUT', obj.auto_inputs.path_suffix, '/to_continue_unkwn_dT_vel_scld.mat']) 
                if epsilon~=0; epsilon = eps_factr^floor(start_iter/eps_ifactr); end 
            catch 
                start_iter = 1; 
            end 
            [f,g,h,h_ext,f_guess,g_guess,h_guess,h_ext_guess,A,B,C,C_ext,... % get_full_dynamics_manifold
                n_omega_ie,n_omega_en,Sx,Qx,C_nb,gl,G_func,f_s,f_p,q_gen,f_q,f_v,f_sns] ...
                = obj.get_full_dynamics_manifold_unknown_sampling_vel_scaled(); 
            
            % perturbation check 
            stvar_name = {'Velocity gain 4 odoadjust','Accel-x gain','Accel-y gain','Accel-z gain','Accel-x bias','Accel-y bias','Accel-z bias',...
                'Gyro-x gain','Gyro-y gain','Gyro-z gain','Gyro-x bias','Gyro-y bias','Gyro-z bias','Init Quaternion-0',...
                'Init Quaternion-x','Init Quaternion-y','Init Quaternion-z','Init Velocity-x','Init Velocity-y','Init Velocity-z','Sampling Time'}; 
            if obj.auto_mode 
                en_grad_chk = 1; 
            else 
                en_grad_chk = input('Press `1` to enable graident tuning (press ENTER to skip): '); 
            end 
            if ~isempty(en_grad_chk) % check grad_bounds 
%                 [~,~,~,v,p_gen_basecase] = obj.get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld(agb_now2,...
%                     epsilon,indices,odo_all,w_all,f,g,C_nb); 
                [~,~,~,v,p_gen_basecase] = get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld_mex(agb_now2,...
                    indices,odo_all,w_all,obj.downsampling,obj.start_gps,...
                    obj.best_initial_orientation);
                final_state_basecase = p_gen_basecase(:,end); 
                report_perturbation = nan(4,length_of_gain_vector); 
                report_perturbation(1,1) = 0; 
                for i=1:length_of_gain_vector 
                    new_agb_now2 = agb_now2; 
                    for j=0:number_of_directions 
                        new_agb_now2(i) = new_agb_now2(i) + (3^j)*accleration_factor*grad_bounds(i,i); 
%                         [~,~,~,~,p_gen,odo_gen] = obj.get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld(new_agb_now2,...
%                             epsilon,indices,odo_all,w_all,f,g,C_nb); 
                        [~,~,~,~,p_gen,odo_gen] = get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld_mex(new_agb_now2,...
                            indices,odo_all,w_all,obj.downsampling,obj.start_gps,...
                            obj.best_initial_orientation);
                        final_state_now = p_gen(:,end); 
                        report_perturbation(2:4,i) = (final_state_now-final_state_basecase).*diag(Q).*(final_state_now-final_state_basecase); 
%                         figure(1) % <-- testing 
%                         geoplot(p_gen(1,1)',p_gen(2,1)','x'); 
%                         hold on 
%                         geoplot(p_gen(1,:)',p_gen(2,:)'); 
%                         geoplot(p_gen_basecase(1,:)',p_gen_basecase(2,:)','-.'); 
%                         geoplot(obj.end_gps(1),obj.end_gps(2),'o'); 
%                         hold off 
%                         y_fulltraj = [transpose(odo_data(1)+odo_gen)/obj.odo_gain_guess,p_gen']; 
%                         [gstart,gfinish,~,gmrkd] = obj.odo_marker_hit(y_fulltraj);
%                         obj.marker_projection(gstart,gfinish,gmrkd); 
%                         title(['Tuning parameter: ', stvar_name{i}]) 
%                         pause 
                        if norm(report_perturbation(2:4,i))>1 % approx 1 meter in x-y OR z direction 
                            report_perturbation(1,i) = j; 
                            figure(1) % <-- testing 
                            geoplot(p_gen(1,1)',p_gen(2,1)','x'); 
                            hold on 
                            geoplot(p_gen(1,:)',p_gen(2,:)'); 
                            geoplot(p_gen_basecase(1,:)',p_gen_basecase(2,:)','-.'); 
                            geoplot(obj.end_gps(1),obj.end_gps(2),'o'); 
                            hold off 
                            y_fulltraj = [transpose(odo_data(1)+odo_gen)/obj.odo_gain_guess,p_gen']; 
                            [gstart,gfinish,~,gmrkd] = obj.odo_marker_hit(y_fulltraj);
                            obj.marker_NW_distance(gstart,gfinish,gmrkd); 
                            title(['Tuning parameter: ', stvar_name{i}]) 
                            pause(0.1) 
                            break 
                        end 
                    end 
                end 
                disp('Perturbation report: ') 
                disp(report_perturbation) 
                disp('Old grad bounds: ') 
                disp(diag(grad_bounds)') 
                disp('Modified grad bounds: ') 
                disp((3.^report_perturbation(1,:)).*diag(grad_bounds)') 
                if obj.auto_mode 
                    sentvty = obj.auto_inputs.S6.sentvty; 
                else 
                    sentvty = input('Enter sensitivity of graidents (press ENTER to skip): '); 
                end 
                if ~isempty(sentvty) % modify grad_bounds 
                    grad_bounds = sentvty*diag(3.^report_perturbation(1,:))*grad_bounds; 
                end 
            end 
            % disp('Press any key to continue ... ') 
            % pause 
            %             if sum(isnan(report_perturbation(1,:)))>0 
            %                 warning('Too small graidents! ') 
            %                 report_perturbation(1,isnan(report_perturbation(1,:))) = number_of_directions; 
            %             end 

            % main loop 
            no_of_elites = floor((50/100)*number_of_directions); 
            best_grad_bound_so_far = zeros(length_of_gain_vector,no_of_elites); 
            auto_tuning_start_iter = start_iter; 
            for i=start_iter:max_steps 
                % Sub-step 2a: Choose gradients at uniformly random 
                random_gain_grads = [zeros(length_of_gain_vector,1), best_grad_bound_so_far, ...
                    2*grad_bounds*(0.5-rand(length_of_gain_vector, number_of_directions-no_of_elites-1))]; 

                % Sub-step 2b: Find new points along the random gradients 
                %                 accleration_factor = 1/i; 
                new_agb = repmat(agb_now2,1,number_of_directions) + accleration_factor*random_gain_grads; 

                % Sub-step 2c: Evaluate end gps point for all new states 
                all_costs = inf(1,number_of_directions); 
                for j=1:number_of_directions 
                    % load parameters for forward run 
                    %                     [~,~,~,v,p_gen,odo_gen] = obj.get_full_dynamical_trajectory(new_agb(:,j),...
                    %                         epsilon,indices,odo_all,w_all); 
%                     [~,~,~,v,p_gen,odo_gen] = obj.get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld(new_agb(:,j),...
%                         epsilon,indices,odo_all,w_all,f,g,C_nb); 
                    [~,~,~,v,p_gen,odo_gen] = get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld_mex(new_agb(:,j),...
                        indices,odo_all,w_all,obj.downsampling,obj.start_gps,...
                        obj.best_initial_orientation);
                    v_imu_magn = abs(new_agb(1,j))*sqrt(sum(v.*v,1)); 
                    [marker_costs,end_point_cost,straightning_cost,odo_cost,vel_odo_cost] ...
                        = obj.get_costs_mrkd_S6b_odovelcst_loglagr(odo_gen,p_gen,v_imu_magn,odo_data,noindices, ...
                        new_agb(:,j),false); 
                    all_costs(1,j) = marker_costs + end_point_cost + straightning_cost ...
                        + odo_cost + 0.2*vel_odo_cost; 
                    % start-1 < for testing > 
%                     figure(1) 
%                     geoplot(p_gen(1,1)',p_gen(2,1)','x'); 
%                     hold on 
%                     geoplot(p_gen(1,:)',p_gen(2,:)'); 
%                     geoplot(obj.end_gps(1),obj.end_gps(2),'o'); 
%                     hold off 
%                     title(['i = ', num2str(i), ' | elevation error = ', ...
%                         num2str(obj.end_gps(3)-p_gen(3,end))]) 
%                     figure(2) 
%                     clf; stem(all_costs); hold on; 
%                     plot(min(all_costs)*ones(1,number_of_directions), 'g--'); 
%                     plot(all_costs(1)*ones(1,number_of_directions), '-'); 
%                     hold off 
%                     figure(3) 
%                     plot(odo_gen); hold on; plot(odo_data-odo_data(1)); hold off 
%                     % disp(all_costs(1,1:j)) 
%                     % disp(straightning_cost) 
%                     disp('error components = ') 
%                     disp(transpose((final_state(1:3)-obj.end_gps').*diag(Q).*(final_state(1:3)-obj.end_gps'))) 
%                     disp(['end_cost = ', num2str(end_point_cost), ' & strtn_cost = ', num2str(straightning_cost), ...
%                         ' & odo_cost = ', num2str(odo_cost)]) 
                    % end-1 < for testing >
                end 

                % Sub-step 2d: Choose the best and set it as new gain 
                [~,best_arg] = sort(all_costs); 
                agb_now2 = new_agb(:,best_arg(1)); 
                best_grad_bound_so_far = random_gain_grads(:,best_arg(1:no_of_elites)); 
                best_grad_bound_so_far = obj.elite_selection(best_grad_bound_so_far,no_of_elites,...
                    [25,25,nan],0.5); % [old elites, scaled elites, crossover] 
                % see plots 
                %                 [~,~,~,v,p_gen,odo_gen] = obj.get_full_dynamical_trajectory(agb_now2,...
                %                     epsilon,indices,odo_all,w_all); 
%                 [q_dot,q,v_dot,v,p_gen,odo_gen,acc_generated_body] = obj.get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld(agb_now2,...
%                     epsilon,indices,odo_all,w_all,f,g,C_nb); 
                [q_dot,q,v_dot,v,p_gen,odo_gen,acc_generated_body] = get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld_mex(agb_now2,...
                    indices,odo_all,w_all,obj.downsampling,obj.start_gps,...
                    obj.best_initial_orientation);
                final_state = p_gen(:,end); 
                disp((final_state(1:3)-obj.end_gps').*diag(Q).*(final_state(1:3)-obj.end_gps')) 
                % lagrangian update 
                v_imu_magn = abs(agb_now2(1))*sqrt(sum(v.*v,1)); 
                obj.get_costs_mrkd_S6b_odovelcst_lagr(odo_gen,p_gen,v_imu_magn,odo_data,noindices,agb_now2,true); 
                
                if obj.auto_inputs.en_plot(i)
                    figure(1) % <-- testing 
                    geoplot(p_gen(1,1)',p_gen(2,1)','x'); 
                    hold on 
                    geoplot(p_gen(1,:)',p_gen(2,:)'); 
                    geoplot(obj.end_gps(1),obj.end_gps(2),'o'); 
                    hold off 
                    y_fulltraj = [transpose(odo_data(1)+odo_gen)/obj.odo_gain_guess,p_gen']; 
                    [gstart,gfinish,~,gmrkd] = obj.odo_marker_hit(y_fulltraj);
                    obj.marker_NW_distance(gstart,gfinish,gmrkd);
                    title(['vel mismatch = ',num2str(vel_odo_cost)])
                    figure(2) 
                    plot(odo_all') 
                    hold on 
                    plot(acc_generated_body') 
                    hold off 
                    xlabel('index --> ') 
                    ylabel('Acceleration --> ') 
                    legend('acc imu data-x', 'acc imu data-y', 'acc imu data-z', ...
                        'gyro rotated gravity data-x', 'gyro rotated gravity data-y',  ...
                        'gyro rotated gravity data-z', 'Location','best')
                    if best_arg(1)~=1 
                        title(['iter = ', num2str(i), ' | elevation error = ', ...
                            num2str(obj.end_gps(3)-p_gen(3,end)), ' <IMPROVED>']) 
                    else 
                        title(['iter = ', num2str(i), ' | elevation error = ', ...
                            num2str(obj.end_gps(3)-p_gen(3,end)), ' <No change>']) 
                    end 
                    figure(3) 
                    subplot(2,1,1)
                    plot(odo_gen); hold on; plot(odo_data-odo_data(1)); hold off 
                    subplot(2,1,2)
                    v_imu_magn = abs(new_agb(1,j))*sqrt(sum(v.*v,1));
                    v_odo_magn = obj.odo_gain_guess*diff(obj.odometer_max(obj.start_index:obj.end_index))...
                        *obj.sampling_frequency/obj.downsampling; 
                    plot(v_imu_magn); hold on; plot(v_odo_magn,'-.'); hold off 
                    pause(0.1) 
                end 

                % aip return now 
                return_enable = false; 
                if obj.auto_mode 
                    if (i-auto_tuning_start_iter+1)>=obj.auto_inputs.S6.breaking_iter 
                        try getcsv_venop(obj.auto_inputs.path_suffix, obj,odo_gen,p_gen,q,v,odo_all,w_all); getcsv_venop_using_refdata_forS6(obj.auto_inputs.path_suffix, obj,odo_gen,p_gen,q,v,odo_all,w_all); catch; try getcsv_venop_using_refdata_forS6(obj.auto_inputs.path_suffix, obj,odo_gen,p_gen,q,v,odo_all,w_all); catch; end; end; 
                        return_enable = true;  
                    end 
                end 

                % save 
                save(['../OUTPUT', obj.auto_inputs.path_suffix, '/best_agbgb_unkwn_dT_vel_scld.mat'], 'agb_now2', 'grad_bounds')  
                if mod(i,eps_ifactr)==0 || return_enable 
                    fname = [['../OUTPUT', obj.auto_inputs.path_suffix, '/best_agbgb_unkwn_dT_vel_scld eps '],num2str(eps_factr),'^',num2str(ceil(i/eps_ifactr)-1)]; 
                    save([fname,'.mat'], 'agb_now2', 'epsilon', 'grad_bounds') 
                    saveas(1,[fname,'.png']); saveas(2,[fname,'_imu.png']) 
                    saveas(3,[fname,'_odo.png']) 
                    saveas(1,[fname,'.fig']); saveas(2,[fname,'_imu.fig']) 
                    saveas(3,[fname,'_odo.fig']) 
                    save(['../OUTPUT', obj.auto_inputs.path_suffix, '/last_manual_settings.mat'], 'Q', 'Div_odo', 'agb_now2', 'epsilon', 'p_gen', 'grad_bounds')  
                    %
                    epsilon = eps_factr*epsilon;  
                    % 
                    start_iter = i+1; 
                    save(['../OUTPUT', obj.auto_inputs.path_suffix, '/to_continue_unkwn_dT_vel_scld.mat'], 'agb_now2', 'start_iter', 'grad_bounds')  
                    lag_vals = obj.lagrngns; 
                    save(['../OUTPUT', obj.auto_inputs.path_suffix, '/lagrangians.mat'],'lag_vals'); 
                    disp('Pause here if needed!'); try getcsv_venop(obj.auto_inputs.path_suffix, obj,odo_gen,p_gen,q,v,odo_all,w_all); getcsv_venop_using_refdata_forS6(obj.auto_inputs.path_suffix, obj,odo_gen,p_gen,q,v,odo_all,w_all); catch; try getcsv_venop_using_refdata_forS6(obj.auto_inputs.path_suffix, obj,odo_gen,p_gen,q,v,odo_all,w_all); catch; end; end
                end 

                % Sub-step 2e: Progres bar 
                percent_done = i*100/max_steps; 
                
                if obj.auto_inputs.en_plot(i); clc; disp(['Progress: <', repmat('||',1,floor(percent_done/3 )), '> ', num2str(percent_done), ' % ']); end  

                if obj.auto_mode 
                    if return_enable 
                        disp('Its over in auto_tuning!') 
                        save(['../OUTPUT', obj.auto_inputs.path_suffix, '/auto_outputs.mat'],'agb_now2','q_dot','q','v_dot','v',...
                            'p_gen','odo_gen','acc_generated_body','odo_all','w_all') 
                        return 
                    end 
                    if mod(i-auto_tuning_start_iter+1,obj.auto_inputs.S6.buzzer_on_iter)==0 
                        sound(sin(2*pi*2000*(0:0.5/8192:1))) 
                        % manual return 
                        return_now = false; 
                        warning('Manually break the code HERE! <--') 
                        % execute: return_now = true; 
                        if return_now 
                            return 
                        end 
                    end 
                end 
            end 
            
            %% Step 2: Render environment and IMU device best trajectory 
            figure(1) 
            % Create IMU object 
            obj.imu_device_obj = imu_device(obj.start_gps,orient_quat); 
            obj.show_markers_geoplot(); 
            obj.imu_device_obj.generate_traj_ode(acc,usegyrodata*gyr,obj.timepoints/testf); 
            obj.imu_device_obj.reset_state(); 
            obj.imu_device_obj.set_diag_gains(obj.best_gain); 
            obj.imu_device_obj.set_init_orient(orient_now/norm(orient_now)); 
            obj.imu_device_obj.generate_traj_ode(acc,usegyrodata*gyr,obj.timepoints/testf); 
            hold on 
            obj.imu_device_obj.geoplot_traj(); 
            hold off 
            
            %% Step 5: Print 
            disp('Started at location: ') 
            disp(obj.imu_device_obj.traj_table(1,2:4)) 
            disp('Now at location: ') 
            disp(obj.imu_device_obj.traj_table(end,2:4)) 
            disp('True end at location: ') 
            disp(obj.end_gps) 
            disp('Started at orientation: ') 
            disp(obj.imu_device_obj.traj_table(1,5:8)) 
            disp('Now at orientation: ') 
            disp(obj.imu_device_obj.traj_table(end,5:8)) 
            
            %% Final step: 
            disp('  ') 
            disp('<<<< All STEPS completed! >>>>') 
            if pause_dbug_fcn3(); keyboard; end; clc 
        end 
        % Sxa/b log-lagrangian 
        function S6b_mbf_mnfld_dyn_unkwn_smple_ovs_ovcst_gd_loglagr(obj) 
            obj.init_lagrangians(); 

            figure(1) 
            clf 
            pause(0.1) 
            figure(2) 
            clf 
            pause(0.1) 
            figure(3) 
            clf 
            pause(0.1) 
            %% Step 1: testingv 
            testf = 50; 
            usegyrodata = 1; 
            % theta = rand*pi; 
            % vec = randn(3,1); 
            % orient_quat = [cos(theta/2);sin(theta/2)*vec/norm(vec)]; 
            max_steps = 4000; 

            % Initialization 
            theta = -2.3*pi/4; 
            vec = [0;0;1]; 
            orient_quat = [cos(theta/2);sin(theta/2)*vec/norm(vec)]; 
            
            %% Step 3: Sort data into control singals 
            len_data = length(obj.datapoints(1,:)); 
            disp(['Length of dataset = ', num2str(len_data)]) 
            gyr = obj.datapoints(1:3,1:min(len_data,end))'; 
            acc = obj.datapoints(4:6,1:min(len_data,end))'; 

            % Load 
            try 
                load(['../OUTPUT', obj.auto_inputs.path_suffix, '/to_continue_unkwn_dT.mat']) 
                [~] = agb_now2; 
            catch 
                % init of tuning parameters 
                dT0 = 10/obj.sampling_frequency; % dT0 = (obj.downsampling/10)/obj.sampling_frequency; % % dT0 = obj.downsampling/obj.sampling_frequency; 
                agb_now2 = [1;1;1;1;0;0;0;1;1;1;0;0;0;0;0;0;0;0;0;0;dT0]; % odo_gain, (imu gains, bias) X 2, q0  
            end 
            
            %% Step 4: Optimize the angle, gains and bias 
            number_of_directions = 50; 
            %             old_grad_bounds = 1e-1*diag([1e-2,1e-3*ones(1,3),1e2*[1e-5,1e-5,1e-5],...
            %                 1e-3*ones(1,3),1e2*[1e-5,1e-5,1e-5],1e-2*ones(1,4),1e-2*ones(1,3)]); %,1e7*1e-6]); 
            grad_bounds = 1e-2*diag([1e-2,1e-3*ones(1,3),1e2*[1e-5,1e-5,1e-5],...
                1e-3*ones(1,3),1e-2*[1e-5,1e-5,1e-5],1e-3*ones(1,4),1e-1*ones(1,3),...
                1e-4]); %,1e7*1e-6]); 
            % Q = diag([1e6,1e6,1e-5]); % weight on the norm of final state 
            Q = diag([2e7,2e7,1e-3]); % 1km error x-y plane & z axis produces ~1e3 
            Div_odo = 5e5; 
            length_of_gain_vector = length(grad_bounds); 
            accleration_factor = 0.4; 
            eps_factr = 0.995; 
            eps_ifactr = 40; 
            epsilon = eps_factr^0; % 1 --> generated q  | 0 --> q from gyro data 
            try % test epsilon=0 
%                 [~] = uncomment_to_disable; 
                epsilon = 0; 
                warning('epsilon is set as ZERO! ') 
            catch err
                disp(newline)
                warning('IGNORED ERROR WARNING::')
                warning(getReport(err,'extended'));
                disp(newline)
            end
            % for dynamics 
            indices = obj.start_index:obj.end_index; 
            odo_all = obj.odo_gain_guess*repmat([diff(obj.odometer_max(indices)')', 0],3,1); 
            w_all = diag(obj.best_gain(4:end))*obj.all_datapoints(1:3,indices); 
            odo_data = obj.get_odometer_distance(indices); 
            % C_q = @(q) quat2rotm(q'); 
            noindices = length(indices); 
            % S_w = @(w) [0,-w(1),-w(2),-w(3);w(1),0,w(3),-w(2);w(2),-w(3),0,w(1);w(3),w(2),-w(1),0]; 
            % G_matrix = @(p) diag([(180/pi)/(obj.north_radius_of_earth + p(3)), ...
            %     -(180/pi)/((obj.east_radius_of_earth + p(3))*cosd(p(1))), 1]); % Lat Lon Up 
            % 
            try 
                load(['../OUTPUT', obj.auto_inputs.path_suffix, '/to_continue_unkwn_dT_vel_scld.mat']) 
                if epsilon~=0; epsilon = eps_factr^floor(start_iter/eps_ifactr); end 
            catch 
                start_iter = 1; 
            end 
            [f,g,h,h_ext,f_guess,g_guess,h_guess,h_ext_guess,A,B,C,C_ext,... % get_full_dynamics_manifold
                n_omega_ie,n_omega_en,Sx,Qx,C_nb,gl,G_func,f_s,f_p,q_gen,f_q,f_v,f_sns] ...
                = obj.get_full_dynamics_manifold_unknown_sampling_odovelmag_scaled(); 
            
            % perturbation check 
            stvar_name = {'Velocity gain 4 odoadjust','Accel-x gain','Accel-y gain','Accel-z gain','Accel-x bias','Accel-y bias','Accel-z bias',...
                'Gyro-x gain','Gyro-y gain','Gyro-z gain','Gyro-x bias','Gyro-y bias','Gyro-z bias','Init Quaternion-0',...
                'Init Quaternion-x','Init Quaternion-y','Init Quaternion-z','Init Velocity-x','Init Velocity-y','Init Velocity-z','Sampling Time'}; 
            if obj.auto_mode 
                en_grad_chk = 1; 
            else 
                en_grad_chk = input('Press `1` to enable graident tuning (press ENTER to skip): '); 
            end 
            if ~isempty(en_grad_chk) % check grad_bounds 
%                 [~,~,~,v,p_gen_basecase] = obj.get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld(agb_now2,...
%                     epsilon,indices,odo_all,w_all,f,g,C_nb); 
                [~,~,~,v,p_gen_basecase] = get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld_mex(agb_now2,...
                    indices,odo_all,w_all,obj.downsampling,obj.start_gps,...
                    obj.best_initial_orientation);
                final_state_basecase = p_gen_basecase(:,end); 
                report_perturbation = nan(4,length_of_gain_vector); 
                report_perturbation(1,1) = 0; 
                for i=1:length_of_gain_vector 
                    new_agb_now2 = agb_now2; 
                    for j=0:number_of_directions 
                        new_agb_now2(i) = new_agb_now2(i) + (3^j)*accleration_factor*grad_bounds(i,i); 
%                         [~,~,~,~,p_gen,odo_gen] = obj.get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld(new_agb_now2,...
%                             epsilon,indices,odo_all,w_all,f,g,C_nb); 
                        [~,~,~,~,p_gen,odo_gen] = get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld_mex(new_agb_now2,...
                            indices,odo_all,w_all,obj.downsampling,obj.start_gps,...
                            obj.best_initial_orientation);
                        final_state_now = p_gen(:,end); 
                        report_perturbation(2:4,i) = (final_state_now-final_state_basecase).*diag(Q).*(final_state_now-final_state_basecase); 
%                         figure(1) % <-- testing 
%                         geoplot(p_gen(1,1)',p_gen(2,1)','x'); 
%                         hold on 
%                         geoplot(p_gen(1,:)',p_gen(2,:)'); 
%                         geoplot(p_gen_basecase(1,:)',p_gen_basecase(2,:)','-.'); 
%                         geoplot(obj.end_gps(1),obj.end_gps(2),'o'); 
%                         hold off 
%                         y_fulltraj = [transpose(odo_data(1)+odo_gen)/obj.odo_gain_guess,p_gen']; 
%                         [gstart,gfinish,~,gmrkd] = obj.odo_marker_hit(y_fulltraj);
%                         obj.marker_projection(gstart,gfinish,gmrkd); 
%                         title(['Tuning parameter: ', stvar_name{i}]) 
%                         pause 
                        if norm(report_perturbation(2:4,i))>1 % approx 1 meter in x-y OR z direction 
                            report_perturbation(1,i) = j; 
                            figure(1) % <-- testing 
                            geoplot(p_gen(1,1)',p_gen(2,1)','x'); 
                            hold on 
                            geoplot(p_gen(1,:)',p_gen(2,:)'); 
                            geoplot(p_gen_basecase(1,:)',p_gen_basecase(2,:)','-.'); 
                            geoplot(obj.end_gps(1),obj.end_gps(2),'o'); 
                            hold off 
                            y_fulltraj = [transpose(odo_data(1)+odo_gen)/obj.odo_gain_guess,p_gen']; 
                            [gstart,gfinish,~,gmrkd] = obj.odo_marker_hit(y_fulltraj);
                            obj.marker_NW_distance(gstart,gfinish,gmrkd); 
                            title(['Tuning parameter: ', stvar_name{i}]) 
                            pause(0.1) 
                            break 
                        end 
                    end 
                end 
                disp('Perturbation report: ') 
                disp(report_perturbation) 
                disp('Old grad bounds: ') 
                disp(diag(grad_bounds)') 
                disp('Modified grad bounds: ') 
                disp((3.^report_perturbation(1,:)).*diag(grad_bounds)') 
                if obj.auto_mode 
                    sentvty = obj.auto_inputs.S6.sentvty; 
                else 
                    sentvty = input('Enter sensitivity of graidents (press ENTER to skip): '); 
                end 
                if ~isempty(sentvty) % modify grad_bounds 
                    grad_bounds = sentvty*diag(3.^report_perturbation(1,:))*grad_bounds; 
                end 
            end 
            % disp('Press any key to continue ... ') 
            % pause 
            %             if sum(isnan(report_perturbation(1,:)))>0 
            %                 warning('Too small graidents! ') 
            %                 report_perturbation(1,isnan(report_perturbation(1,:))) = number_of_directions; 
            %             end 

            % main loop 
            no_of_elites = floor((50/100)*number_of_directions); 
            best_grad_bound_so_far = zeros(length_of_gain_vector,no_of_elites); 
            auto_tuning_start_iter = start_iter; 
            for i=start_iter:max_steps 
                % Sub-step 2a: Choose gradients at uniformly random 
                random_gain_grads = [zeros(length_of_gain_vector,1), best_grad_bound_so_far, ...
                    2*grad_bounds*(0.5-rand(length_of_gain_vector, number_of_directions-no_of_elites-1))]; 

                % Sub-step 2b: Find new points along the random gradients 
                %                 accleration_factor = 1/i; 
                new_agb = repmat(agb_now2,1,number_of_directions) + accleration_factor*random_gain_grads; 

                % Sub-step 2c: Evaluate end gps point for all new states 
                all_costs = inf(1,number_of_directions); 
                for j=1:number_of_directions 
                    % load parameters for forward run 
                    %                     [~,~,~,v,p_gen,odo_gen] = obj.get_full_dynamical_trajectory(new_agb(:,j),...
                    %                         epsilon,indices,odo_all,w_all); 
%                     [~,~,~,v,p_gen,odo_gen] = obj.get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld(new_agb(:,j),...
%                         epsilon,indices,odo_all,w_all,f,g,C_nb); 
                    [~,~,~,v,p_gen,odo_gen] = get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld_mex(new_agb(:,j),...
                        indices,odo_all,w_all,obj.downsampling,obj.start_gps,...
                        obj.best_initial_orientation);
                    v_imu_magn = abs(new_agb(1,j))*sqrt(sum(v.*v,1)); 
                    [marker_costs,end_point_cost,straightning_cost,odo_cost,vel_odo_cost] ...
                        = obj.get_costs_mrkd_S6b_odovelcst_loglagr(odo_gen,p_gen,v_imu_magn,odo_data,noindices); 
                    all_costs(1,j) = marker_costs + end_point_cost + straightning_cost ...
                        + odo_cost + vel_odo_cost; 
                    % start-1 < for testing > 
%                     figure(1) 
%                     geoplot(p_gen(1,1)',p_gen(2,1)','x'); 
%                     hold on 
%                     geoplot(p_gen(1,:)',p_gen(2,:)'); 
%                     geoplot(obj.end_gps(1),obj.end_gps(2),'o'); 
%                     hold off 
%                     title(['i = ', num2str(i), ' | elevation error = ', ...
%                         num2str(obj.end_gps(3)-p_gen(3,end))]) 
%                     figure(2) 
%                     clf; stem(all_costs); hold on; 
%                     plot(min(all_costs)*ones(1,number_of_directions), 'g--'); 
%                     plot(all_costs(1)*ones(1,number_of_directions), '-'); 
%                     hold off 
%                     figure(3) 
%                     plot(odo_gen); hold on; plot(odo_data-odo_data(1)); hold off 
%                     % disp(all_costs(1,1:j)) 
%                     % disp(straightning_cost) 
%                     disp('error components = ') 
%                     disp(transpose((final_state(1:3)-obj.end_gps').*diag(Q).*(final_state(1:3)-obj.end_gps'))) 
%                     disp(['end_cost = ', num2str(end_point_cost), ' & strtn_cost = ', num2str(straightning_cost), ...
%                         ' & odo_cost = ', num2str(odo_cost)]) 
                    % end-1 < for testing >
                end 

                % Sub-step 2d: Choose the best and set it as new gain 
                [~,best_arg] = sort(all_costs); 
                agb_now2 = new_agb(:,best_arg(1)); 
                best_grad_bound_so_far = random_gain_grads(:,best_arg(1:no_of_elites)); 
                best_grad_bound_so_far = obj.elite_selection(best_grad_bound_so_far,no_of_elites,...
                    [25,25,nan],0.5); % [old elites, scaled elites, crossover] 
                % see plots 
                %                 [~,~,~,v,p_gen,odo_gen] = obj.get_full_dynamical_trajectory(agb_now2,...
                %                     epsilon,indices,odo_all,w_all); 
%                 [q_dot,q,v_dot,v,p_gen,odo_gen,acc_generated_body] = obj.get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld(agb_now2,...
%                     epsilon,indices,odo_all,w_all,f,g,C_nb); 
                [q_dot,q,v_dot,v,p_gen,odo_gen,acc_generated_body] = get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld_mex(agb_now2,...
                    indices,odo_all,w_all,obj.downsampling,obj.start_gps,...
                    obj.best_initial_orientation);
                final_state = p_gen(:,end); 
                disp((final_state(1:3)-obj.end_gps').*diag(Q).*(final_state(1:3)-obj.end_gps')) 
                % lagrangian update 
                v_imu_magn = abs(agb_now2(1))*sqrt(sum(v.*v,1)); 
                obj.get_costs_mrkd_S6b_odovelcst_loglagr(odo_gen,p_gen,v_imu_magn,odo_data,noindices,true); 
                
                if obj.auto_inputs.en_plot(i)
                    figure(1) % <-- testing 
                    geoplot(p_gen(1,1)',p_gen(2,1)','x'); 
                    hold on 
                    geoplot(p_gen(1,:)',p_gen(2,:)'); 
                    geoplot(obj.end_gps(1),obj.end_gps(2),'o'); 
                    hold off 
                    y_fulltraj = [transpose(odo_data(1)+odo_gen)/obj.odo_gain_guess,p_gen']; 
                    [gstart,gfinish,~,gmrkd] = obj.odo_marker_hit(y_fulltraj);
                    obj.marker_NW_distance(gstart,gfinish,gmrkd);
                    title(['vel mismatch = ',num2str(vel_odo_cost)])
                    figure(2) 
                    plot(odo_all') 
                    hold on 
                    plot(acc_generated_body') 
                    hold off 
                    xlabel('index --> ') 
                    ylabel('Acceleration --> ') 
                    legend('acc imu data-x', 'acc imu data-y', 'acc imu data-z', ...
                        'gyro rotated gravity data-x', 'gyro rotated gravity data-y',  ...
                        'gyro rotated gravity data-z', 'Location','best')
                    if best_arg(1)~=1 
                        title(['iter = ', num2str(i), ' | elevation error = ', ...
                            num2str(obj.end_gps(3)-p_gen(3,end)), ' <IMPROVED>']) 
                    else 
                        title(['iter = ', num2str(i), ' | elevation error = ', ...
                            num2str(obj.end_gps(3)-p_gen(3,end)), ' <No change>']) 
                    end 
                    figure(3) 
                    subplot(2,1,1)
                    plot(odo_gen); hold on; plot(odo_data-odo_data(1)); hold off 
                    subplot(2,1,2)
                    v_imu_magn = abs(new_agb(1,j))*sqrt(sum(v.*v,1));
                    v_odo_magn = obj.odo_gain_guess*diff(obj.odometer_max(obj.start_index:obj.end_index))...
                        *obj.sampling_frequency/obj.downsampling; 
                    plot(v_imu_magn); hold on; plot(v_odo_magn,'-.'); hold off 
                    pause(0.1)
                end 

                % aip return now 
                return_enable = false; 
                if obj.auto_mode 
                    if (i-auto_tuning_start_iter+1)>=obj.auto_inputs.S6.breaking_iter 
                        try getcsv_venop(obj.auto_inputs.path_suffix, obj,odo_gen,p_gen,q,v,odo_all,w_all); getcsv_venop_using_refdata_forS6(obj.auto_inputs.path_suffix, obj,odo_gen,p_gen,q,v,odo_all,w_all); catch; try getcsv_venop_using_refdata_forS6(obj.auto_inputs.path_suffix, obj,odo_gen,p_gen,q,v,odo_all,w_all); catch; end; end; 
                        return_enable = true;  
                    end 
                end 

                % save 
                save(['../OUTPUT', obj.auto_inputs.path_suffix, '/best_agbgb_unkwn_dT_vel_scld.mat'], 'agb_now2', 'grad_bounds')  
                if mod(i,eps_ifactr)==0 || return_enable 
                    fname = [['../OUTPUT', obj.auto_inputs.path_suffix, '/best_agbgb_unkwn_dT_vel_scld eps '],num2str(eps_factr),'^',num2str(ceil(i/eps_ifactr)-1)]; 
                    save([fname,'.mat'], 'agb_now2', 'epsilon', 'grad_bounds') 
                    saveas(1,[fname,'.png']); saveas(2,[fname,'_imu.png']) 
                    saveas(3,[fname,'_odo.png']) 
                    saveas(1,[fname,'.fig']); saveas(2,[fname,'_imu.fig']) 
                    saveas(3,[fname,'_odo.fig']) 
                    save(['../OUTPUT', obj.auto_inputs.path_suffix, '/last_manual_settings.mat'], 'Q', 'Div_odo', 'agb_now2', 'epsilon', 'p_gen', 'grad_bounds')  
                    %
                    epsilon = eps_factr*epsilon;  
                    % 
                    start_iter = i+1; 
                    save(['../OUTPUT', obj.auto_inputs.path_suffix, '/to_continue_unkwn_dT_vel_scld.mat'], 'agb_now2', 'start_iter', 'grad_bounds')  
                    lag_vals = obj.lagrngns; 
                    save(['../OUTPUT', obj.auto_inputs.path_suffix, '/lagrangians.mat'],'lag_vals'); 
                    disp('Pause here if needed!'); try getcsv_venop(obj.auto_inputs.path_suffix, obj,odo_gen,p_gen,q,v,odo_all,w_all); getcsv_venop_using_refdata_forS6(obj.auto_inputs.path_suffix, obj,odo_gen,p_gen,q,v,odo_all,w_all); catch; try getcsv_venop_using_refdata_forS6(obj.auto_inputs.path_suffix, obj,odo_gen,p_gen,q,v,odo_all,w_all); catch; end; end
                end 

                % Sub-step 2e: Progres bar 
                percent_done = i*100/max_steps; 
                
                if obj.auto_inputs.en_plot(i); clc; disp(['Progress: <', repmat('||',1,floor(percent_done/3 )), '> ', num2str(percent_done), ' % ']); end  

                if obj.auto_mode 
                    if return_enable 
                        disp('Its over in auto_tuning!') 
                        save(['../OUTPUT', obj.auto_inputs.path_suffix, '/auto_outputs.mat'],'agb_now2','q_dot','q','v_dot','v',...
                            'p_gen','odo_gen','acc_generated_body','odo_all','w_all') 
                        return 
                    end 
                    if mod(i-auto_tuning_start_iter+1,obj.auto_inputs.S6.buzzer_on_iter)==0 
                        sound(sin(2*pi*2000*(0:0.5/8192:1))) 
                        % manual return 
                        return_now = false; 
                        warning('Manually break the code HERE! <--') 
                        % execute: return_now = true; 
                        if return_now 
                            return 
                        end 
                    end 
                end 
            end 
            
            %% Step 2: Render environment and IMU device best trajectory 
            figure(1) 
            % Create IMU object 
            obj.imu_device_obj = imu_device(obj.start_gps,orient_quat); 
            obj.show_markers_geoplot(); 
            obj.imu_device_obj.generate_traj_ode(acc,usegyrodata*gyr,obj.timepoints/testf); 
            obj.imu_device_obj.reset_state(); 
            obj.imu_device_obj.set_diag_gains(obj.best_gain); 
            obj.imu_device_obj.set_init_orient(orient_now/norm(orient_now)); 
            obj.imu_device_obj.generate_traj_ode(acc,usegyrodata*gyr,obj.timepoints/testf); 
            hold on 
            obj.imu_device_obj.geoplot_traj(); 
            hold off 
            
            %% Step 5: Print 
            disp('Started at location: ') 
            disp(obj.imu_device_obj.traj_table(1,2:4)) 
            disp('Now at location: ') 
            disp(obj.imu_device_obj.traj_table(end,2:4)) 
            disp('True end at location: ') 
            disp(obj.end_gps) 
            disp('Started at orientation: ') 
            disp(obj.imu_device_obj.traj_table(1,5:8)) 
            disp('Now at orientation: ') 
            disp(obj.imu_device_obj.traj_table(end,5:8)) 
            
            %% Final step: 
            disp('  ') 
            disp('<<<< All STEPS completed! >>>>') 
            if pause_dbug_fcn3(); keyboard; end; clc 
        end 
        function S6b_mbf_mnfld_dyn_unkwn_smple_vel_scaled_odovelcst_gd_loglagr(obj) 
            obj.init_lagrangians(); 

            figure(1) 
            clf 
            pause(0.1) 
            figure(2) 
            clf 
            pause(0.1) 
            figure(3) 
            clf 
            pause(0.1) 
            %% Step 1: testingv 
            testf = 50; 
            usegyrodata = 1; 
            % theta = rand*pi; 
            % vec = randn(3,1); 
            % orient_quat = [cos(theta/2);sin(theta/2)*vec/norm(vec)]; 
            max_steps = 4000; 

            % Initialization 
            theta = -2.3*pi/4; 
            vec = [0;0;1]; 
            orient_quat = [cos(theta/2);sin(theta/2)*vec/norm(vec)]; 
            
            %% Step 3: Sort data into control singals 
            len_data = length(obj.datapoints(1,:)); 
            disp(['Length of dataset = ', num2str(len_data)]) 
            gyr = obj.datapoints(1:3,1:min(len_data,end))'; 
            acc = obj.datapoints(4:6,1:min(len_data,end))'; 

            % Load 
            try 
                load(['../OUTPUT', obj.auto_inputs.path_suffix, '/to_continue_unkwn_dT.mat']) 
                [~] = agb_now2; 
            catch 
                % init of tuning parameters 
                dT0 = 10/obj.sampling_frequency; % dT0 = (obj.downsampling/10)/obj.sampling_frequency; % % dT0 = obj.downsampling/obj.sampling_frequency; 
                agb_now2 = [1;1;1;1;0;0;0;1;1;1;0;0;0;0;0;0;0;0;0;0;dT0]; % odo_gain, (imu gains, bias) X 2, q0  
            end 
            
            %% Step 4: Optimize the angle, gains and bias 
            number_of_directions = 50; 
            %             old_grad_bounds = 1e-1*diag([1e-2,1e-3*ones(1,3),1e2*[1e-5,1e-5,1e-5],...
            %                 1e-3*ones(1,3),1e2*[1e-5,1e-5,1e-5],1e-2*ones(1,4),1e-2*ones(1,3)]); %,1e7*1e-6]); 
            grad_bounds = 1e-2*diag([1e-2,1e-3*ones(1,3),1e2*[1e-5,1e-5,1e-5],...
                1e-3*ones(1,3),1e-2*[1e-5,1e-5,1e-5],1e-3*ones(1,4),1e-1*ones(1,3),...
                1e-4]); %,1e7*1e-6]); 
            % Q = diag([1e6,1e6,1e-5]); % weight on the norm of final state 
            Q = diag([2e7,2e7,1e-3]); % 1km error x-y plane & z axis produces ~1e3 
            Div_odo = 5e5; 
            length_of_gain_vector = length(grad_bounds); 
            accleration_factor = 0.4; 
            eps_factr = 0.995; 
            eps_ifactr = 40; 
            epsilon = eps_factr^0; % 1 --> generated q  | 0 --> q from gyro data 
            try % test epsilon=0 
%                 [~] = uncomment_to_disable; 
                epsilon = 0; 
                warning('epsilon is set as ZERO! ') 
            catch err
                disp(newline)
                warning('IGNORED ERROR WARNING::')
                warning(getReport(err,'extended'));
                disp(newline)
            end
            % for dynamics 
            indices = obj.start_index:obj.end_index; 
            odo_all = obj.odo_gain_guess*repmat([diff(obj.odometer_max(indices)')', 0],3,1); 
            w_all = diag(obj.best_gain(4:end))*obj.all_datapoints(1:3,indices); 
            odo_data = obj.get_odometer_distance(indices); 
            % C_q = @(q) quat2rotm(q'); 
            noindices = length(indices); 
            % S_w = @(w) [0,-w(1),-w(2),-w(3);w(1),0,w(3),-w(2);w(2),-w(3),0,w(1);w(3),w(2),-w(1),0]; 
            % G_matrix = @(p) diag([(180/pi)/(obj.north_radius_of_earth + p(3)), ...
            %     -(180/pi)/((obj.east_radius_of_earth + p(3))*cosd(p(1))), 1]); % Lat Lon Up 
            % 
            try 
                load(['../OUTPUT', obj.auto_inputs.path_suffix, '/to_continue_unkwn_dT_vel_scld.mat']) 
                if epsilon~=0; epsilon = eps_factr^floor(start_iter/eps_ifactr); end 
            catch 
                start_iter = 1; 
            end 
            [f,g,h,h_ext,f_guess,g_guess,h_guess,h_ext_guess,A,B,C,C_ext,... % get_full_dynamics_manifold
                n_omega_ie,n_omega_en,Sx,Qx,C_nb,gl,G_func,f_s,f_p,q_gen,f_q,f_v,f_sns] ...
                = obj.get_full_dynamics_manifold_unknown_sampling_vel_scaled(); 
            
            % perturbation check 
            stvar_name = {'Velocity gain 4 odoadjust','Accel-x gain','Accel-y gain','Accel-z gain','Accel-x bias','Accel-y bias','Accel-z bias',...
                'Gyro-x gain','Gyro-y gain','Gyro-z gain','Gyro-x bias','Gyro-y bias','Gyro-z bias','Init Quaternion-0',...
                'Init Quaternion-x','Init Quaternion-y','Init Quaternion-z','Init Velocity-x','Init Velocity-y','Init Velocity-z','Sampling Time'}; 
            if obj.auto_mode 
                en_grad_chk = 1; 
            else 
                en_grad_chk = input('Press `1` to enable graident tuning (press ENTER to skip): '); 
            end 
            if ~isempty(en_grad_chk) % check grad_bounds 
%                 [~,~,~,v,p_gen_basecase] = obj.get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld(agb_now2,...
%                     epsilon,indices,odo_all,w_all,f,g,C_nb); 
                [~,~,~,v,p_gen_basecase] = get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld_mex(agb_now2,...
                    indices,odo_all,w_all,obj.downsampling,obj.start_gps,...
                    obj.best_initial_orientation);
                final_state_basecase = p_gen_basecase(:,end); 
                report_perturbation = nan(4,length_of_gain_vector); 
                report_perturbation(1,1) = 0; 
                for i=1:length_of_gain_vector 
                    new_agb_now2 = agb_now2; 
                    for j=0:number_of_directions 
                        new_agb_now2(i) = new_agb_now2(i) + (3^j)*accleration_factor*grad_bounds(i,i); 
%                         [~,~,~,~,p_gen,odo_gen] = obj.get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld(new_agb_now2,...
%                             epsilon,indices,odo_all,w_all,f,g,C_nb); 
                        [~,~,~,~,p_gen,odo_gen] = get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld_mex(new_agb_now2,...
                            indices,odo_all,w_all,obj.downsampling,obj.start_gps,...
                            obj.best_initial_orientation);
                        final_state_now = p_gen(:,end); 
                        report_perturbation(2:4,i) = (final_state_now-final_state_basecase).*diag(Q).*(final_state_now-final_state_basecase); 
%                         figure(1) % <-- testing 
%                         geoplot(p_gen(1,1)',p_gen(2,1)','x'); 
%                         hold on 
%                         geoplot(p_gen(1,:)',p_gen(2,:)'); 
%                         geoplot(p_gen_basecase(1,:)',p_gen_basecase(2,:)','-.'); 
%                         geoplot(obj.end_gps(1),obj.end_gps(2),'o'); 
%                         hold off 
%                         y_fulltraj = [transpose(odo_data(1)+odo_gen)/obj.odo_gain_guess,p_gen']; 
%                         [gstart,gfinish,~,gmrkd] = obj.odo_marker_hit(y_fulltraj);
%                         obj.marker_projection(gstart,gfinish,gmrkd); 
%                         title(['Tuning parameter: ', stvar_name{i}]) 
%                         pause 
                        if norm(report_perturbation(2:4,i))>1 % approx 1 meter in x-y OR z direction 
                            report_perturbation(1,i) = j; 
                            figure(1) % <-- testing 
                            geoplot(p_gen(1,1)',p_gen(2,1)','x'); 
                            hold on 
                            geoplot(p_gen(1,:)',p_gen(2,:)'); 
                            geoplot(p_gen_basecase(1,:)',p_gen_basecase(2,:)','-.'); 
                            geoplot(obj.end_gps(1),obj.end_gps(2),'o'); 
                            hold off 
                            y_fulltraj = [transpose(odo_data(1)+odo_gen)/obj.odo_gain_guess,p_gen']; 
                            [gstart,gfinish,~,gmrkd] = obj.odo_marker_hit(y_fulltraj);
                            obj.marker_NW_distance(gstart,gfinish,gmrkd); 
                            title(['Tuning parameter: ', stvar_name{i}]) 
                            pause(0.1) 
                            break 
                        end 
                    end 
                end 
                disp('Perturbation report: ') 
                disp(report_perturbation) 
                disp('Old grad bounds: ') 
                disp(diag(grad_bounds)') 
                disp('Modified grad bounds: ') 
                disp((3.^report_perturbation(1,:)).*diag(grad_bounds)') 
                if obj.auto_mode 
                    sentvty = obj.auto_inputs.S6.sentvty; 
                else 
                    sentvty = input('Enter sensitivity of graidents (press ENTER to skip): '); 
                end 
                if ~isempty(sentvty) % modify grad_bounds 
                    grad_bounds = sentvty*diag(3.^report_perturbation(1,:))*grad_bounds; 
                end 
            end 
            % disp('Press any key to continue ... ') 
            % pause 
            %             if sum(isnan(report_perturbation(1,:)))>0 
            %                 warning('Too small graidents! ') 
            %                 report_perturbation(1,isnan(report_perturbation(1,:))) = number_of_directions; 
            %             end 

            % main loop 
            no_of_elites = floor((50/100)*number_of_directions); 
            best_grad_bound_so_far = zeros(length_of_gain_vector,no_of_elites); 
            auto_tuning_start_iter = start_iter; 
            for i=start_iter:max_steps 
                % Sub-step 2a: Choose gradients at uniformly random 
                random_gain_grads = [zeros(length_of_gain_vector,1), best_grad_bound_so_far, ...
                    2*grad_bounds*(0.5-rand(length_of_gain_vector, number_of_directions-no_of_elites-1))]; 

                % Sub-step 2b: Find new points along the random gradients 
                %                 accleration_factor = 1/i; 
                new_agb = repmat(agb_now2,1,number_of_directions) + accleration_factor*random_gain_grads; 

                % Sub-step 2c: Evaluate end gps point for all new states 
                all_costs = inf(1,number_of_directions); 
                for j=1:number_of_directions 
                    % load parameters for forward run 
                    %                     [~,~,~,v,p_gen,odo_gen] = obj.get_full_dynamical_trajectory(new_agb(:,j),...
                    %                         epsilon,indices,odo_all,w_all); 
%                     [~,~,~,v,p_gen,odo_gen] = obj.get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld(new_agb(:,j),...
%                         epsilon,indices,odo_all,w_all,f,g,C_nb); 
                    [~,~,~,v,p_gen,odo_gen] = get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld_mex(new_agb(:,j),...
                        indices,odo_all,w_all,obj.downsampling,obj.start_gps,...
                        obj.best_initial_orientation);
                    v_imu_magn = abs(new_agb(1,j))*sqrt(sum(v.*v,1)); 
                    [marker_costs,end_point_cost,straightning_cost,odo_cost,vel_odo_cost] ...
                        = obj.get_costs_mrkd_S6b_odovelcst_loglagr(odo_gen,p_gen,v_imu_magn,odo_data,noindices); 
                    all_costs(1,j) = marker_costs + end_point_cost + straightning_cost ...
                        + odo_cost + 0.2*vel_odo_cost; 
                    % start-1 < for testing > 
%                     figure(1) 
%                     geoplot(p_gen(1,1)',p_gen(2,1)','x'); 
%                     hold on 
%                     geoplot(p_gen(1,:)',p_gen(2,:)'); 
%                     geoplot(obj.end_gps(1),obj.end_gps(2),'o'); 
%                     hold off 
%                     title(['i = ', num2str(i), ' | elevation error = ', ...
%                         num2str(obj.end_gps(3)-p_gen(3,end))]) 
%                     figure(2) 
%                     clf; stem(all_costs); hold on; 
%                     plot(min(all_costs)*ones(1,number_of_directions), 'g--'); 
%                     plot(all_costs(1)*ones(1,number_of_directions), '-'); 
%                     hold off 
%                     figure(3) 
%                     plot(odo_gen); hold on; plot(odo_data-odo_data(1)); hold off 
%                     % disp(all_costs(1,1:j)) 
%                     % disp(straightning_cost) 
%                     disp('error components = ') 
%                     disp(transpose((final_state(1:3)-obj.end_gps').*diag(Q).*(final_state(1:3)-obj.end_gps'))) 
%                     disp(['end_cost = ', num2str(end_point_cost), ' & strtn_cost = ', num2str(straightning_cost), ...
%                         ' & odo_cost = ', num2str(odo_cost)]) 
                    % end-1 < for testing >
                end 

                % Sub-step 2d: Choose the best and set it as new gain 
                [~,best_arg] = sort(all_costs); 
                agb_now2 = new_agb(:,best_arg(1)); 
                best_grad_bound_so_far = random_gain_grads(:,best_arg(1:no_of_elites)); 
                best_grad_bound_so_far = obj.elite_selection(best_grad_bound_so_far,no_of_elites,...
                    [25,25,nan],0.5); % [old elites, scaled elites, crossover] 
                % see plots 
                %                 [~,~,~,v,p_gen,odo_gen] = obj.get_full_dynamical_trajectory(agb_now2,...
                %                     epsilon,indices,odo_all,w_all); 
%                 [q_dot,q,v_dot,v,p_gen,odo_gen,acc_generated_body] = obj.get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld(agb_now2,...
%                     epsilon,indices,odo_all,w_all,f,g,C_nb); 
                [q_dot,q,v_dot,v,p_gen,odo_gen,acc_generated_body] = get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld_mex(agb_now2,...
                    indices,odo_all,w_all,obj.downsampling,obj.start_gps,...
                    obj.best_initial_orientation);
                final_state = p_gen(:,end); 
                disp((final_state(1:3)-obj.end_gps').*diag(Q).*(final_state(1:3)-obj.end_gps')) 
                % lagrangian update 
                v_imu_magn = abs(agb_now2(1))*sqrt(sum(v.*v,1)); 
                obj.get_costs_mrkd_S6b_odovelcst_loglagr(odo_gen,p_gen,v_imu_magn,odo_data,noindices,true); 
                
                if obj.auto_inputs.en_plot(i)
                    figure(1) % <-- testing 
                    geoplot(p_gen(1,1)',p_gen(2,1)','x'); 
                    hold on 
                    geoplot(p_gen(1,:)',p_gen(2,:)'); 
                    geoplot(obj.end_gps(1),obj.end_gps(2),'o'); 
                    hold off 
                    y_fulltraj = [transpose(odo_data(1)+odo_gen)/obj.odo_gain_guess,p_gen']; 
                    [gstart,gfinish,~,gmrkd] = obj.odo_marker_hit(y_fulltraj);
                    obj.marker_NW_distance(gstart,gfinish,gmrkd);
                    title(['vel mismatch = ',num2str(vel_odo_cost)])
                    figure(2) 
                    plot(odo_all') 
                    hold on 
                    plot(acc_generated_body') 
                    hold off 
                    xlabel('index --> ') 
                    ylabel('Acceleration --> ') 
                    legend('acc imu data-x', 'acc imu data-y', 'acc imu data-z', ...
                        'gyro rotated gravity data-x', 'gyro rotated gravity data-y',  ...
                        'gyro rotated gravity data-z', 'Location','best')
                    if best_arg(1)~=1 
                        title(['iter = ', num2str(i), ' | elevation error = ', ...
                            num2str(obj.end_gps(3)-p_gen(3,end)), ' <IMPROVED>']) 
                    else 
                        title(['iter = ', num2str(i), ' | elevation error = ', ...
                            num2str(obj.end_gps(3)-p_gen(3,end)), ' <No change>']) 
                    end 
                    figure(3) 
                    subplot(2,1,1)
                    plot(odo_gen); hold on; plot(odo_data-odo_data(1)); hold off 
                    subplot(2,1,2)
                    v_imu_magn = abs(new_agb(1,j))*sqrt(sum(v.*v,1));
                    v_odo_magn = obj.odo_gain_guess*diff(obj.odometer_max(obj.start_index:obj.end_index))...
                        *obj.sampling_frequency/obj.downsampling; 
                    plot(v_imu_magn); hold on; plot(v_odo_magn,'-.'); hold off 
                    pause(0.1) 
                end 

                % aip return now 
                return_enable = false; 
                if obj.auto_mode 
                    if (i-auto_tuning_start_iter+1)>=obj.auto_inputs.S6.breaking_iter 
                        try getcsv_venop(obj.auto_inputs.path_suffix, obj,odo_gen,p_gen,q,v,odo_all,w_all); getcsv_venop_using_refdata_forS6(obj.auto_inputs.path_suffix, obj,odo_gen,p_gen,q,v,odo_all,w_all); catch; try getcsv_venop_using_refdata_forS6(obj.auto_inputs.path_suffix, obj,odo_gen,p_gen,q,v,odo_all,w_all); catch; end; end; 
                        return_enable = true;  
                    end 
                end 

                % save 
                save(['../OUTPUT', obj.auto_inputs.path_suffix, '/best_agbgb_unkwn_dT_vel_scld.mat'], 'agb_now2', 'grad_bounds')  
                if mod(i,eps_ifactr)==0 || return_enable 
                    fname = [['../OUTPUT', obj.auto_inputs.path_suffix, '/best_agbgb_unkwn_dT_vel_scld eps '],num2str(eps_factr),'^',num2str(ceil(i/eps_ifactr)-1)]; 
                    save([fname,'.mat'], 'agb_now2', 'epsilon', 'grad_bounds') 
                    saveas(1,[fname,'.png']); saveas(2,[fname,'_imu.png']) 
                    saveas(3,[fname,'_odo.png']) 
                    saveas(1,[fname,'.fig']); saveas(2,[fname,'_imu.fig']) 
                    saveas(3,[fname,'_odo.fig']) 
                    save(['../OUTPUT', obj.auto_inputs.path_suffix, '/last_manual_settings.mat'], 'Q', 'Div_odo', 'agb_now2', 'epsilon', 'p_gen', 'grad_bounds')  
                    %
                    epsilon = eps_factr*epsilon;  
                    % 
                    start_iter = i+1; 
                    save(['../OUTPUT', obj.auto_inputs.path_suffix, '/to_continue_unkwn_dT_vel_scld.mat'], 'agb_now2', 'start_iter', 'grad_bounds')  
                    lag_vals = obj.lagrngns; 
                    save(['../OUTPUT', obj.auto_inputs.path_suffix, '/lagrangians.mat'],'lag_vals'); 
                    disp('Pause here if needed!'); try getcsv_venop(obj.auto_inputs.path_suffix, obj,odo_gen,p_gen,q,v,odo_all,w_all); getcsv_venop_using_refdata_forS6(obj.auto_inputs.path_suffix, obj,odo_gen,p_gen,q,v,odo_all,w_all); catch; try getcsv_venop_using_refdata_forS6(obj.auto_inputs.path_suffix, obj,odo_gen,p_gen,q,v,odo_all,w_all); catch; end; end
                end 

                % Sub-step 2e: Progres bar 
                percent_done = i*100/max_steps; 
                
                if obj.auto_inputs.en_plot(i); clc; disp(['Progress: <', repmat('||',1,floor(percent_done/3 )), '> ', num2str(percent_done), ' % ']); end  

                if obj.auto_mode 
                    if return_enable 
                        disp('Its over in auto_tuning!') 
                        save(['../OUTPUT', obj.auto_inputs.path_suffix, '/auto_outputs.mat'],'agb_now2','q_dot','q','v_dot','v',...
                            'p_gen','odo_gen','acc_generated_body','odo_all','w_all') 
                        return 
                    end 
                    if mod(i-auto_tuning_start_iter+1,obj.auto_inputs.S6.buzzer_on_iter)==0 
                        sound(sin(2*pi*2000*(0:0.5/8192:1))) 
                        % manual return 
                        return_now = false; 
                        warning('Manually break the code HERE! <--') 
                        % execute: return_now = true; 
                        if return_now 
                            return 
                        end 
                    end 
                end 
            end 
            
            %% Step 2: Render environment and IMU device best trajectory 
            figure(1) 
            % Create IMU object 
            obj.imu_device_obj = imu_device(obj.start_gps,orient_quat); 
            obj.show_markers_geoplot(); 
            obj.imu_device_obj.generate_traj_ode(acc,usegyrodata*gyr,obj.timepoints/testf); 
            obj.imu_device_obj.reset_state(); 
            obj.imu_device_obj.set_diag_gains(obj.best_gain); 
            obj.imu_device_obj.set_init_orient(orient_now/norm(orient_now)); 
            obj.imu_device_obj.generate_traj_ode(acc,usegyrodata*gyr,obj.timepoints/testf); 
            hold on 
            obj.imu_device_obj.geoplot_traj(); 
            hold off 
            
            %% Step 5: Print 
            disp('Started at location: ') 
            disp(obj.imu_device_obj.traj_table(1,2:4)) 
            disp('Now at location: ') 
            disp(obj.imu_device_obj.traj_table(end,2:4)) 
            disp('True end at location: ') 
            disp(obj.end_gps) 
            disp('Started at orientation: ') 
            disp(obj.imu_device_obj.traj_table(1,5:8)) 
            disp('Now at orientation: ') 
            disp(obj.imu_device_obj.traj_table(end,5:8)) 
            
            %% Final step: 
            disp('  ') 
            disp('<<<< All STEPS completed! >>>>') 
            if pause_dbug_fcn3(); keyboard; end; clc 
        end 
        function S6b_mbf_mnfld_dyn_unkwn_smple_vscl_ovcst_vscst_gd_loglagr(obj) 
            obj.init_lagrangians(); 

            figure(1) 
            clf 
            pause(0.1) 
            figure(2) 
            clf 
            pause(0.1) 
            figure(3) 
            clf 
            pause(0.1) 
            %% Step 1: testingv 
            testf = 50; 
            usegyrodata = 1; 
            % theta = rand*pi; 
            % vec = randn(3,1); 
            % orient_quat = [cos(theta/2);sin(theta/2)*vec/norm(vec)]; 
            max_steps = 4000; 

            % Initialization 
            theta = -2.3*pi/4; 
            vec = [0;0;1]; 
            orient_quat = [cos(theta/2);sin(theta/2)*vec/norm(vec)]; 
            
            %% Step 3: Sort data into control singals 
            len_data = length(obj.datapoints(1,:)); 
            disp(['Length of dataset = ', num2str(len_data)]) 
            gyr = obj.datapoints(1:3,1:min(len_data,end))'; 
            acc = obj.datapoints(4:6,1:min(len_data,end))'; 

            % Load 
            try 
                load(['../OUTPUT', obj.auto_inputs.path_suffix, '/to_continue_unkwn_dT.mat']) 
                [~] = agb_now2; 
            catch 
                % init of tuning parameters 
                dT0 = 10/obj.sampling_frequency; % dT0 = (obj.downsampling/10)/obj.sampling_frequency; % % dT0 = obj.downsampling/obj.sampling_frequency; 
                agb_now2 = [1;1;1;1;0;0;0;1;1;1;0;0;0;0;0;0;0;0;0;0;dT0]; % odo_gain, (imu gains, bias) X 2, q0  
            end 
            
            %% Step 4: Optimize the angle, gains and bias 
            number_of_directions = 50; 
            %             old_grad_bounds = 1e-1*diag([1e-2,1e-3*ones(1,3),1e2*[1e-5,1e-5,1e-5],...
            %                 1e-3*ones(1,3),1e2*[1e-5,1e-5,1e-5],1e-2*ones(1,4),1e-2*ones(1,3)]); %,1e7*1e-6]); 
            grad_bounds = 1e-2*diag([1e-2,1e-3*ones(1,3),1e2*[1e-5,1e-5,1e-5],...
                1e-3*ones(1,3),1e-2*[1e-5,1e-5,1e-5],1e-3*ones(1,4),1e-1*ones(1,3),...
                1e-4]); %,1e7*1e-6]); 
            % Q = diag([1e6,1e6,1e-5]); % weight on the norm of final state 
            Q = diag([2e7,2e7,1e-3]); % 1km error x-y plane & z axis produces ~1e3 
            Div_odo = 5e5; 
            length_of_gain_vector = length(grad_bounds); 
            accleration_factor = 0.4; 
            eps_factr = 0.995; 
            eps_ifactr = 40; 
            epsilon = eps_factr^0; % 1 --> generated q  | 0 --> q from gyro data 
            try % test epsilon=0 
%                 [~] = uncomment_to_disable; 
                epsilon = 0; 
                warning('epsilon is set as ZERO! ') 
            catch err
                disp(newline)
                warning('IGNORED ERROR WARNING::')
                warning(getReport(err,'extended'));
                disp(newline)
            end
            % for dynamics 
            indices = obj.start_index:obj.end_index; 
            % odo_all = obj.odo_gain_guess*[diff(obj.all_datapoints(7:9,indices)')', zeros(3,1)]; 
            vodo_all = obj.odo_gain_guess*repmat([diff(obj.odometer_max(indices)')', 0],3,1); 
            w_all = diag(obj.best_gain(4:end))*obj.all_datapoints(1:3,indices); 
            odo_data = obj.get_odometer_distance(indices); 
            % C_q = @(q) quat2rotm(q'); 
            noindices = length(indices); 
            % S_w = @(w) [0,-w(1),-w(2),-w(3);w(1),0,w(3),-w(2);w(2),-w(3),0,w(1);w(3),w(2),-w(1),0]; 
            % G_matrix = @(p) diag([(180/pi)/(obj.north_radius_of_earth + p(3)), ...
            %     -(180/pi)/((obj.east_radius_of_earth + p(3))*cosd(p(1))), 1]); % Lat Lon Up 
            % 
            try 
                load(['../OUTPUT', obj.auto_inputs.path_suffix, '/to_continue_unkwn_dT_vel_scld.mat']) 
                if epsilon~=0; epsilon = eps_factr^floor(start_iter/eps_ifactr); end 
            catch 
                start_iter = 1; 
            end 
            [f,g,h,h_ext,f_guess,g_guess,h_guess,h_ext_guess,A,B,C,C_ext,... % get_full_dynamics_manifold
                n_omega_ie,n_omega_en,Sx,Qx,C_nb,gl,G_func,f_s,f_p,q_gen,f_q,f_v,f_sns] ...
                = obj.get_full_dynamics_manifold_unknown_sampling_vel_scaled(); 
            
            % perturbation check 
            stvar_name = {'Velocity gain 4 odoadjust','Accel-x gain','Accel-y gain','Accel-z gain','Accel-x bias','Accel-y bias','Accel-z bias',...
                'Gyro-x gain','Gyro-y gain','Gyro-z gain','Gyro-x bias','Gyro-y bias','Gyro-z bias','Init Quaternion-0',...
                'Init Quaternion-x','Init Quaternion-y','Init Quaternion-z','Init Velocity-x','Init Velocity-y','Init Velocity-z','Sampling Time'}; 
            if obj.auto_mode 
                en_grad_chk = 1; 
            else 
                en_grad_chk = input('Press `1` to enable graident tuning (press ENTER to skip): '); 
            end 
            if ~isempty(en_grad_chk) % check grad_bounds 
%                 [~,~,~,v,p_gen_basecase] = obj.get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld(agb_now2,...
%                     epsilon,indices,odo_all,w_all,f,g,C_nb); 
                [~,~,~,v_gen,p_gen_basecase] = get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld_mex(agb_now2,...
                    indices,vodo_all,w_all,obj.downsampling,obj.start_gps,...
                    obj.best_initial_orientation);
                final_state_basecase = p_gen_basecase(:,end); 
                report_perturbation = nan(4,length_of_gain_vector); 
                report_perturbation(1,1) = 0; 
                for i=1:length_of_gain_vector 
                    new_agb_now2 = agb_now2; 
                    for j=0:number_of_directions 
                        new_agb_now2(i) = new_agb_now2(i) + (3^j)*accleration_factor*grad_bounds(i,i); 
%                         [~,~,~,~,p_gen,odo_gen] = obj.get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld(new_agb_now2,...
%                             epsilon,indices,odo_all,w_all,f,g,C_nb); 
                        [~,~,~,~,p_gen,odo_gen] = get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld_mex(new_agb_now2,...
                            indices,vodo_all,w_all,obj.downsampling,obj.start_gps,...
                            obj.best_initial_orientation);
                        final_state_now = p_gen(:,end); 
                        report_perturbation(2:4,i) = (final_state_now-final_state_basecase).*diag(Q).*(final_state_now-final_state_basecase); 
%                         figure(1) % <-- testing 
%                         geoplot(p_gen(1,1)',p_gen(2,1)','x'); 
%                         hold on 
%                         geoplot(p_gen(1,:)',p_gen(2,:)'); 
%                         geoplot(p_gen_basecase(1,:)',p_gen_basecase(2,:)','-.'); 
%                         geoplot(obj.end_gps(1),obj.end_gps(2),'o'); 
%                         hold off 
%                         y_fulltraj = [transpose(odo_data(1)+odo_gen)/obj.odo_gain_guess,p_gen']; 
%                         [gstart,gfinish,~,gmrkd] = obj.odo_marker_hit(y_fulltraj);
%                         obj.marker_projection(gstart,gfinish,gmrkd); 
%                         title(['Tuning parameter: ', stvar_name{i}]) 
%                         pause 
                        if norm(report_perturbation(2:4,i))>1 % approx 1 meter in x-y OR z direction 
                            report_perturbation(1,i) = j; 
                            figure(1) % <-- testing 
                            geoplot(p_gen(1,1)',p_gen(2,1)','x'); 
                            hold on 
                            geoplot(p_gen(1,:)',p_gen(2,:)'); 
                            geoplot(p_gen_basecase(1,:)',p_gen_basecase(2,:)','-.'); 
                            geoplot(obj.end_gps(1),obj.end_gps(2),'o'); 
                            hold off 
                            y_fulltraj = [transpose(odo_data(1)+odo_gen)/obj.odo_gain_guess,p_gen']; 
                            [gstart,gfinish,~,gmrkd] = obj.odo_marker_hit(y_fulltraj);
                            obj.marker_NW_distance(gstart,gfinish,gmrkd); 
                            title(['Tuning parameter: ', stvar_name{i}]) 
                            pause(0.1) 
                            break 
                        end 
                    end 
                end 
                disp('Perturbation report: ') 
                disp(report_perturbation) 
                disp('Old grad bounds: ') 
                disp(diag(grad_bounds)') 
                disp('Modified grad bounds: ') 
                disp((3.^report_perturbation(1,:)).*diag(grad_bounds)') 
                if obj.auto_mode 
                    sentvty = obj.auto_inputs.S6.sentvty; 
                else 
                    sentvty = input('Enter sensitivity of graidents (press ENTER to skip): '); 
                end 
                if ~isempty(sentvty) % modify grad_bounds 
                    grad_bounds = sentvty*diag(3.^report_perturbation(1,:))*grad_bounds; 
                end 
            end 
            % disp('Press any key to continue ... ') 
            % pause 
            %             if sum(isnan(report_perturbation(1,:)))>0 
            %                 warning('Too small graidents! ') 
            %                 report_perturbation(1,isnan(report_perturbation(1,:))) = number_of_directions; 
            %             end 
            
            % Mods
            grad_bounds(isnan(grad_bounds)) = 0; 
            lowr_limit_decs = [1,2,3,4,8,10]; % gains-scaler and dT-scaler
            lowr_limit_vals = 0.5*ones(length(lowr_limit_decs),1); 
            lowr_limit_vals(1) = 0.85; 
            upr_limit_decs = [1]; % gains-scaler and dT-scaler
            upr_limit_vals = 1.5*ones(length(upr_limit_decs),1); 

            % main loop 
            no_of_elites = floor((50/100)*number_of_directions); 
            best_grad_bound_so_far = zeros(length_of_gain_vector,no_of_elites); 
            auto_tuning_start_iter = start_iter; 
            for i=start_iter:max_steps 
                % Sub-step 2a: Choose gradients at uniformly random 
                random_gain_grads = [zeros(length_of_gain_vector,1), best_grad_bound_so_far, ...
                    2*grad_bounds*(0.5-rand(length_of_gain_vector, number_of_directions-no_of_elites-1))]; 

                % Sub-step 2b: Find new points along the random gradients 
                %                 accleration_factor = 1/i; 
                new_agb = repmat(agb_now2,1,number_of_directions) + accleration_factor*random_gain_grads; 

                % Sub-step 2c: Evaluate end gps point for all new states 
                all_costs = inf(1,number_of_directions); 
                for j=1:number_of_directions 
                    % load parameters for forward run 
                    %                     [~,~,~,v,p_gen,odo_gen] = obj.get_full_dynamical_trajectory(new_agb(:,j),...
                    %                         epsilon,indices,odo_all,w_all); 
%                     [~,~,~,v,p_gen,odo_gen] = obj.get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld(new_agb(:,j),...
%                         epsilon,indices,odo_all,w_all,f,g,C_nb); 
                    
                    % nov 6 change
                    % scale the odo gains
                    % obj.odo_gain_guess = obj.odo_gain_guess*new_agb(1,j);
                    % obj.odo_gain_backcalc = obj.odo_gain_backcalc*new_agb(1,j);
                    vodo_all = obj.odo_gain_guess*repmat([diff(obj.odometer_max(indices)')', 0],3,1); 
                    odo_data = obj.get_odometer_distance(indices); 
                    
                    lowr_satsfd = new_agb(lowr_limit_decs,j)>=lowr_limit_vals; 
                    upr_satsfd = new_agb(upr_limit_decs,j)<=upr_limit_vals; 
                    new_agb(lowr_limit_decs,j) = new_agb(lowr_limit_decs,j).*double(lowr_satsfd) + lowr_limit_vals.*double(~lowr_satsfd); 
                    new_agb(upr_limit_decs,j) = new_agb(upr_limit_decs,j).*double(upr_satsfd) + upr_limit_vals.*double(~upr_satsfd); 
                    [~,q_gen,~,v_gen,p_gen,odo_gen,rotated_gravity] = get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld_mex(new_agb(:,j),...
                        indices,vodo_all,w_all,obj.downsampling,obj.start_gps,...
                        obj.best_initial_orientation);
                    v_imu_magn = abs(new_agb(1,j))*sqrt(sum(v_gen.*v_gen,1)); 
                    [marker_costs,end_point_cost,straightning_cost,odo_cost,vel_odo_cost] ...
                        = obj.get_costs_mrkd_S6b_odovelcst_loglagr(odo_gen,p_gen,q_gen,v_gen,rotated_gravity,v_imu_magn,odo_data,noindices, ...
                        new_agb(:,j),false); 
                    all_costs(1,j) = marker_costs + end_point_cost + straightning_cost ...
                        + odo_cost + 0.2*vel_odo_cost; 
                    % start-1 < for testing > 
                    % figure(1) 
                    % geoplot(p_gen(1,1)',p_gen(2,1)','x'); 
                    % hold on 
                    % geoplot(p_gen(1,:)',p_gen(2,:)'); 
                    % geoplot(obj.end_gps(1),obj.end_gps(2),'o'); 
                    % hold off 
                    % title(['i = ', num2str(i), ' | elevation error = ', ...
                    %     num2str(obj.end_gps(3)-p_gen(3,end))]) 
                    % figure(2) 
                    % clf; stem(all_costs); hold on; 
                    % plot(min(all_costs)*ones(1,number_of_directions), 'g--'); 
                    % plot(all_costs(1)*ones(1,number_of_directions), '-'); 
                    % hold off 
                    % figure(3) 
                    % plot(odo_gen); hold on; plot(odo_data-odo_data(1)); hold off 
                    % % disp(all_costs(1,1:j)) 
                    % % disp(straightning_cost) 
                    % disp('error components = ') 
                    % % disp(transpose((final_state(1:3)-obj.end_gps').*diag(Q).*(final_state(1:3)-obj.end_gps'))) 
                    % disp(['end_cost = ', num2str(end_point_cost), ' & strtn_cost = ', num2str(straightning_cost), ...
                    %     ' & odo_cost = ', num2str(odo_cost)]) 
                    % end-1 < for testing >
                end 

                % Sub-step 2d: Choose the best and set it as new gain 
                [~,best_arg] = sort(all_costs); 
                agb_now2 = new_agb(:,best_arg(1)); 
                best_grad_bound_so_far = random_gain_grads(:,best_arg(1:no_of_elites)); 
                best_grad_bound_so_far = obj.elite_selection(best_grad_bound_so_far,no_of_elites,...
                    [25,25,nan],0.5); % [old elites, scaled elites, crossover] 
                % see plots 
                %                 [~,~,~,v,p_gen,odo_gen] = obj.get_full_dynamical_trajectory(agb_now2,...
                %                     epsilon,indices,odo_all,w_all); 
%                 [q_dot,q,v_dot,v,p_gen,odo_gen,acc_generated_body] = obj.get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld(agb_now2,...
%                     epsilon,indices,odo_all,w_all,f,g,C_nb); 
                [q_dot,q_gen,v_dot,v_gen,p_gen,odo_gen,acc_generated_body] = get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld_mex(agb_now2,...
                    indices,vodo_all,w_all,obj.downsampling,obj.start_gps,...
                    obj.best_initial_orientation);
                % final_state = p_gen(:,end); 
                % disp((final_state(1:3)-obj.end_gps').*diag(Q).*(final_state(1:3)-obj.end_gps')) 
                % lagrangian update 
                v_imu_magn = abs(agb_now2(1))*sqrt(sum(v_gen.*v_gen,1)); 
                obj.get_costs_mrkd_S6b_odovelcst_loglagr(odo_gen,p_gen,q_gen,v_gen,acc_generated_body,v_imu_magn,odo_data,noindices,agb_now2,true); 
                
                if obj.auto_inputs.en_plot(i)
                    figure(1) % <-- testing 
                    geoplot(p_gen(1,1)',p_gen(2,1)','x'); 
                    hold on 
                    geoplot(p_gen(1,:)',p_gen(2,:)'); 
                    geoplot(obj.end_gps(1),obj.end_gps(2),'o'); 
                    hold off 
                    y_fulltraj = [transpose(odo_data(1)+odo_gen)/obj.odo_gain_guess,p_gen']; 
                    [gstart,gfinish,~,gmrkd] = obj.odo_marker_hit(y_fulltraj);
                    obj.marker_NW_distance(gstart,gfinish,gmrkd);
                    title(['vel mismatch = ',num2str(vel_odo_cost)])
                    figure(2) 
                    plot(vodo_all') 
                    hold on 
                    plot(acc_generated_body') 
                    hold off 
                    xlabel('index --> ') 
                    ylabel('Acceleration --> ') 
                    legend('acc imu data-x', 'acc imu data-y', 'acc imu data-z', ...
                        'gyro rotated gravity data-x', 'gyro rotated gravity data-y',  ...
                        'gyro rotated gravity data-z', 'Location','best')
                    if best_arg(1)~=1 
                        title(['iter = ', num2str(i), ' | elevation error = ', ...
                            num2str(obj.end_gps(3)-p_gen(3,end)), ' <IMPROVED>']) 
                    else 
                        title(['iter = ', num2str(i), ' | elevation error = ', ...
                            num2str(obj.end_gps(3)-p_gen(3,end)), ' <No change>']) 
                    end 
                    figure(3) 
                    subplot(2,1,1)
                    plot(odo_gen); hold on; plot(odo_data-odo_data(1)); hold off 
                    subplot(2,1,2)
                    v_imu_magn = abs(new_agb(1,j))*sqrt(sum(v_gen.*v_gen,1));
                    v_odo_magn = obj.odo_gain_guess*diff(obj.odometer_max(obj.start_index:obj.end_index))...
                        *obj.sampling_frequency/obj.downsampling; 
                    plot(v_imu_magn); hold on; plot(v_odo_magn,'-.'); hold off 
                    pause(0.1) 
                end 

                % aip return now 
                return_enable = false; 
                if obj.auto_mode 
                    if (i-auto_tuning_start_iter+1)>=obj.auto_inputs.S6.breaking_iter 
                        try getcsv_venop(obj.auto_inputs.path_suffix, obj,odo_gen,p_gen,q_gen,v_gen,vodo_all,w_all); getcsv_venop_using_refdata_forS6(obj.auto_inputs.path_suffix, obj,odo_gen,p_gen,q_gen,v_gen,vodo_all,w_all); catch; try getcsv_venop_using_refdata_forS6(obj.auto_inputs.path_suffix, obj,odo_gen,p_gen,q_gen,v_gen,vodo_all,w_all); catch; end; end; 
                        return_enable = true;  
                    end 
                end 

                % save 
                % disp('commented'); %save(['../OUTPUT', obj.auto_inputs.path_suffix, '/best_agbgb_unkwn_dT_vel_scld.mat'], 'agb_now2', 'grad_bounds')  
                if mod(i,eps_ifactr)==0 || return_enable 
                    fname = [['../OUTPUT', obj.auto_inputs.path_suffix, '/best_agbgb_unkwn_dT_vel_scld eps '],num2str(eps_factr),'^',num2str(ceil(i/eps_ifactr)-1)]; 
                    save([fname,'.mat'], 'agb_now2', 'epsilon', 'grad_bounds') 
                    saveas(1,[fname,'.png']); saveas(2,[fname,'_imu.png']) 
                    saveas(3,[fname,'_odo.png']) 
                    saveas(1,[fname,'.fig']); saveas(2,[fname,'_imu.fig']) 
                    saveas(3,[fname,'_odo.fig']) 
                    save(['../OUTPUT', obj.auto_inputs.path_suffix, '/last_manual_settings.mat'], 'Q', 'Div_odo', 'agb_now2', 'epsilon', 'p_gen', 'grad_bounds')  
                    %
                    epsilon = eps_factr*epsilon;  
                    % 
                    start_iter = i+1; 
                    save(['../OUTPUT', obj.auto_inputs.path_suffix, '/to_continue_unkwn_dT_vel_scld.mat'], 'agb_now2', 'start_iter', 'grad_bounds')  
                    lag_vals = obj.lagrngns; 
                    save(['../OUTPUT', obj.auto_inputs.path_suffix, '/lagrangians.mat'],'lag_vals'); 
                    estimates_table = array2table([p_gen; obj.odometer_max(indices)]', 'VariableNames', {'Lat', 'lon', 'height', 'odo'});
                    writetable(estimates_table, ['../CSV_OUTPUT', obj.auto_inputs.path_suffix, '/estimates.csv']);
                    disp('Pause here if needed!'); try getcsv_venop(obj.auto_inputs.path_suffix, obj,odo_gen,p_gen,q_gen,v_gen,vodo_all,w_all); getcsv_venop_using_refdata_forS6(obj.auto_inputs.path_suffix, obj,odo_gen,p_gen,q_gen,v_gen,vodo_all,w_all); catch; try getcsv_venop_using_refdata_forS6(obj.auto_inputs.path_suffix, obj,odo_gen,p_gen,q_gen,v_gen,vodo_all,w_all); catch; end; end
                end 

                % Sub-step 2e: Progres bar 
                percent_done = i*100/max_steps; 
                
                if obj.auto_inputs.en_plot(i); clc; disp(['Progress: <', repmat('||',1,floor(percent_done/3 )), '> ', num2str(percent_done), ' % ']); end  

                if obj.auto_mode 
                    if return_enable 
                        disp('Its over in auto_tuning!') 
                        save(['../OUTPUT', obj.auto_inputs.path_suffix, '/auto_outputs.mat'],'agb_now2','q_dot','q_gen','v_dot','v_gen',...
                            'p_gen','odo_gen','acc_generated_body','vodo_all','w_all') 
                        return 
                    end 
                    if mod(i-auto_tuning_start_iter+1,obj.auto_inputs.S6.buzzer_on_iter)==0 
                        sound(sin(2*pi*2000*(0:0.5/8192:1))) 
                        % manual return 
                        return_now = false; 
                        warning('Manually break the code HERE! <--') 
                        % execute: return_now = true; 
                        if return_now 
                            return 
                        end 
                    end 
                end 
            end 
            
            %% Step 2: Render environment and IMU device best trajectory 
            figure(1) 
            % Create IMU object 
            obj.imu_device_obj = imu_device(obj.start_gps,orient_quat); 
            obj.show_markers_geoplot(); 
            obj.imu_device_obj.generate_traj_ode(acc,usegyrodata*gyr,obj.timepoints/testf); 
            obj.imu_device_obj.reset_state(); 
            obj.imu_device_obj.set_diag_gains(obj.best_gain); 
            obj.imu_device_obj.set_init_orient(orient_now/norm(orient_now)); 
            obj.imu_device_obj.generate_traj_ode(acc,usegyrodata*gyr,obj.timepoints/testf); 
            hold on 
            obj.imu_device_obj.geoplot_traj(); 
            hold off 
            
            %% Step 5: Print 
            disp('Started at location: ') 
            disp(obj.imu_device_obj.traj_table(1,2:4)) 
            disp('Now at location: ') 
            disp(obj.imu_device_obj.traj_table(end,2:4)) 
            disp('True end at location: ') 
            disp(obj.end_gps) 
            disp('Started at orientation: ') 
            disp(obj.imu_device_obj.traj_table(1,5:8)) 
            disp('Now at orientation: ') 
            disp(obj.imu_device_obj.traj_table(end,5:8)) 
            
            %% Final step: 
            disp('  ') 
            disp('<<<< All STEPS completed! >>>>') 
            if pause_dbug_fcn3(); keyboard; end; clc 
        end 
    end 
    methods %c(Access=protected) % Data setup methods, etc. 
        function default_settings(obj) 
            % Settings 
            obj.downsampling = 10*1000; % Downsampling 
            obj.sampling_frequency = 100; % Sampling Frequency (Hz) 
        end 
        function sample_static_data(obj) 
            load('../INPUT/static_data.mat') 
            obj.static_data = static; 
        end 
        function resultant_readings = correctOdometer(varargin)
            % Function to correct odometer readings exceeding the register limit
            % uncleaned_readings = varargin{1,2}
            % Initialize variables
            resultant_readings = varargin{1,2}; % copy of data
            overshoot_count = 0;
            negative_change_thresh = 5000;  % Threshold to check sudden drop
            % positive_change_thresh = 2500;  % Threshold to check spikes
            register_max_limit = 65535;     % 16-bit unsigned integer limit
            near_register_limit_thresh = register_max_limit * 0.95;  % 95% of max limit
        
            % Iterate through odometer readings to apply corrections
            for i = 2:length(resultant_readings)-1
                prev_val = varargin{1,2}(i-1);
                current_val = varargin{1,2}(i);
                next_val = varargin{1,2}(i+1);
                
                % Check for sudden drop and increase the overshoot count
                if (prev_val - current_val) >= negative_change_thresh && ...
                   prev_val >= near_register_limit_thresh
                    overshoot_count = overshoot_count + 1;
                end
                % Compute the new value with overshoot correction
                value_to_set = current_val + overshoot_count * register_max_limit;
                
                % Similarly compute next value to set
                if (current_val - next_val) >= negative_change_thresh && ...
                   current_val >= near_register_limit_thresh
                    overshoot_count_next = overshoot_count + 1;
                else
                    overshoot_count_next = overshoot_count;
                end
                next_value_to_set = varargin{1,2}(i+1) + overshoot_count_next * register_max_limit;
                
                % Check if the new value is noisy or too big and correct
                if value_to_set > next_value_to_set
                    value_to_set = mean([resultant_readings(i-1), next_value_to_set]);
                end
                
                % Update the corrected value
                resultant_readings(i) = value_to_set;
            end
            % Set the last value
            resultant_readings(end) = varargin{1,2}(end) + overshoot_count * register_max_limit;
        end        
        function sample_all_data(obj) 
            
            % Initialize database names 
            if obj.auto_mode 
                try 
                    if obj.auto_inputs.ref_data 
                        load('../INPUT/ref_data_markers_all16km.mat') % ref_data_markers.mat 
                    else 
                        error('load 1km marker data!') 
                    end 
                catch 
                    load('../INPUT/markers.mat') 
                end 
            else 
                try % Marker or Ref-marker 
                    if isempty(input('Ignore (press ENTER) for ref_data_markers: ')) 
                        load('../ref_data_markers_all16km.mat') % ref_data_markers.mat 
                        % [Limited] load('../ref_data_markers_6onwards.mat') % ref_data_markers.mat 
                    else 
                        load('../markers.mat') 
                    end 
                catch err
                    disp(newline)
                    warning('IGNORED ERROR WARNING::')
                    warning(getReport(err,'extended'));
                    disp(newline)
                end
            end 
            try % IMU 
                load('../INPUT/IMU_ID_data_file.mat','IMU_IDs'); 
                obj.IMU_ID_data = IMU_IDs; 
            catch 
                obj.IMU_ID_data(1).name = 'IMUdata1'; % ST 
                obj.IMU_ID_data(1).associated_file = '2021101814.log'; 
                obj.IMU_ID_data(2).name = 'IMUdata2a'; 
                obj.IMU_ID_data(2).associated_file = '2021101815.log'; 
                obj.IMU_ID_data(3).name = 'IMUdata2b'; 
                obj.IMU_ID_data(3).associated_file = '2021101815.log'; 
                obj.IMU_ID_data(4).name = 'IMUdata2c'; 
                obj.IMU_ID_data(4).associated_file = '2021101815.log'; 
                obj.IMU_ID_data(5).name = 'IMUdata2d'; % MM1 
                obj.IMU_ID_data(5).associated_file = '2021101815.log'; 
                obj.IMU_ID_data(6).name = 'IMUdata2e'; 
                obj.IMU_ID_data(6).associated_file = '2021101815.log'; 
                obj.IMU_ID_data(7).name = 'IMUdata2f'; 
                obj.IMU_ID_data(7).associated_file = '2021101815.log'; 
                obj.IMU_ID_data(8).name = 'IMUdata2g'; 
                obj.IMU_ID_data(8).associated_file = '2021101815.log'; 
                obj.IMU_ID_data(9).name = 'IMUdata3a'; 
                obj.IMU_ID_data(9).associated_file = '2021101816.log'; 
                obj.IMU_ID_data(10).name = 'IMUdata3b'; 
                obj.IMU_ID_data(10).associated_file = '2021101816.log'; 
                obj.IMU_ID_data(11).name = 'IMUdata3c'; %  
                obj.IMU_ID_data(11).associated_file = '2021101816.log'; 
                obj.IMU_ID_data(12).name = 'IMUdata3d'; 
                obj.IMU_ID_data(12).associated_file = '2021101816.log'; 
                obj.IMU_ID_data(13).name = 'IMUdata3e'; 
                obj.IMU_ID_data(13).associated_file = '2021101816.log'; 
                obj.IMU_ID_data(14).name = 'IMUdata4a'; 
                obj.IMU_ID_data(14).associated_file = '2021101817.log'; 
                obj.IMU_ID_data(15).name = 'IMUdata4b'; %  
                obj.IMU_ID_data(15).associated_file = '2021101817.log'; 
                obj.IMU_ID_data(16).name = 'IMUdata4c'; 
                obj.IMU_ID_data(16).associated_file = '2021101817.log'; 
                obj.IMU_ID_data(17).name = 'IMUdata4d'; 
                obj.IMU_ID_data(17).associated_file = '2021101817.log'; 
                obj.IMU_ID_data(18).name = 'IMUdata5a'; 
                obj.IMU_ID_data(18).associated_file = '2021101818.log'; 
                obj.IMU_ID_data(19).name = 'IMUdata5b'; %  
                obj.IMU_ID_data(19).associated_file = '2021101818.log'; 
                obj.IMU_ID_data(20).name = 'IMUdata5c'; 
                obj.IMU_ID_data(20).associated_file = '2021101818.log'; 
                obj.IMU_ID_data(21).name = 'IMUdata5d'; 
                obj.IMU_ID_data(21).associated_file = '2021101818.log'; 
                obj.IMU_ID_data(22).name = 'IMUdata6a'; 
                obj.IMU_ID_data(22).associated_file = '2021101819.log'; 
                obj.IMU_ID_data(23).name = 'IMUdata6b'; %  
                obj.IMU_ID_data(23).associated_file = '2021101819.log'; 
                obj.IMU_ID_data(24).name = 'IMUdata6c'; 
                obj.IMU_ID_data(24).associated_file = '2021101819.log'; 
                obj.IMU_ID_data(25).name = 'IMUdata6d'; 
                obj.IMU_ID_data(25).associated_file = '2021101819.log'; 
            end 
            
            % Loading datapoints 
            offst = obj.downsampling-1; 
            prev_mean = 0; 
            n_total = 0; 
            tp_start = 0; 
            obj.all_timepoints = []; 
            obj.all_datapoints = []; 
            obj.raw_datapoints = []; 
            for idp=1:length(obj.IMU_ID_data) 
                load(['../INPUT/',obj.IMU_ID_data(idp).name,'.mat']); 
                
                % size of datapoints 
                sizeof_data = size(data.VarName2,1); 
                n = ceil((sizeof_data-(obj.downsampling-offst-1))/obj.downsampling); % new_sz%ds + 1
                
                tlim = tp_start+(n-1)*obj.downsampling/obj.sampling_frequency; 
                obj.all_timepoints = [obj.all_timepoints, linspace(tp_start,tlim,n)]; 
                tp_start = tlim + obj.downsampling/obj.sampling_frequency; 
                n_total = n_total + n; 
                
                % Load data into variables 
                pick_indices = (obj.downsampling-offst) + (0:obj.downsampling:(n-1)*obj.downsampling); 
                    % 1st_indx + 0, ds, 2*ds, ... , (n-1)*ds 
                dp_now = zeros(size(data,2),n); 
                rawdp_now = zeros(size(data,2),n); 
                sel = repmat(pick_indices',1,obj.downsampling) + repmat(1:obj.downsampling,length(pick_indices),1); 
                % 1 
                dp_now(:,1) = (offst*prev_mean' + (obj.downsampling-offst)*mean(table2array(data(1:pick_indices(1),:)),1)')...
                    /obj.downsampling; 
                rawdp_now(:,1) = table2array(data(1,:))'; 
                % 2:end 
                for i=size(data,2):-1:1 
                    the_ith_data = table2array(data(:,i)); 
                    mean_downsampled_data = mean(the_ith_data(sel(1:end-1,:)),2); 
                    dp_now(i,2:end) = mean_downsampled_data'; 
                end 
                rawdp_now(:,2:end) = table2array(data(sel(1:end-1,end),:))'; 
                obj.all_datapoints = [obj.all_datapoints, dp_now]; 
                obj.raw_datapoints = [obj.raw_datapoints, rawdp_now]; 
                offst = sizeof_data - pick_indices(end); 
                % end onwarobj.ds (for next iteration) 
                prev_mean = mean(table2array(data(pick_indices(end):end,:)),1); 
                obj.IMU_ID_data(idp).indices = pick_indices; 
                % 
                clear data 
                
                % Safety checks 
                if size(obj.all_timepoints,2)==size(obj.all_datapoints,2) 
                    disp([' <<<< all ok! --- DataID-',num2str(idp),' >>>> ']) 
                    disp(['Number of points (additional) = ',num2str(n)]) 
                    disp(['Number of points (total) = ',num2str(n_total)]) 
                    disp(['Downsample value (counts) = ',num2str(obj.downsampling)]) 
                    disp(['Sampling frequency (Hz) = ',num2str(obj.sampling_frequency)]) 
                    disp(['Simulation time (secs) = ',num2str(tlim)]) 
                    disp(' ') 
                else 
                    warning('need correction! ') 
                end 
            end 

            % Applying moving average filter 
            % obj.raw_datapoints = obj.all_datapoints; 
            % obj.get_moving_average_of_all_datapoints(); 
            
            % Processing data: Marker distances + Marker IMU indexing
            odo1_correct = obj.correctOdometer(obj.all_datapoints(end-2,:));
            odo2_correct = obj.correctOdometer(obj.all_datapoints(end-1,:));
            odo3_correct = obj.correctOdometer(obj.all_datapoints(end,:));  
            obj.all_datapoints()
            % obj.odometer_max = max([odo1_correct; odo2_correct; odo3_correct]);
            obj.odometer_max = odo3_correct;
            % obj.odometer_max = obj.all_datapoints(end,:);
            
            % separation points for the data 
            marker_no = 1; 
            % markers.odo = max([markers.odo1,markers.odo2,markers.odo3]')'; 
            markers.odo = markers.odo3;
            no_all_vm = 90; 
            new_row_count = 0; 
            new_markers = markers; 
            obj.map_markers = 1:size(markers,1); 
            try % insert VM markers for straight lines 
                is_curved = marker_curve_info.curved; 
                is_fwd_curved = marker_curve_info.fwd_curved; 
                is_bckwd_curved = marker_curve_info.bckwd_curved; 
                disp(marker_curve_info) 
                if obj.auto_mode 
                    novm = obj.auto_inputs.number_of_vm; 
                else 
                    novm = input('Number of VM for straight lines [Default is 0]: '); 
                end 
                if isempty(novm) || novm==0; error('skip VM'); end 
                for mid = 1:size(marker_curve_info,1) 
                    if ~is_curved(mid)  % `ahead data` or `behind data` or `none` for VM markers points 
                        vm_start = [markers.lat(mid),markers.lon(mid),markers.hgt(mid)]; 
                        vm_end = [markers.lat(mid+1),markers.lon(mid+1),markers.hgt(mid+1)]; 
                        odo_vms = markers.odo(mid); 
                        odo_vme = markers.odo(mid+1); 
                        start_sel = 1; end_sel = 1+2*novm; 
                        mid_sel = 1+novm; 
                        vm_info = 'ahead'; 
                    elseif ~is_curved(max(1,mid-1)) 
                        vm_start = [markers.lat(mid-1),markers.lon(mid-1),markers.hgt(mid-1)]; 
                        vm_end = [markers.lat(mid),markers.lon(mid),markers.hgt(mid)]; 
                        odo_vms = markers.odo(mid-1); 
                        odo_vme = markers.odo(mid); 
                        start_sel = no_all_vm; end_sel = no_all_vm+2*novm; 
                        mid_sel = no_all_vm+novm; 
                        vm_info = 'behind'; 
                    else 
                        continue 
                    end 
                    del_odo_all_vm = (odo_vme-odo_vms)/(no_all_vm-1); 
                    start_odo_extended = -novm*del_odo_all_vm; 
                    end_odo_extended = (no_all_vm-1+novm)*del_odo_all_vm; 
                    odo_all_vm = odo_vms + (start_odo_extended:del_odo_all_vm:end_odo_extended); 
                    if is_bckwd_curved(mid) % `fwd` extension is bad 
                        start_sel = start_sel+novm; 
                    end 
                    if is_fwd_curved(mid) % `bckwd` extension is bad 
                        end_sel = end_sel-novm; %no_all_vm+novm; 
                    end 
                    odo_in_use_vm_bckwd = odo_all_vm(start_sel:(mid_sel-1)); 
                    odo_in_use_vm_fwd = odo_all_vm((mid_sel+1):end_sel); 
                    % ...(1+novm+1):(1+2*novm),(end-2*novm):(end-novm-1),(end-novm+1):end_sel
                    if ~isempty(odo_in_use_vm_bckwd) % create all bckwd rows 
                        alpha_lc_bckwd = (odo_in_use_vm_bckwd-odo_vms)/(odo_vme-odo_vms); 
                        tot_vm_bckwd = size(alpha_lc_bckwd,2); 
                        gps_in_use_vm_bckwd = (1-kron([1,1,1],alpha_lc_bckwd')).*repmat(vm_start,tot_vm_bckwd,1) ...
                            + kron([1,1,1],alpha_lc_bckwd').*repmat(vm_end,tot_vm_bckwd,1); 
                        clear new_rows_bckwd 
                        new_rows_bckwd(tot_vm_bckwd,1).name = ''; 
                        for i_vm=1:tot_vm_bckwd 
                            new_rows_bckwd(i_vm).name = ['VM-',vm_info,'-bckwd-',num2str(mid),'-',num2str(i_vm)]; 
                            new_rows_bckwd(i_vm).lat = gps_in_use_vm_bckwd(i_vm,1); 
                            new_rows_bckwd(i_vm).lon = gps_in_use_vm_bckwd(i_vm,2); 
                            new_rows_bckwd(i_vm).odo1 = nan; 
                            new_rows_bckwd(i_vm).odo2 = nan; 
                            new_rows_bckwd(i_vm).odo3 = nan; 
                            new_rows_bckwd(i_vm).odoSum = nan; 
                            new_rows_bckwd(i_vm).hgt = gps_in_use_vm_bckwd(i_vm,3); 
                            new_rows_bckwd(i_vm).VarName9 = nan; 
                            new_rows_bckwd(i_vm).VarName10 = nan; 
                            new_rows_bckwd(i_vm).odo = odo_in_use_vm_bckwd(i_vm); 
                        end 
                        new_markers = [new_markers(1:(new_row_count+mid-1),:);...
                            struct2table(new_rows_bckwd);new_markers((new_row_count+mid):end,:)]; 
                        new_row_count = new_row_count + tot_vm_bckwd; 
                    end 
                    obj.map_markers(mid) = new_row_count + mid; 
                    if ~isempty(odo_in_use_vm_fwd) % create all fwd rows 
                        alpha_lc_fwd = (odo_in_use_vm_fwd-odo_vms)/(odo_vme-odo_vms); 
                        tot_vm_fwd = size(alpha_lc_fwd,2); 
                        gps_in_use_vm_fwd = (1-kron([1,1,1],alpha_lc_fwd')).*repmat(vm_start,tot_vm_fwd,1) ...
                            + kron([1,1,1],alpha_lc_fwd').*repmat(vm_end,tot_vm_fwd,1); 
                        clear new_rows_fwd 
                        new_rows_fwd(tot_vm_fwd,1).name = ''; 
                        for i_vm=1:tot_vm_fwd 
                            new_rows_fwd(i_vm).name = ['VM-',vm_info,'-fwd-',num2str(mid),'-',num2str(i_vm)]; 
                            new_rows_fwd(i_vm).lat = gps_in_use_vm_fwd(i_vm,1); 
                            new_rows_fwd(i_vm).lon = gps_in_use_vm_fwd(i_vm,2); 
                            new_rows_fwd(i_vm).odo1 = nan; 
                            new_rows_fwd(i_vm).odo2 = nan; 
                            new_rows_fwd(i_vm).odo3 = nan; 
                            new_rows_fwd(i_vm).odoSum = nan; 
                            new_rows_fwd(i_vm).hgt = gps_in_use_vm_fwd(i_vm,3); 
                            new_rows_fwd(i_vm).VarName9 = nan; 
                            new_rows_fwd(i_vm).VarName10 = nan; 
                            new_rows_fwd(i_vm).odo = odo_in_use_vm_fwd(i_vm); 
                        end 
                        new_markers = [new_markers(1:(new_row_count+mid),:);...
                            struct2table(new_rows_fwd);new_markers((new_row_count+mid+1):end,:)]; 
                        new_row_count = new_row_count + tot_vm_fwd; 
                    end 
                end 
            catch err
                disp(newline)
                warning('IGNORED ERROR WARNING::')
                warning(getReport(err,'extended'));
                disp(newline)
            end
            obj.marker_data = new_markers; 
            total_markers = length(obj.marker_data.odo); 
            obj.marker_gps_distances = zeros(1,total_markers); 
            obj.marker_ref_odo_distances = zeros(1,total_markers); 
            for imkpt=1:total_markers-1 
                %     obj.marker_gps_distances(imkpt+1) = gps2meters(obj.markers.lat(imkpt),obj.markers.lon(imkpt),...
                %         obj.markers.lat(imkpt+1),obj.markers.lon(imkpt+1)); 
                [end_x,end_y,end_z] = latlon2local(obj.marker_data.lat(imkpt+1),obj.marker_data.lon(imkpt+1),...
                    obj.marker_data.hgt(imkpt+1),[obj.marker_data.lat(imkpt),obj.marker_data.lon(imkpt),obj.marker_data.hgt(imkpt)]); 
                obj.marker_gps_distances(imkpt+1) = norm([end_x,end_y,end_z]); 
                obj.marker_ref_odo_distances(imkpt+1) = obj.odo_gain_guess...
                    *(obj.marker_data.odo(imkpt+1)-obj.marker_data.odo(imkpt)); 
            end 
            obj.marker_cumulative_gps_distances = cumsum(obj.marker_gps_distances); 
            obj.marker_cumulative_ref_odo_distances = cumsum(obj.marker_ref_odo_distances); 
            % 
            obj.separation_indxs = nan(1,total_markers); 
            obj.uncleaned_odometer_max = obj.odometer_max; 
            % obj.odometer_max = obj.correctOdometer(obj.uncleaned_odometer_max);
            
            disp('Finding marker separation points: ')
            slp_avg_pts = 20; del_spike = 100; 
            % tst_delodo = []; 
            sz_odomax = length(obj.odometer_max); 
            for indxpt=1:n_total 
                try 
                indxpt_10_smpls = indxpt+(1:10); 
                indxpt_10_smpls(indxpt_10_smpls>sz_odomax) = sz_odomax; 
                if obj.odometer_max(indxpt)>=obj.marker_data.odo(marker_no) ...
                        && mean(obj.odometer_max(indxpt_10_smpls))>=obj.marker_data.odo(marker_no) 
                    % there are spikes (plot odometer_max to check it!) 
                    disp(['Reached marker `',char(obj.marker_data.name(marker_no)),'` at odometer location ',...
                        num2str(obj.marker_data.odo(marker_no))]);  
                    obj.separation_indxs(marker_no) = indxpt; 
                    marker_no = marker_no+1; 
                end 
                catch 
                    disp('here')
                end 
                if indxpt>slp_avg_pts && indxpt<n_total 
                    if abs(obj.odometer_max(indxpt)-obj.odometer_max(indxpt-1))>del_spike 
                        slope_odo = mean(obj.odometer_max(indxpt-(1:slp_avg_pts))-obj.odometer_max(indxpt-(2:(slp_avg_pts+1)))); 
                        obj.odometer_max(indxpt) = round(obj.odometer_max(indxpt-1) + slope_odo); 
                    end 
                    % tst_delodo = [tst_delodo,abs(obj.odometer_max(indxpt)-obj.odometer_max(indxpt-1))]; 
                end 
                if marker_no>total_markers 
                    disp('all obj.markers sorted'); 
                    break 
                end 
            end 
            disp(' ') 
            
            % Extras 
            disp('Time (mins)') 
            disp((obj.separation_indxs(2:6)-obj.separation_indxs(1:5))*(obj.downsampling/obj.sampling_frequency)/60) 

            % Lets begin  
            obj.last_index_loc = find(~isnan(obj.separation_indxs),1,'last'); 
            obj.last_index = obj.separation_indxs(obj.last_index_loc); 
        end 
        function set_data_subset(obj) 
            % New Datapoint 
            disp(' ') 
            tmp_litst_of_markers = find(~isnan(obj.separation_indxs(obj.map_markers))); 
            disp(['Choice: ',num2str(tmp_litst_of_markers(1)),' to ',num2str(tmp_litst_of_markers(end))]) 
            if obj.auto_mode 
                tmp_selected_marker_indices = obj.auto_inputs.selected_marker_indices; 
            else 
                tmp_selected_marker_indices = input('Enter array: '); 
            end 
            if length(tmp_selected_marker_indices)<=1 
                tmp_selected_marker_indices = 1:2; 
            end 
            obj.selected_marker_indices = obj.map_markers(tmp_selected_marker_indices(1)):...
                obj.map_markers(tmp_selected_marker_indices(2)); 
            chosen_sep_indx = obj.separation_indxs(obj.selected_marker_indices); 
            if ~isnan(chosen_sep_indx) 
                obj.start_index = chosen_sep_indx(1); 
                obj.end_index = chosen_sep_indx(end); 
                obj.timepoints = obj.all_timepoints(1,obj.start_index:obj.end_index); 
                obj.timepoints = obj.timepoints-obj.timepoints(1); tlim = obj.timepoints(end); 
                obj.datapoints = obj.all_datapoints(:,obj.start_index:obj.end_index); 
                % 
                start_choice = obj.selected_marker_indices(1); 
                end_choice = obj.selected_marker_indices(end); 
                obj.start_gps = [obj.marker_data.lat(start_choice),obj.marker_data.lon(start_choice),...
                    obj.marker_data.hgt(start_choice)]; 
                obj.end_gps = [obj.marker_data.lat(end_choice),obj.marker_data.lon(end_choice),...
                    obj.marker_data.hgt(end_choice)]; 
                obj.start_end_distance = obj.marker_cumulative_gps_distances(end_choice) ...
                    - obj.marker_cumulative_gps_distances(start_choice); 
                start_end_ref_odo_distance = obj.marker_cumulative_ref_odo_distances(end_choice) ...
                    - obj.marker_cumulative_ref_odo_distances(start_choice); 
                disp(' '); 
                disp(['Starting from `',char(obj.marker_data.name(start_choice)),'` ']); 
                disp(['Ending at `',char(obj.marker_data.name(end_choice)),'` ']); 
                disp(['GPS based distance between marker points (meters): ',num2str(obj.start_end_distance)]); 
                disp(['Reference odometer based distance between marker points (meters): ',num2str(start_end_ref_odo_distance)]); 
                disp(['Total number of datapoints: ',num2str(size(obj.datapoints,2))]); 
            else 
                warning('Bad choice of points! '); 
            end 
        end 
        function sample_vendor_and_ref_data(obj) 
            try % Vendor data 
                load('../INPUT/vendor_st_mm1.mat'); 
            catch 
                disp('Couldn`t load vendor data! '); 
                gps_odo_data = []; 
            end 
            obj.vendor_data = gps_odo_data; 
            try % Reference data 
                load('../OPTIONAL_INPUT/ref_data.mat'); 
            catch 
                disp('Couldn`t load reference data! '); 
                IMUDATARESULTFORWELD = []; 
            end 
            obj.ref_data = IMUDATARESULTFORWELD; 
        end 
        function init_lagrangians(obj) 
            try load(['../OUTPUT', obj.auto_inputs.path_suffix, '/lagrangians.mat'],'lag_vals'); catch  
                lag_vals.marker = 1; 
            end 
            obj.lagrngns = lag_vals; 
        end 
        function update_lagrangians(obj,marker_err_vec) 
            marker_subgrad = sum(abs(marker_err_vec-5)); % feasible is negative (1m circle)
            marker_subgrad = max(-obj.slack_cap,min(marker_subgrad,obj.slack_cap)); 
            obj.lagrngns.marker = obj.lagrngns.marker ...
                + marker_subgrad*obj.dlgrngn_diter/100; 
            obj.lagrngns.marker = max(0,obj.lagrngns.marker); % lower bounded by 0 
        end 
        function update_loglagrangians(obj,marker_err_vec) 
            marker_subgrad = sum(20*log(marker_err_vec/5)); % feasible is negative (1m circle)
            marker_subgrad = max(-obj.slack_cap,min(marker_subgrad,obj.slack_cap)); 
            obj.lagrngns.marker = obj.lagrngns.marker ...
                + marker_subgrad*obj.dlgrngn_diter/100; 
            obj.lagrngns.marker = max(0,obj.lagrngns.marker); % lower bounded by 0 
        end 
        function [gstart,gfinish,ghit,gmrkd,hit_indxs,mrkd_indxs] = odo_marker_hit(obj,y_fulltraj) 
            gstart = obj.marker_data{obj.selected_marker_indices(1:end-1),2:3}; 
            gfinish = obj.marker_data{obj.selected_marker_indices(2:end),2:3}; 
            odomrkrd = obj.marker_data{obj.selected_marker_indices,end}; 
            hit_indxs = nan(length(odomrkrd)-1,1); 
            for i=2:length(odomrkrd) 
                tmp = find(y_fulltraj(:,1)>odomrkrd(i),1,'first'); 
                if isempty(tmp) 
                    hit_indxs(i-1) = size(y_fulltraj,1); 
                else 
                    hit_indxs(i-1) = tmp; 
                end 
            end 
            ghit = y_fulltraj(hit_indxs,2:3); 
            mrkd_indxs = obj.separation_indxs(obj.selected_marker_indices(2:end)) ...
                - obj.separation_indxs(obj.selected_marker_indices(1)) + 1; 
            gmrkd = y_fulltraj(mrkd_indxs,2:3); 
        end 
        function err_res = marker_projection(varargin) % axial 
            if nargin==4 
                [obj,gstart,gfinish,ghit] = varargin{:}; 
                enable_plot = true; 
            elseif nargin==5 
                [obj,gstart,gfinish,ghit,enable_plot] = varargin{:}; 
            end 
            dg = gfinish-gstart; 
            dg_uv = dg./sqrt(sum(dg.*dg,2)); % normalize 
            obj.error_results = []; 
            % projection gps locations 
            prjctn = sum(dg_uv.*(gfinish-ghit),2); % dot product unit vector with GPS error 
            gn = gfinish-repmat(prjctn,1,2).*dg_uv; 
            hold on 
            for i=1:size(gstart,1) 
                if enable_plot 
                    geoplot(ghit(i,1),ghit(i,2),'diamond') 
                    geoplot(gn(i,1),gn(i,2),'.') 
                    geoplot([gn(i,1);gfinish(i,1)],[gn(i,2);gfinish(i,2)]) 
                end 
                % obj.error_results = [obj.error_results;...
                %     prjctn(i)*mean([obj.east_radius_of_earth,obj.north_radius_of_earth])*pi/180]; 
                obj.error_results = [obj.error_results;...
                    gps2meters(gfinish(i,1),gfinish(i,2),gn(i,1),gn(i,2))]; 
                if enable_plot 
                    text(gfinish(i,1)-1e-5,gfinish(i,2)+1e-5,[num2str(obj.error_results(i)),' m']); 
                end 
            end 
            hold off 
            err_res = obj.error_results; 
        end 
        function err_res = marker_NW_distance(varargin) 
            if nargin==4 
                [obj,gstart,gfinish,ghit] = varargin{:}; 
                enable_plot = true; 
            elseif nargin==5 
                [obj,gstart,gfinish,ghit,enable_plot] = varargin{:}; 
            end 
            obj.error_results = []; 
            hold on 
            for i=1:size(gstart,1) 
                if enable_plot 
                    geoplot(ghit(i,1),ghit(i,2),'diamond') 
                    geoplot(gfinish(i,1),gfinish(i,2),'.') 
                    geoplot([ghit(i,1);gfinish(i,1)],[ghit(i,2);gfinish(i,2)]) 
                end 
                % obj.error_results = [obj.error_results;...
                %     prjctn(i)*mean([obj.east_radius_of_earth,obj.north_radius_of_earth])*pi/180]; 
                obj.error_results = [obj.error_results;...
                    gps2meters(gfinish(i,1),gfinish(i,2),ghit(i,1),ghit(i,2))]; 
                if enable_plot 
                    text(gfinish(i,1)-1e-5,gfinish(i,2)+1e-5,[num2str(obj.error_results(i)),' m']); 
                end 
            end 
            hold off 
            err_res = obj.error_results; 
        end 
        function [gstart,gfinish,ghit,gmrkd,hit_indxs,mrkd_indxs] = wrong_odo_hidden_marker_hit(obj,y_fulltraj) 
            hidden_sel_mrkr_indxs = obj.selected_marker_indices(1):obj.selected_marker_indices(end); 
            gstart = obj.marker_data{hidden_sel_mrkr_indxs(1:end-1),2:3}; 
            gfinish = obj.marker_data{hidden_sel_mrkr_indxs(2:end),2:3}; 
            odomrkrd = obj.marker_data{hidden_sel_mrkr_indxs,end}; 
            hit_indxs = nan(length(odomrkrd)-1,1); 
            for i=2:length(odomrkrd) 
                tmp = find(y_fulltraj(:,1)>odomrkrd(i),1,'first'); 
                if isempty(tmp) 
                    hit_indxs(i-1) = size(y_fulltraj,1); 
                else 
                    hit_indxs(i-1) = tmp; 
                end 
            end 
            ghit = y_fulltraj(hit_indxs,2:3); 
            mrkd_indxs = obj.separation_indxs(hidden_sel_mrkr_indxs(2:end)) ...
                - obj.separation_indxs(hidden_sel_mrkr_indxs(1)); % + 1; 
            gmrkd = y_fulltraj(mrkd_indxs,2:3); 
        end 
        function [gstart,gfinish,ghit,gmrkd,hit_indxs,mrkd_indxs] = odo_hidden_marker_hit(obj,y_fulltraj) 
            hidden_sel_mrkr_indxs = obj.selected_marker_indices(1):obj.selected_marker_indices(end); 
            gstart = obj.marker_data{hidden_sel_mrkr_indxs(1:end-1),2:3}; 
            gfinish = obj.marker_data{hidden_sel_mrkr_indxs(2:end),2:3}; 
            odomrkrd = obj.marker_data{hidden_sel_mrkr_indxs,end}; 
            hit_indxs = nan(length(odomrkrd)-1,1); 
            for i=2:length(odomrkrd) 
                tmp = find(y_fulltraj(:,1)>odomrkrd(i),1,'first'); 
                if isempty(tmp) 
                    hit_indxs(i-1) = size(y_fulltraj,1); 
                else 
                    hit_indxs(i-1) = tmp; 
                end 
            end 
            ghit = y_fulltraj(hit_indxs,2:3); 
            mrkd_indxs = obj.separation_indxs(hidden_sel_mrkr_indxs(2:end)) ...
                - obj.separation_indxs(hidden_sel_mrkr_indxs(1)) + 1; 
            gmrkd = y_fulltraj(mrkd_indxs,2:3); 
        end 
    end 
end 

%% Tests below 
function new_obj = test_simulate_ili_run_case1() 
clc; 
disp('This is a test! ') 
disp('First case: ') 
new_obj = simulate_ili_run(); 
new_obj.about(); 
new_obj.main_basic_run(); 

% if pause_dbug_fcn3(); keyboard; end; clc 

end 

function new_obj = test_simulate_ili_run_case2() 
clc; 
disp('This is a test! ') 
disp('Second case: ') 
new_obj = simulate_ili_run(); 
new_obj.about(); 
new_obj.main_basic_run(); 

% if pause_dbug_fcn3(); keyboard; end; clc 

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
