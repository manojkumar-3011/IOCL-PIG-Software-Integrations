classdef draw_stuff < handle 
    properties (Access=protected) 
        writerObj = []; 
        frame_count = 0; 
    end 
    properties 
        enable_video_rec = false; 
    end 
    methods 
        function obj = draw_stuff(varargin) 
            if nargin>0 
                if isempty(varargin{1}) 
                    tests() 
                    return 
                end 
            else 
            end 
        end 
        %% Useful methods 
        function top_view(~) 
            view(0,90) 
        end 
        function side_view(~) 
            view(0,0) 
        end 
        %% Computation 
        %% Draw 
        function render_cube(obj,origin,Rtheta,X,Y,Z,color) 
            obj.draw_cube(origin,Rtheta,X,Y,Z,color); 
            xlabel('x --> ') 
            ylabel('y --> ') 
            zlabel('up --> ') 
            axis equal 
            view(10,10) 
        end 
        function draw_cube(~,origin,Rtheta,X,Y,Z,color)
            % CUBE_PLOT plots a cube with dimension of X, Y, Z.
            %
            % INPUTS:
            % origin = set origin point for the cube in the form of [x,y,z].
            % X      = cube length along x direction.
            % Y      = cube length along y direction.
            % Z      = cube length along z direction.
            % color  = STRING, the color patched for the cube.
            %         List of colors
            %         b blue
            %         g green
            %         r red
            %         c cyan
            %         m magenta
            %         y yellow
            %         k black
            %         w white
            % OUPUTS:
            % Plot a figure in the form of cubics.
            %
            % EXAMPLES
            % cube_plot(2,3,4,'red')
            %
            % SOURCE: https://jialunliu.com/how-to-use-matlab-to-plot-3d-cubes/
            % MODIFICATION (by Som): for orientation using 'Rtheta' and shift base
            %       origin to the center (default setting was 1st quad cube)

            % ------------------------------Code Starts Here------------------------------ %
            % Define the vertexes of the unit cubic

            ver = [1 1 0;
                0 1 0;
                0 1 1;
                1 1 1;
                0 0 1;
                1 0 1;
                1 0 0;
                0 0 0];
            ver = ver-0.5;
            ver(:,1) = ver(:,1)*X;
            ver(:,2) = ver(:,2)*Y;
            ver(:,3) = ver(:,3)*Z;
            ver = transpose(Rtheta*(ver)');

            %  Define the faces of the unit cubic
            fac = [1 2 3 4;
                4 3 5 6;
                6 7 8 5;
                1 2 8 7;
                6 7 1 4;
                2 3 5 8];

            cube = [ver(:,1)+origin(1),ver(:,2)+origin(2),ver(:,3)+origin(3)];
            patch('Faces',fac,'Vertices',cube,'FaceColor',color);
            % ------------------------------Code Ends Here-------------------------------- %
        end
        %
        function h = render_circle(~,xy,r)
            d = r*2; 
            px = xy(1)-r; 
            py = xy(2)-r; 
            h = rectangle('Position',[px py d d],'Curvature',[1,1]); 
            daspect([1,1,1]) 
        end 
        %
        function create_video_object(varargin) 
            obj = varargin{1}; 
            fps = varargin{2}; 
            if nargin>2 
                video_name = varargin{3}; 
            else 
                if fopen('out.avi')==-1
                    video_name = 'out'; 
                else
                    time_id = num2str(clock); 
                    time_id = time_id(time_id~=' '); 
                    time_id = time_id(time_id~='.'); 
                    video_name = ['out_',time_id]; 
                end 
            end 
            if obj.enable_video_rec 
                obj.writerObj = VideoWriter([video_name,'.avi']); % Name it.
                obj.writerObj.FrameRate = fps; % How many frames per second.
                open(obj.writerObj); 
                disp('Initiallizing video recording. ') 
            else 
                disp('Video recording DISABLED. ') 
            end 
        end 
        function record_videoframe(varargin) 
            obj = varargin{1}; 
            if nargin>1 
                reduced_frames = varargin{2}; 
            else 
                reduced_frames = 100; 
            end 
            if obj.enable_video_rec 
                if mod(obj.frame_count,floor(100/reduced_frames))==0, % Uncomment to take 1 out of every 4 frames.
                    frame = getframe(gcf); % 'gcf' can handle if you zoom in to take a movie.
                    try 
                    writeVideo(obj.writerObj, frame); 
                    catch 
                        keyboard 
                    end 
                    obj.frame_count = obj.frame_count + 1; 
                end
            end
        end 
        function publish_video(obj) 
            if obj.enable_video_rec
                close(obj.writerObj); 
                disp('Publishing recorded video. ') 
            end
        end 
    end 
    methods % Important drawings and animations   
        %% Bogee 
        function render_bogee(obj,sz,origin,angle,color) 
            clf 
            obj.draw_bogee(sz,origin,angle,color); 
            xlabel('x --> ') 
            ylabel('y --> ') 
            axf = 1.5; 
            axis([origin(1)+axf*sz*[-1,1],origin(2)+axf*sz*[-1,1]])
        end 
        function draw_bogee(obj,sz,origin,angle,color) 
            origin = origin(:) + sz*[0;0.3]; 
            R_theta = rotz(angle); R_theta = R_theta(1:2,1:2); 
            xydata = sz*[-1,-1,1,1;1,0,0,1]; 
            xydata = R_theta*xydata; 
            patch(origin(1)+xydata(1,:),origin(2)+xydata(2,:),color) 
            wheel_loc = sz*[-0.5,0.5;0,0]; 
            wheel_loc = R_theta*wheel_loc + repmat(origin,1,2); 
            wheel_radius = sz*0.3; 
            obj.render_circle(wheel_loc(:,1),wheel_radius); 
            obj.render_circle(wheel_loc(:,2),wheel_radius); 
        end 
        function animate_bogee(obj,sz,v1,v2,alpha) 
            v(1).loc = v1(:); v(2).loc = v2(:);
            xy = (1-alpha)*v(1).loc + alpha*v(2).loc;
            [~,lower_pt] = min([v(1).loc(2),v(2).loc(2)]);
            higher_pt = 3-lower_pt; 
            % angle = atan2(v(higher_pt).loc(2)-v(lower_pt).loc(2),v(higher_pt).loc(1)-v(lower_pt).loc(1))*180/pi; 
            angle = atan((v(higher_pt).loc(2)-v(lower_pt).loc(2))/(v(higher_pt).loc(1)-v(lower_pt).loc(1)))*180/pi; 
            % 
            hold on 
            obj.draw_bogee(sz,xy,angle,'b'); 
            hold on 
            plot([v(1).loc(1),v(2).loc(1)],[v(1).loc(2),v(2).loc(2)],'x-.') 
            hold on 
            pause(0.01) 
        end 
        %% Flexible Link 
        function draw_flex_link2D(obj,sz,origin,angle,twist_angle,color) 
            % 
            nop = 10; 
            % 
            vec = origin(:) + sz*[1;0]; 
            R_delta = rotz(twist_angle); R_delta = R_delta(1:2,1:2); 
            R_theta = rotz(angle); R_theta = R_theta(1:2,1:2); 
            xy_data = [linspace(origin(1),vec(1),nop); ...
                linspace(origin(2),vec(2),nop)]; 
            xy_data = R_delta*xy_data; 
            xy_data(2,:) = (xy_data(2,:)/xy_data(2,end)).^2*xy_data(2,end); 
            xy_data = R_theta*xy_data; 
            plot(xy_data(1,:),xy_data(2,:),color); 
        end 
    end 
    methods % some useful ones 
        function str = num2substr(~,num) 
            snum = num2str(num); 
            str = char(kron(snum,[0,1]) + repmat([95,0],1,length(snum))); 
        end 
    end 
end 

function draw_qped_body() 

dw = draw_stuff(); 
%
base_l = 1; 
sd_l = 2*base_l; 
sd_b = 1*base_l; 
sd_h = 0.5*base_l; 
ln_u = 0.8*base_l; 
ln_l = 0.7*base_l; 
vfl0 = -[pi/7, -2*pi/7];  % upper leg angle, lower leg angle 
ht0 = sd_h/2 + ln_u*cos(vfl0(1)) + ln_l*cos(vfl0(1)+vfl0(2));
v0 = [1;1;ht0]; o0 = [0;0;1*pi/6]; 
Rbase = rotz(o0(3)*180/pi)*roty(o0(2)*180/pi)*rotx(o0(1)*180/pi);
dw.render_cube(v0,Rbase,sd_l,sd_b,sd_h,'b'); 

end 

function moving_bogee() 

dw = draw_stuff(); 
%
sz = 2; 
%
v1 = rand(2,1); v2 = [10;-15]+rand(2,1);
for alpha = 0:0.03:1 
    clf 
    dw.animate_bogee(sz,v1,v2,alpha) 
    axis auto 
end 

if pause_dbug_fcn3(); keyboard; end; clc 

end 


function draw_flexible_link() 

dw = draw_stuff(); 

dw.draw_flex_link2D(1,[0;0],30,10,'b'); 

end 

function tests() 
clc; 

% draw_qped_body(); 
% moving_bogee(); 
draw_flexible_link(); 

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
