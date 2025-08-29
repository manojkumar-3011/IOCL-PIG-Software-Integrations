classdef simulate_ili_run_expC2 < simulate_ili_run % run: >> simulate_ili_run_expC2([]) %&ENV
    properties (Access=protected) 
        data1_simulate_ili_run_expC2 = [1,2]; 
    end 
    properties 
        scriptname_TITLE_1 = '<<<<< simulate_ili_run_expC2 fundamental settings >>>>>'; 
        final_stop_enabled_simulate_ili_run_expC2 = true; 
        data2_simulate_ili_run_expC2 = [2,3]; 
        scriptname_TITLE_2 = '<<<<< simulate_ili_run_expC2 2nd category >>>>>'; 
        data3_simulate_ili_run_expC2 = false; 
    end 
    methods 
        %$ Core 
        function obj = simulate_ili_run_expC2(varargin) 
            obj@simulate_ili_run(varargin{:}); 
            %             if nargin>0 
            %                 % test case execution 
            %                 if isempty(varargin{1}) 
            %                     obj = obj.tests(); 
            %                     return 
            %                 end 
            %                 % get new data 
            %                 obj.data1_simulate_ili_run_expC2 = varargin{1}; 
            %                 obj.data2_simulate_ili_run_expC2 = varargin{2}; 
            %                 if nargin>2 
            %                     obj.data3_simulate_ili_run_expC2 = varargin{3}; 
            %                 else 
            %                     obj.data3_simulate_ili_run_expC2 = false; 
            %                 end 
            %             else 
            %                 % change default data 
            %                 obj.data2_simulate_ili_run_expC2(2) = 4; 
            %                 obj.data3_simulate_ili_run_expC2 = true; 
            %             end 
            obj.about(); 
        end 
        function new_obj = tests(~) 
            clc 

            % new_obj = test_simulate_ili_run_expC2_case1(); 
            % new_obj = test_simulate_ili_run_expC2_case2();  

        end 
        function about(~) 
            disp('This is a framework for classes defining `main` files! '); 
            disp('Class name: simulate_ili_run_expC2') 
        end 
        %$ Useful methods 
        %$ Get methods: get_ 
        %$ Set methods: set_ 
        %$ Load methods: load_ 
        %$ Save methods: save_ 
    end 
    methods 
        %% All main methods 
        function main(obj)
            %% Step 1: 
            %% Step 2: 
            %% Final step: 
            disp('  ') 
            disp('<<<< All STEPS completed! >>>>') 
            if obj.final_stop_enabled_simulate_ili_run_expC2 
                if pause_dbug_fcn3(); keyboard; end; clc 
            end 
        end 
        %% Rendering: show_ 
    end
    methods 
        % Testbench: test_ & report_ 
    end 
    methods (Access=protected) 
    end 
end 

%% Tests below 
function new_obj = test_simulate_ili_run_expC2_case1() 
clc; 
disp('This is a test! ') 
disp('First case: ') 
new_obj = simulate_ili_run_expC2(); 
new_obj.about(); 
new_obj.main(); 

% if pause_dbug_fcn3(); keyboard; end; clc 

end 

function new_obj = test_simulate_ili_run_expC2_case2() 
clc; 
disp('This is a test! ') 
disp('Second case: ') 
new_obj = simulate_ili_run_expC2(); 
new_obj.about(); 
new_obj.main(); 

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
