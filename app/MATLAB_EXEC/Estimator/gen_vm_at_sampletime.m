function op_data = gen_vm_at_sampletime(obj,mes_markers,C_swtch_data) 
    % 
    lc_fun = @(arr) round(arr(:,2:4).*(arr(:,5)-arr(:,9))./(arr(:,5)-arr(:,1)) ...
        + arr(:,6:8).*(arr(:,9)-arr(:,1))./(arr(:,5)-arr(:,1)),8); 
    
    % filter 
    odomax = obj.odometer_max; 
    iom = find(odomax(1:end-1)>odomax(2:end)); 
    odomax(iom) = 0.5*odomax(iom-1) + 0.5*odomax(iom+1); 

    % parents odom  
    cdiff = [0;diff(odomax(obj.start_index + C_swtch_data)')]; 
    parent1_odo = zeros(obj.end_index-obj.start_index+1,1); 
    parent1_odo(C_swtch_data+1) = cdiff; 
    parent1_odo = cumsum(parent1_odo) + odomax(obj.start_index); 
    parent2_odo = zeros(obj.end_index-obj.start_index+1,1); 
    parent2_odo(C_swtch_data(1:end-1)+1) = cdiff(2:end); 
    parent2_odo = cumsum(parent2_odo) + odomax(obj.start_index); 
    
    % index 
    indx = zeros(obj.end_index-obj.start_index+1,1); 
    indx(C_swtch_data+1) = 1; 
    indx = cumsum(indx); 
    
    % data 
%     lincomb_title = {'parent1_odo','parent1_Lat','parent1_lon',...
%         'parent2_odo','parent2_Lat','parent2_lon',...
%         'odo','Lat','lon'};  % ,'CD_odo','CD_Lat','CD_lon'
    lincomb_array = [parent1_odo,mes_markers(indx,1),mes_markers(indx,2),mes_markers(indx,3),...
        parent2_odo,mes_markers(min(indx+1,indx(end)),1),mes_markers(min(indx+1,indx(end)),2),...
        mes_markers(min(indx+1,indx(end)),3),odomax(obj.start_index:obj.end_index)',nan(length(indx),3)]; 
    lincomb_array(:,10:12) = lc_fun(lincomb_array); 
    lincomb_array(C_swtch_data(end)+1,10:12) = lincomb_array(C_swtch_data(end)+1,6:8); 
%     lincomb_array = [lincomb_array,cd_table{:,2:4}]; 
%     
%     lincomb_table = array2table(lincomb_array,"VariableNames",lincomb_title); 
%     writetable(lincomb_table,['../CSV_OUTPUT', path_suffix, '/linear_combination_result.csv'])

    % output 
    op_data = lincomb_array(:,end-3:end); % 
    
end 