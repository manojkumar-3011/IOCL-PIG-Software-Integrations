clear all 

%% Load marker xlsx data
[filename, pathname, filterindex] = uigetfile('*.xlsx', 'Pick the Marker XLSX file');
agm_rawdata = readtable([pathname,filename],'Range','A1:K114'); 

%% Rearrange tables
agm_rawdata_struct = table2struct(agm_rawdata);
order_needed = {'name', 'lon', 'lat', 'odo1', 'odo2', 'odo3', 'odosum', 'hgt'}; 

varnames = order_needed; varvals = {}; 
for fld=order_needed 
    fld_data = agm_rawdata.(fld{:}); 
    if iscell(fld_data)
        varvals = [varvals, fld_data]; 
    else
        varvals = [varvals, num2cell(fld_data)]; 
    end 
    agm_rawdata_struct = rmfield(agm_rawdata_struct, fld{:}); 
end 

col_names = fields(agm_rawdata_struct)'; 
for fld=col_names 
    fld_data = agm_rawdata.(fld{:}); 
    if iscell(fld_data)
        varvals = [varvals, fld_data]; 
    else
        varvals = [varvals, num2cell(fld_data)]; 
    end 
    varnames = [varnames, fld{:}]; 
end 

markers = cell2table(varvals,"VariableNames",varnames); 

%% Curved info 

varnames_mci = {'name', 'curved', 'fwd_curved', 'bckwd_curved'}; 
varvals_mci = varvals(:,1); 
varvals_mci(:,2:4) = num2cell( true( size(varvals_mci,1),3 ) ); 

marker_curve_info = cell2table(varvals_mci,"VariableNames",varnames_mci); 

%% Save it 
save('../INPUT/markers.mat', "markers", "marker_curve_info");  
