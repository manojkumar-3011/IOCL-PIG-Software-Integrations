function [uqop_table,op_array] = getcsv_venop(varargin) 
% Gives GPS coordinates at odometer locations and weld locations (just like the vendor) 

% Extract the last value from varargin as path_suffix
path_suffix = varargin{1};   % Get the last value
varargin(1) = [];            % Remove the last value from varargin

%% At all odometer locations 
if nargin==4 
    [ac2_sim_ig,store_traj,selected_marker_indices,fname] = varargin{:}; 
elseif nargin==3  
    [ac2_sim_ig,store_traj,selected_marker_indices] = varargin{:}; 
    fname = 'op.csv'; 
elseif nargin==2 
    [ac2_sim_ig,store_traj] = varargin{:}; 
    fname = 'op.csv'; 
    selected_marker_indices = ac2_sim_ig.selected_marker_indices; 
else 
    [ac2_sim_ig,odo_gen,p_gen,q,v,g_all,w_all] = varargin{:}; 
    lnv = size(q,2); 
    store_traj = [ones(lnv,1),odo_gen(:,1:lnv)',p_gen(:,1:lnv)',q',v',nan(lnv,1),...
        g_all(:,1:lnv)',w_all(:,1:lnv)']; 
    fname = 'op.csv'; 
    selected_marker_indices = ac2_sim_ig.selected_marker_indices; 
end 

% 
factr = 1; 
tmp_sel_mar_indx_indx = 1:length(ac2_sim_ig.selected_marker_indices); 
tmp_to_use = tmp_sel_mar_indx_indx(1:factr:end); 
tmp_to_not_use = tmp_sel_mar_indx_indx; tmp_to_not_use(1:factr:end) = []; 
mes_indx_sel = ac2_sim_ig.selected_marker_indices(tmp_to_use); 
mes_indx = ac2_sim_ig.separation_indxs(mes_indx_sel); 
C_swtch_data = mes_indx - mes_indx(1); 
mes_markers = table2array(ac2_sim_ig.marker_data(mes_indx_sel,[2,3,7])); 
vm_data = gen_vm_at_sampletime(ac2_sim_ig,mes_markers,C_swtch_data); 

% 
op_title = {'odo','Lat','lon','Latvm','lonvm'}; 
odo_op = ac2_sim_ig.odometer_max(ac2_sim_ig.start_index) ...
    + round(store_traj(:,2)/ac2_sim_ig.odo_gain_guess); 
gps_op = store_traj(:,3:4); 
% 
op_array = [odo_op,gps_op]; 
[~,uq_indx] = unique(odo_op,'last'); 
uqop_array = [op_array(uq_indx,:),vm_data(uq_indx,2:3)]; 
uqop_table = array2table(uqop_array,"VariableNames",op_title); 

disp(uqop_table(1:20,:)) 
disp('... lots more ...') 
disp(' ') 
disp('[ saved table]') 
disp(' ') 

writetable(uqop_table,[['../CSV_OUTPUT', path_suffix, '/At_odom_'],fname]) 

%% At welds 
[gstart,gfinish,ghit,gmrkd] = ac2_sim_ig.get_op_at_markers(op_array); 
[gstart_vm,gfinish_vm,ghit_vm,gmrkd_vm] = ac2_sim_ig.get_op_at_markers(vm_data); 
mop_title = {'id','Lat','lon','weld','Latref','lonref','odomax','Latvm','lonvm','errref','errvmref'}; 
mrkrop_array = [(selected_marker_indices(1):selected_marker_indices(end))',[gstart(1,:);gmrkd(1:end,:)],...
    ac2_sim_ig.marker_data{ac2_sim_ig.selected_marker_indices(1):ac2_sim_ig.selected_marker_indices(end),[1:3,8]},...
    [gstart_vm(1,:);gmrkd_vm(1:end,:)]]; 
mrkrop_array = [mrkrop_array, sqrt((double(mrkrop_array(:,2))-double(mrkrop_array(:,5))).^2 ...
    +(double(mrkrop_array(:,3))-double(mrkrop_array(:,6))).^2)*111000,...
    sqrt((double(mrkrop_array(:,8))-double(mrkrop_array(:,5))).^2 ...
    +(double(mrkrop_array(:,9))-double(mrkrop_array(:,6))).^2)*111000]; 
mrkrop_table = array2table(mrkrop_array,"VariableNames",mop_title); 

writetable(mrkrop_table,[['../CSV_OUTPUT', path_suffix, '/At_weld_'],fname]) 

end 