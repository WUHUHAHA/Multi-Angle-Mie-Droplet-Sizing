clear all
close all
% Creates a set of simulated light scattering images.
%
% Copyright (C) 2012, Stephen D. LePera.  GNU General Public License, v3.
% Terms available in GPL_v3_license.txt, or <http://www.gnu.org/licenses/>

% Setup the desired properties of the simulated data set here

% Location of Irr_int.m and create_view.m 
addpath ../mie_m_code

% Scattering crossection database containing A and B
scat_db_filename=...
    '../mie_m_code/database_files/scattering_coefficients_database2.mat';

% z-y location of "red dot" centers within frame, inches
% lower left corner is origin w/ respect to the dots.
y_z_dots=[0.025 0.025
    .125 0.025
    .125 0.575
    0.025 0.575];
% "red dot" diameter, inches
rd=0.03;
image_width=0.15;  % inches

% droplet distribution/location
% each column a different standard deviation
% each row will be different mean diameter
% note: one-column case centered at desired angle

dg_max=50;   % micrometers
dg_min=1;  %was 0.3
sigma=[10];  % micrometers
dist_type='logn';   % Can be 'single', 'logn', or 'norm'   

y_cent=0.075;  % inches  This will be center of the resulting data images
z_cent=0.3;  % inches

% Camera Angular Location(s) with respect to y_cent,z_cent, above
% matrix contains data about how the image will be created
% first row is assumed to be reference angle

% Setup methods from PhD thesis:
MTD1=[40 138:1.2:150];
MTD2=[40 138:0.5:142 146 150];
MTD3=[40 138:2.4:150];
MTD4=[40 138:1:142 150];
MTD5=[40 139 141];

% Pick one cam_loc only, corresponding to desired setup method:
% cam_loc=...
% [50*ones(size(MTD1))' MTD1' 0.5*ones(size(MTD1))' 0.5*ones(size(MTD1))'];
% cam_loc=...
% [50*ones(size(MTD2))' MTD2' 0.5*ones(size(MTD2))' 0.5*ones(size(MTD2))'];
cam_loc=...
 [50*ones(size(MTD3))' MTD3' 0.5*ones(size(MTD3))' 0.5*ones(size(MTD3))'];
%cam_loc=...
% [50*ones(size(MTD4))' MTD4' 0.5*ones(size(MTD4))' 0.5*ones(size(MTD4))'];
%cam_loc=...
% [50*ones(size(MTD5))' MTD5' 0.5*ones(size(MTD5))' 0.5*ones(size(MTD5))'];

gamma_ref=90*pi/180;  % polarization of input light relative to ref plane
                      % else set to 'unpolarized'
xi=90*pi/180;  % transmission axis of polarization filter
               % else set to 'no filter'
half_angle=0.5*pi/180;  % half solid-cone angle in detector camera
wavelength=514.5;  % laser wavelength, nanometers
method='1D'; % computation method for scattering information
     
% if 'on' then all the above exposure times MUST be equal.  New exposure
% times will be calculated so that every image has the same maximum 
% brightness.  If set to 'off' then the above times will be used and are
% allowed to differ from image to image.
auto_exposure='on';

% image characteristics
%y_pix=2044;  % DO NOT exceed 2044x1533 !! bad things happens w/ graphics!!
%z_pix=1533;  %    (probably limitation of current graphic card...)

y_pix=225;
z_pix=900;

% super pixels in each diminsion 
y_sup=3;
z_sup=12;

% perspective 1=yes, 0=no
perspective_yes=1;

% Any spheres below this size set to zero.  Must be equal or larger than
% smallest size in the DB.
min_d=0.1; % micrometers

%% Probably no need to change parameters below this point

current_path=pwd; 
startpath=current_path;  % sets the startpath in the dialog to current path

% resolution, pixels/inch
pix_res=y_pix/image_width;
image_height=z_pix/pix_res;

% geometric center of super-pixel
yc=(1/pix_res)*(y_pix/y_sup)*(0.5+(1:y_sup)-1);
zc=(1/pix_res)*(z_pix/z_sup)*(0.5+(z_sup:-1:1)-1);
% geometric center of image pixels
ycm=(1/pix_res)*(0.5+(1:y_pix)-1);
zcm=(1/pix_res)*(0.5+(z_pix:-1:1)-1);

distnc=zeros(z_sup,y_sup);
dg=zeros(z_sup,y_sup);
sig_g=sigma*ones(z_sup,y_sup);

% Calcualte diameters at each superpixel
for jj=1:z_sup
    
    for ii=1:y_sup
        
        if (jj>=floor((y_sup-size(sigma,2))/2)+1 && ii>1 &&...
                ii<y_sup && jj<z_sup-1)
            dg(jj,ii)=((dg_max-dg_min)/(zc(z_sup-2)-zc(2)))*...
                (zc(jj)-zc(2))+dg_min;
            if dg(jj,ii)>10
                dg(jj,ii)=round(dg(jj,ii));
                
            end
            
        end
        
        if (dg(jj,ii)<0 || dg(jj,ii)>(1.001*dg_max))
            dg(jj,ii)=0;
            sig_g(jj,ii)=0;
        end
    end
end

% dissertion specific latex table-formatted output of dg
%mfprintf(1,' & %3.1f',dg(2:10,2));
%mfprintf(1,'\n');

% Size parameter determination
dgx=2*pi*(dg/2)*1e3/wavelength;
sig_gx=2*pi*(sig_g)*1e3/wavelength;

%% calculate brightnesses in each superpixel based on dg and sig_g above
global A B
load(scat_db_filename)
% find right index for proper angle
X=[B.theta];
% used to normalize images
max_b=0;

[save_file, save_pathname, filterindex] = ...
    uiputfile('*.*', 'Filename to save image files:', 'save_file');

% Slow, lazy way to normalize all images in the set but won't destroy 
% memory in cases of large images or large number of images
II=zeros(z_sup,y_sup);
camera_position=zeros(size(cam_loc,1),3);

for kk=1:size(cam_loc,1)
    camera_position(kk,1)=cam_loc(kk,1)*sin(pi*cam_loc(kk,2)/180);
    camera_position(kk,2)=cam_loc(kk,1)*cos(pi*cam_loc(kk,2)/180);
    for ii=1:y_sup
        for jj=1:z_sup
            if dg(jj,ii)<min_d
                II(jj,ii)=0;
            else
                point=[0 yc(ii)-y_cent zc(jj)-z_cent];
                
                d_dist=sqrt(sum((camera_position(kk,:)-point).^2));
                dy_dist=camera_position(kk,2)-point(2);
                dx_dist=camera_position(kk,1)-point(1);
                dz_dist=camera_position(kk,3)-point(3);
                
                d_ang=acos(dy_dist/d_dist);
                d_phi=atan(dz_dist/dx_dist);
                
                % auto switch from norm to logn at small diameters (within
                % 3 std of mean)
                switch dist_type
                    case 'norm'
                        if 2*dgx(jj,ii)<3*sig_gx(jj,ii)
                            do_dist_type='logn';
                            do_sigx=2*pi*(sig_g(ii,jj)^2)*1e3/wavelength;
                        else
                            do_dist_type=dist_type;
                            do_sigx=sig_gx(jj,ii);
                        end
                    otherwise
                        do_dist_type=dist_type;
                        do_sigx=sig_gx(jj,ii);
                end
                
                [IIm Isr2_dist Qsr2_dist Usr2_dist Vsr2_dist matches]=...
                Irr_int(dgx(jj,ii), do_sigx, do_dist_type, d_ang,...
                d_phi, cam_loc(kk,3)*pi/180, gamma_ref,xi,method);
            
                II(jj,ii)=(2500/cam_loc(kk,1)^2)*cam_loc(kk,4)*IIm;
             end
        end
    end
    
    % What is the brightest scattererererer?
    if max_b<max(max(II))
        max_b=max(max(II));
    end
    II=zeros(z_sup,y_sup);
end

% Now re-calcualte scattering for images
for kk=1:size(cam_loc,1)
    for ii=1:y_sup
        for jj=1:z_sup
            if dg(jj,ii)<min_d
                II(jj,ii)=0;
            else
                point=[0 yc(ii)-y_cent zc(jj)-z_cent];
                
                d_dist=sqrt(sum((camera_position(kk,:)-point).^2));
                dy_dist=camera_position(kk,2)-point(2);
                dx_dist=camera_position(kk,1)-point(1);
                dz_dist=camera_position(kk,3)-point(3);
                
                d_ang=acos(dy_dist/d_dist);
                d_phi=atan(dz_dist/dx_dist);
                
                % auto switch from norm to logn at small diameters (within
                % 3 std of mean)
                switch dist_type
                    case 'norm'
                        if 2*dgx(jj,ii)<3*sig_gx(jj,ii)
                            do_dist_type='logn';
                            do_sigx=2*pi*(sig_g(ii,jj)^2)*1e3/wavelength;
                        else
                            do_dist_type=dist_type;
                            do_sigx=sig_gx(jj,ii);
                        end
                    otherwise
                        do_dist_type=dist_type;
                        do_sigx=sig_gx(jj,ii);
                end
                
                [IIm Isr2_dist Qsr2_dist Usr2_dist Vsr2_dist matches]=...
                Irr_int(dgx(jj,ii), do_sigx, do_dist_type, d_ang,...
                d_phi, cam_loc(kk,3)*pi/180, gamma_ref,xi,method);
            
                II(jj,ii)=(2500/cam_loc(kk,1)^2)*cam_loc(kk,4)*IIm;
             end
        end
    end
    
    % normalized brightness matrix (with max at 96% of maximum so data 
    % won't go to 255 later)
    II_n=II./(max_b+0.04*max_b);
    
    % iterpolate from superpixel grid onto image resolution
    dg_im=interp2(yc,zc',dg,ycm,zcm','nearest');
    
    % calcualte z-y coordinates in the image
    for ii=1:y_pix
        ycorr(ii)=(ii-1)/(pix_res)+0.5/pix_res-y_cent;
    end
    for ii=1:z_pix
        zcorr(ii)=(z_pix-ii)/(pix_res)+0.5/pix_res-z_cent;
    end
    
    warning('off', 'MATLAB:intConvertNonIntVal')
    
    if strcmp(auto_exposure,'on')==1
        cam_loc(kk,4)=0.95/max(max(II_n));
        II_n=cam_loc(kk,4)*II_n;
    end
    
    II_im=uint8(255*interp2(yc,zc',II_n,ycm,zcm','nearest'));
    warning('on','all');
    
    figure(kk)
    % make an RGB image, using G channel
    for ll=1:3
        if ll==2
            mult=1;
        else
            mult=0;
        end
        II_sv(:,:,ll)=uint8(mult*II_im);
    end
        
    warning('off','Images:initSize:adjustingMag');
    h_im=imshow(II_sv);
        
    %% Add the red dots
    for ll=1:size(y_z_dots,1)
        
        ypos=round((y_z_dots(ll,1)-rd/2)*pix_res);
        zpos=z_pix-round((y_z_dots(ll,2)+rd/2)*pix_res);
                
        rdpix=round(rd*pix_res);
        
        red_dot=uint8(zeros(size(II_sv)));
        e = imellipse(gca,[ypos zpos rdpix rdpix]);
        BW = createMask(e,h_im);
        II_sv(:,:,1) = immultiply(imcomplement(BW),II_sv(:,:,1));
        II_sv(:,:,2) = immultiply(imcomplement(BW),II_sv(:,:,2));
        II_sv(:,:,3) = immultiply(imcomplement(BW),II_sv(:,:,3));
        red_dot(:,:,1)=uint8(255*BW);
        II_sv=imadd(red_dot,II_sv);
    end
    
    h_im=imshow(II_sv);
        
    %% rotate image for perspective
    if perspective_yes==1
        y_cam_pos=cam_loc(kk,1)*cos(pi*cam_loc(kk,2)/180);
        x_cam_pos=cam_loc(kk,1)*sin(pi*cam_loc(kk,2)/180);
        
        hh=0.5*(max(max(y_z_dots)-min(y_z_dots)+rd));
        cc=cam_loc(kk,1)^2+hh^2-2*cam_loc(kk,1)*hh*...
            cos(pi*cam_loc(kk,2)/180);
        cc=sqrt(cc);
        
        if kk==1
            % view angle is the included angle of the camera lens.  
            % In effect it is like a "zoom" on the image.  
            % We want this to be the same for all images
            % FDGE is a factor used to trim this up so it works 
            % "best" for all angles even though we just calculate it once.  
            % Smaller "zooms" in more
            fdge=0.33;
            view_angle=fdge*2*180*asin(hh*sin(pi*cam_loc(kk,2)/180)/cc)/pi;
        end
        
        [II_sv H]=create_view([0 y_cent z_cent],...
            [x_cam_pos y_cam_pos 0],view_angle,image_width,II_sv);
         
        % matlab output is awful for things like this, so print figure to
        % temp,
        % lossless file and then re-open.  this method uses graphics card
        % rendering, thus there is a max resolution where things blow up.
        % below that resolution it works nicely, and that is all that is
        % required here.
        output_size = [y_pix z_pix]; %Size in pixels
        resolution = 600; %Resolution in DPI.

        set(H,'paperunits','inches','paperposition',...
            [0 0 output_size/resolution]);
        print('temp.tif','-dtiffnocompression',['-r' num2str(resolution)]);
        
        clear II_sv
        II_sv=imread('temp.tif');
       
        close(H)
        
        delete('temp.tif')
        
    end
    
    %% save the images and data
    % control over final quality of files here - can be JPEG or TIFF or
    % anything.  Actual diameter data is saved in the .mat files
    save_string=strcat(save_pathname,save_file,'-',num2str(kk),'_',...
        num2str(cam_loc(kk,2)),'.jpg');
    imwrite(II_sv, save_string, 'JPEG', 'Quality', 95)
    save_string=strcat(save_pathname,save_file,'_dg-',num2str(kk),'_',...
        num2str(cam_loc(kk,2)),'.mat');
    save(save_string,'dg_im','ycorr','zcorr');
    save_string=strcat(save_pathname,save_file,'_In-',num2str(kk),'_',...
        num2str(cam_loc(kk,2)),'.mat');
    save(save_string,'II_n','ycorr','zcorr');
    
    figure(kk)
    h_im=imshow(II_sv);
    clear II_sv BW red_dot II_im
end

% information about the generation of a set of images
save_strng=strcat(save_pathname,save_file,'-image_info.mat');
save(save_strng,'y_z_dots','rd','image_width','cam_loc','auto_exposure',...
    'dg_max','dg_min','sigma','dist_type','y_cent','z_cent','gamma_ref',...
    'xi','wavelength','method','y_sup','z_sup','min_d','dg');

figure
v=0:dg_max/20:dg_max;
contourf(ycorr,zcorr,dg_im,v,'LineStyle','none')
colorbar
caxis([0 dg_max])
title('Average sphere diameter, micrometers')
xlabel('inches')
ylabel('inches')
axis equal

warning('on','all');

%% Generate processing initialization file based on the above 
%% simulated data set

ini_filename=strcat(save_pathname,save_file,'-image_processing.ini');

% NOTE: inifile.m is a function written by by Primoz Cermelj, NOT part of
% matlab.

% fresh start, do no overwirte variables.
if exist(ini_filename)>0
    delete(ini_filename)
end

%Make comments section at top of file
inifile(ini_filename,'write',{'','',...
    ';- Lines starting with a semi-colon are treated as a comment.',''})
inifile(ini_filename,'write',{'','',...
    ';- Comment lines do NOT need the = sign at the end :)',''})
inifile(ini_filename,'write',{'','',...
    ';- Filenames should be given with a full pathname',''})
inifile(ini_filename,'write',{'','',...
    ';  if they are not in the current directory.',''})
inifile(ini_filename,'write',{'','',...
    ';- An unlimited number of angles may be given, so long',''})
inifile(ini_filename,'write',{'','',...
    ';  as the sections follow the AngleX naming convention shown.',''})
inifile(ini_filename,'write',{'','', ';     ',''})
inifile(ini_filename,'write',{'','',...
    ';- This .ini file may be hand edited; this file was created by',''})
inifile(ini_filename,'write',{'','',...
    ';  the inifile function written by by Primoz Cermelj.  Data is',''})
inifile(ini_filename,'write',{'','',...
    ';  easily read using the same function.',''})

%Test Section section
red_dot_1_str=strcat('[',...
    num2str([0 y_z_dots(1,1)-y_cent y_z_dots(1,2)-z_cent]),']');
red_dot_2_str=strcat('[',...
    num2str([0 y_z_dots(2,1)-y_cent y_z_dots(2,2)-z_cent]),']');
red_dot_3_str=strcat('[',...
    num2str([0 y_z_dots(3,1)-y_cent y_z_dots(3,2)-z_cent]),']');
red_dot_4_str=strcat('[',...
    num2str([0 y_z_dots(4,1)-y_cent y_z_dots(4,2)-z_cent]),']');
scatter_calc_str=strcat(' '' ',method,''' ');
TS_cell_mat={'','Test_section', 'red_dot_1',red_dot_1_str;...
    '','Test_section', 'red_dot_2',red_dot_2_str;...
    '','Test_section', 'red_dot_3',red_dot_3_str;...
    '','Test_section', 'red_dot_4',red_dot_4_str;...
    '','Test_section', 'red_dot_size',num2str(rd);...
    '','Test_section', 'wavelength',num2str(wavelength);...
    '','Test_section', 'xi',num2str(xi);...
    '','Test_section', 'gamma_ref',num2str(gamma_ref);...
    '','Test_section', 'scatter_calc_meth',scatter_calc_str;...
    '','Test_section', 'half_angle',num2str(half_angle)};
inifile(ini_filename,'write',TS_cell_mat)

% Reference section
save_string=strcat(' '' ',save_pathname,save_file,'-',num2str(1),'_',...
    num2str(cam_loc(1,2)),'.jpg',''' ');
RF_cell_mat={'','Reference', 'angle',num2str(cam_loc(1,2));...
    '','Reference', 'caxis_limits',' ''Auto'' ';...
    '','Reference', 'distance',num2str(cam_loc(1,1));...
    '','Reference', 'cam_height','0';...
    '','Reference', 'registration_image_name',save_string;...
    '','Reference', 'data_image_name',save_string;...
    '','Reference', 'data_image_exposure_time',num2str(cam_loc(1,4))};
inifile(ini_filename,'write',RF_cell_mat)

for kk=2:size(cam_loc,1)
    % Angle section
    angle_name=strcat('Angle',num2str(kk-1));
    save_string=strcat(' '' ',save_pathname,save_file,'-',...
        num2str(kk),'_',num2str(cam_loc(kk,2)),'.jpg',''' ');
    ANG1_cell_mat={'',angle_name, 'angle',num2str(cam_loc(kk,2));...
        '',angle_name, 'caxis_limits',' ''Auto'' ';...
        '',angle_name, 'distance',num2str(cam_loc(kk,1));...
        '',angle_name, 'cam_height','0';...
        '',angle_name, 'registration_image_name',save_string;...
        '',angle_name, 'data_image_name',save_string;...
        '',angle_name, 'data_image_exposure_time',num2str(cam_loc(kk,4))};
    inifile(ini_filename,'write',ANG1_cell_mat)
end

% Output section
limits_y_str=strcat('[',num2str([-(y_sup/2-1)*image_width/y_sup ...
    (y_sup/2-1)*image_width/y_sup]),']');
limits_z_str=strcat('[',num2str([-(z_sup/2-2)*image_height/z_sup ...
    (z_sup/2-1)*image_height/z_sup]),']');
save_dir_str=strcat(' '' ',save_pathname,'processed_output',''' ');
super_pixels_yz_str=strcat('[',num2str([y_sup z_sup-3]),']');
OUT_cell_mat={'','Output', 'limits_y',limits_y_str;...
    '','Output', 'limits_z',limits_z_str;...
    '','Output', 'threshold','5';...
    '','Output', 'caxis_limits',' ''Auto'' ';...
    '','Output', 'limit_full_res_figures',' ''No'' ';...
    '','Output', 'output_eps_figures',' ''No'' ';...
    '','Output', 'max_percent_sat_pixels','1.0';...
    '','Output', 'correction_file_name',' ''../unity_correction.mat'' ';...
    '','Output', 'color_channel','2';...
    '','Output', 'figure_origin','[0.0   0.0   0.0]';...
    '','Output', 'save_dir',save_dir_str;...
    '','Output', 'processing_info_identifier',' ''sim_data'' ';...
    '','Output', 'super_pixel_shape',' ''square'' ';...
    '','Output', 'super_pixels_size',num2str(0.25*image_width/y_sup);...
    '','Output', 'super_pixels_yz',super_pixels_yz_str};
inifile(ini_filename,'write',OUT_cell_mat)
