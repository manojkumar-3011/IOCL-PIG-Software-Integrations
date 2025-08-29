function [uqop_table,op_array] = getcsv_venop_using_refdata_forS6(varargin) 
% Gives GPS coordinates at odometer locations and weld locations (just like the vendor) 
% Using 'ref_data' instead of 'marker_data'. 

odo_ref_sel = 2; % which odo 

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
elseif nargin==7 
    [ac2_sim_ig,odo_gen,p_gen,q,v,g_all,w_all] = varargin{:}; 
    lnv = size(q,2); 
    store_traj = [ones(lnv,1),odo_gen(:,1:lnv)',p_gen(:,1:lnv)',q',v',nan(lnv,1),...
        g_all(:,1:lnv)',w_all(:,1:lnv)']; 
    fname = 'op.csv'; 
    selected_marker_indices = ac2_sim_ig.selected_marker_indices; 
else 
    [ac2_sim_ig,odo_gen,p_gen,q,v,g_all,w_all,fname] = varargin{:}; 
    lnv = size(q,2); 
    store_traj = [ones(lnv,1),odo_gen(:,1:lnv)',p_gen(:,1:lnv)',q',v',nan(lnv,1),...
        g_all(:,1:lnv)',w_all(:,1:lnv)']; 
    selected_marker_indices = ac2_sim_ig.selected_marker_indices; 
end 

% changing to ref_data from marker_data 
sel_mrkrdata = ac2_sim_ig.marker_data(ac2_sim_ig.selected_marker_indices,:); 
% odosum_ref_data = sum(ac2_sim_ig.ref_data{:,4:6},2); 
odo_ref_data = ac2_sim_ig.ref_data{:,3+odo_ref_sel}; 
for i=1:length(odo_ref_data) 
    if odo_ref_data(i)<=sel_mrkrdata.odo(1) 
        ref_data_start_indx = i; 
    end 
    if odo_ref_data(i)>=sel_mrkrdata.odo(end) 
        if abs(odo_ref_data(i)-sel_mrkrdata.odo(1))...
                <abs(odo_ref_data(i)-sel_mrkrdata.odo(end))% start is closer 
            ref_data_end_indx = i-1; 
            break 
        else % end is closer 
            ref_data_start_indx = ref_data_start_indx + 1; 
            ref_data_end_indx = i; 
            break 
        end 
    end 
end 
sel_refdata = ac2_sim_ig.ref_data(ref_data_start_indx:ref_data_end_indx,:); 
mes_markers = sel_refdata{[1,end],[2,3,7]}; 
% 
c2_sim_ig_struct.odo_gain_guess = ac2_sim_ig.odo_gain_guess; 
c2_sim_ig_struct.odometer_max = ac2_sim_ig.odometer_max; 
c2_sim_ig_struct.start_index = ac2_sim_ig.start_index; 
c2_sim_ig_struct.end_index = ac2_sim_ig.end_index; 
c2_sim_ig_struct.marker_data = ac2_sim_ig.ref_data; 
c2_sim_ig_struct.selected_marker_indices = ref_data_start_indx:ref_data_end_indx; 
total_markers = size(c2_sim_ig_struct.marker_data,1); 
c2_sim_ig_struct.separation_indxs = nan(1,total_markers); 
% disp('Finding marker separation points: ') 
marker_no = 1; 
for indxpt=1:size(ac2_sim_ig.all_datapoints,2) 
    if c2_sim_ig_struct.odometer_max(indxpt)>=c2_sim_ig_struct.marker_data.odo(marker_no) ...
            && mean(c2_sim_ig_struct.odometer_max(indxpt+(1:10)))>=c2_sim_ig_struct.marker_data.odo(marker_no) 
        % there are spikes (plot odometer_max to check it!) 
        c2_sim_ig_struct.separation_indxs(marker_no) = indxpt; 
        marker_no = marker_no+1; 
    end 
    if marker_no>total_markers 
        disp('all obj.markers sorted'); 
        break 
    end 
end 
% 

% 
mes_indx = c2_sim_ig_struct.separation_indxs([ref_data_start_indx,ref_data_end_indx]); 
C_swtch_data = mes_indx - mes_indx(1); 
% 
% indx_diff = c2_sim_ig_struct.end_index-c2_sim_ig_struct.start_index; 
% if C_swtch_data(end) ~= indx_diff 
%     C_swtch_data = [C_swtch_data, indx_diff]; 
% end 
% 
% vm_data = gen_vm_at_sampletime(c2_sim_ig_struct,mes_markers,C_swtch_data); 
vm_data = gen_vm_at_sampletime(ac2_sim_ig,[ac2_sim_ig.start_gps;ac2_sim_ig.end_gps],...
    [0,ac2_sim_ig.end_index-ac2_sim_ig.start_index]); 

% 
op_title = {'odo','Lat','lon','Latvm','lonvm'}; 
odo_op = c2_sim_ig_struct.odometer_max(c2_sim_ig_struct.start_index) ...
    + round(store_traj(:,2)/c2_sim_ig_struct.odo_gain_guess); 
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

writetable(uqop_table,[['../CSV_OUTPUT', path_suffix, '/At_odom_using_refdata_S6_'],fname]) 

%% At welds 
[gstart,gfinish,ghit,gmrkd] = cstm2_odo_hidden_marker_hit(c2_sim_ig_struct,op_array); 
[gstart_vm,gfinish_vm,ghit_vm,gmrkd_vm] = cstm2_odo_hidden_marker_hit(c2_sim_ig_struct,vm_data); 
mop_title = {'id','Lat','lon','weld','Latref','lonref','odomax','Latvm','lonvm','errref','errvmref','axial_factr','axial_err'}; 
% mrkrop_array = [(selected_marker_indices(1):selected_marker_indices(end))',[gstart(1,:);gmrkd(1:end,:)],...
%     ac2_sim_ig.marker_data{ac2_sim_ig.selected_marker_indices(1):ac2_sim_ig.selected_marker_indices(end),[1:3,8]},...
%     [gstart_vm(1,:);gmrkd_vm(1:end,:)]]; 
mrkrop_array = [(ref_data_start_indx:ref_data_end_indx)',gmrkd(1:end,:),...
    ac2_sim_ig.ref_data{ref_data_start_indx:ref_data_end_indx,[1:3,8]},...
    gmrkd_vm(1:end,:)]; 
mrkrop_array = [mrkrop_array, sqrt((double(mrkrop_array(:,2))-double(mrkrop_array(:,5))).^2 ...
    +(double(mrkrop_array(:,3))-double(mrkrop_array(:,6))).^2)*111000,...
    sqrt((double(mrkrop_array(:,8))-double(mrkrop_array(:,5))).^2 ...
    +(double(mrkrop_array(:,9))-double(mrkrop_array(:,6))).^2)*111000]; 

% heading unit vector & error unit vector --> dot product 
tmp = diff(mrkrop_array(:,2:3)); dLdh = [tmp;tmp(end,:)]; 
dLdh_unit = dLdh./repmat(sqrt(sum(dLdh.*dLdh,2)),1,2); 
dLrdhr = mrkrop_array(:,2:3)-mrkrop_array(:,5:6); 
dLrdhr_unit = dLrdhr./repmat(sqrt(sum(dLrdhr.*dLrdhr,2)),1,2); 
axial_factor = sum(dLdh_unit.*dLrdhr_unit,2); 
mrkrop_array = [mrkrop_array,axial_factor,mrkrop_array(:,10).*abs(axial_factor)]; 

mrkrop_table = array2table(mrkrop_array,"VariableNames",mop_title); 
writetable(mrkrop_table,[['../CSV_OUTPUT', path_suffix, '/At_weld_using_refdata_S6_'],fname]) 

end 

function [gstart,gfinish,ghit,gmrkd,hit_indxs,mrkd_indxs] = cstm_odo_hidden_marker_hit(obj,y_fulltraj) 
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

function [gstart,gfinish,ghit,gmrkd_all,hit_indxs,mrkd_indxs] = cstm2_odo_hidden_marker_hit(obj,y_fulltraj) 
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
    [~,mindx] = min(abs(y_fulltraj(:,1)-odomrkrd(1))); 
    mrkd_indxs = obj.separation_indxs(hidden_sel_mrkr_indxs) ...
        - obj.separation_indxs(hidden_sel_mrkr_indxs(1)) + mindx; 
    mrkd_mismatch = mrkd_indxs>size(y_fulltraj,1); 
    mrkd_indxs(mrkd_mismatch) = []; 
    gmrkd_all = [y_fulltraj(mrkd_indxs,2:3);nan(sum(mrkd_mismatch),2)]; 
end 