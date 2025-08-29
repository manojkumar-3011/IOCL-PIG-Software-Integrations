function extract_4m_comparisonsheet()
    load('../../../INPUTS/100km_INPUT/INPUT/ComparisonSheet.mat', 'ComparisonSheet')
    load('../../../INPUTS/100km_INPUT/INPUT/markers.mat', 'markers')
    mm.tag = ComparisonSheet.newMM(:);
    mm.hgt = ComparisonSheet.heightm(:); 
    mmt = struct2table(mm); 

    data = []; % ID height
    for indx=1:size(mmt,1) 
        tag = char(mmt{indx,1}); 
        hgt = mmt{indx,2}; 
        if contains(tag,"M")
            data = [data; str2double(tag(2:end)), hgt]; 
            % disp(markers.RefNo_{data(end,1)+1})
            markers{data(end,1)+1,"hgt"} = hgt; 
        end
    end

    save('../../../INPUTS/100km_INPUT/INPUT/markers_bckp.mat', 'markers')
    save('../../../INPUTS/100km_INPUT/INPUT/markers.mat', 'markers')

end 