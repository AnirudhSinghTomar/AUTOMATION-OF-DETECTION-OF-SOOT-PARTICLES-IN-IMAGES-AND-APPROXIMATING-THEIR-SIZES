close all;clear all;
TEMscale = 1; % e.g. 200 nm per 200 pixels in the scale bar
maxImgCount = 255; % Maximum image count for 8-bit image
SelfSubt = 0.8; % Self-subtraction level
mf = 1; % Median filter [x x] if needed
alpha = 0.1; % Shape of the negative Laplacian “unsharp” filter 0∼1
rmax = 30; % Maximum radius in pixel
rmin = 4; % Minimun radius in pixel
sens_val = 0.75; % the sensitivity (0∼1) for the circular Hough transform
ImgFile = ['TEM Images.png']; % soot TEM image
% If dpAutomatedDetection is called up as a function…
%[dpdist] = dpAutomatedDetection(TEMscale,maxImgCount,SelfSubt,mf,alpha,rmin,rmax,sens_val,ImgFile);
%function[dpdist] = dpAutomatedDetection(TEMscale,maxImgCount,SelfSubt,mf,alpha,rmin,rmax,sens_val,ImgFile)
II1=double(imread(ImgFile));
OriginalImg = II1;

%% - step 1: invert
if size(OriginalImg,1) > 900
II1(950:size(II1,1), 1:250) = 0;% ignore scale bar in the TEM image x 1-250 pixel and y 950-max pixel
end
II1_bg=SelfSubt*II1; % Self-subtration from the original image
II1=maxImgCount-II1;
II1=II1-II1_bg;
II1(II1<0)=0;
figure();imshow(II1, []);title('Step 1: Inversion and self-subtraction');
% - step 2: median filter to remove noise
II1=rgb2gray(II1);
II1_mf=medfilt2(II1);
figure();imshow(II1_mf);title('Step 2: Median filter');
% - step 3: Unsharp filter
f = fspecial('unsharp', alpha);
II1_lt = imfilter(II1_mf, f);
figure();imshow(II1_lt, []);title('Step 3: Unsharp filter');
%% Canny edge detection
BWCED = edge(II1_lt,'canny');
figure();imshow(BWCED);title('Step 4: Canny edge detection');

%% Find circles within soot aggregates
[centersCED, radiiCED, metricCED] = imfindcircles(BWCED,[rmin rmax], 'objectpolarity', 'bright', 'sensitivity', sens_val, 'method', 'twostage');
% - draw circles
figure();imshow(OriginalImg,[]);hold;h = viscircles(centersCED, radiiCED, 'EdgeColor','r');
title('Step 5: Parimary particles overlaid on the original TEM image');
%% - check the circle finder by overlaying the CHT boundaries on the original image
R = imfuse(BWCED, OriginalImg,'blend');
figure();imshow(R,[],'InitialMagnification',500);hold;h = viscircles(centersCED, radiiCED, 'EdgeColor','r');
title('Step 6: Primary particles overlaid on the Canny edges and the original TEM image');
dpdist = radiiCED*TEMscale*2;
save([ImgFile '_dp.mat'], 'dpdist_CED', 'centersCED', 'metricCED'); % Save the results
%end % for the dpAutomatedDetection function