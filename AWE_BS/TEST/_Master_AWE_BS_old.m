%Set two things:: workDir (on line 4) and outDir (on line 9)

clear all; close all; clc;
% workDir='D:\Work\Whitecap\ASIP_dep3';   %set location of images::
workDir='D:\Work\Whitecap\ASIP_dep3';
cd(workDir);
folders=dir([workDir '\r*']);
folders(([folders(:).isdir]==0))=[];    %only save folders (directories)

%set up the output directory;
outDir='C:\Users\Brian\Desktop\Whitecap_Project\SOAP_Results\Whitecap_results';


%$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
%              Set the processing to developer mode
%
%  The developer mode allows you to view the programs threshold values, and
%  adjust them by using the following keys::
%
%  up    arrow key  == threshold increases by 1
%  down  arrow key  == threshold decreases by 1
%  left  arrow key  == threshold decreases by 15
%  right arrow key  == threshold increases by 15
%
%  return key continues to the final figure
%
%  The final figure shows the PIP, its 1st, 2nd, 3rd & 4th derivatives. It 
%  also shows the local max and min points on the 1st and 2nd derivatives, 
%  the old and new threshold values
%
%$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
normPix=1;     % normalise the vertical columns of the image using the slope 
%normPix=0;

tuning = 1;    %tuning on               %manual tuning of the threshold
derivShow=0;   %show the plot of the PIP, its derivatives and the thresholds
WaWb_analysis=1; %separation of the 
writing=1;     %save files etc
ROI_analysis=0;

%$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
%Global Variable Setup %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
global ButterSample;   %sampling used for the butterworth cuttoff. This will 
ButterSample=0.1;                    %sharpen the step changes in PIP

global cropLength;       %take 5 pixels off the original image
cropLength=5;

global topcropLength
topcropLength=0;

global I_max;          %The maximum intensity value of each image, note; that
I_max=253;                    %matlab indices start at 1, so instead of the normal
                    %[0:255] range, it will be succeeded with [1:256] 

global cutOff;       %Crops the final derivative data and replaces outliers 
cutOff=9;                   %with Nan values
                   


for i=2%1:length(folders)
     files=dir([workDir '\' folders(i).name '\*.jpg']);
     cd(outDir);
    if ~exist(folders(i).name, 'dir')
       mkdir(folders(i).name);
    end
    cd([outDir '/' folders(i).name]);
  
    
%&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
%    For deployment 3, ii will start with the following:
%    1,6,11,16,21,26,31,36,41,46
%        ^^                                (^ is the current marker)
%      
%    This will achieve the desired 0.2Hz processing 
%&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
    
%     for ii=33011:50:length(files)%[24,37,49,60,69,79,80,94,95,20]%
for ii=6:50:1840%length(files)
%Reset values:
processCode = 0;
finalThresh(1,1:2)=[255 0];
        

%$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
% Find derivatives, local max and mins too.
%$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ 
tic;
[PIP_sdx,PIP_s2dx,PIP_s3dx,PIP_s4dx,smoothen,threshold,editImage,peak,opt]...
    =AWE_BS_deriv...
    (files(ii).name,[workDir '\' folders(i).name '\'],normPix);
disp(toc);

%Count the number of regions of interest for each threshold value::
if ROI_analysis==1
[ROI_count,roiDX] = countroi( editImage,threshold );
else
    ROI_count=0/0; roiDX=0/0;    %create Nan values for outputs
end
%Find the Local mins and maxs::
     [LocalMax,LocalMin,peakChange] = AWE_BS_deriv_analysis(...
         PIP_sdx,PIP_s2dx,threshold,1);
     
     
%$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$     
%First filter for images, if its intensity is not over 100, then its too
%dark.
%$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
if max(max(editImage)) <= 100
        rgb=editImage>255;
        editImage = [];
end
%&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
% Purge the LocalMax and Mins below the peak value. The peak value will be
% unchanged from normalisation as a result from the initial PIP calculation
%&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
if ~isempty(LocalMax)
LocalMax=LocalMax(LocalMax(:,1)>peak(1,1),:);
end
if ~isempty(LocalMin)
LocalMin=LocalMin(LocalMin(:,1)>peak(1,1),:);
end




        if ~isempty(editImage)
           if ~isempty(LocalMax)
%&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
%Here the results show that whitecap pixels exist in the PIP. A threshold
%to separate background pixels and whitecap pixels is now carried out::
%$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
%Get max and mins of 2nd derivatives::
[LocalMax2,LocalMin2,peakChange2]=AWE_BS_deriv_analysis(PIP_s2dx,PIP_s2dx,threshold,2);
           
%&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
% Purge the LocalMax and Mins below the peak value. The peak value will be
% unchanged from normalisation as a result from the initial PIP calculation
%&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
if ~isempty(LocalMax2)
LocalMax2=LocalMax2(LocalMax2(:,1)>peak(1,1),:);
end
if ~isempty(LocalMin2)
LocalMin2=LocalMin2(LocalMin2(:,1)>peak(1,1),:);
end
%&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
% First attempt at finding the threshold. 
%
%Firslty, the 'peak' found is used to equivalently find the threshold
%values of the negative to positive crossing of the 1st derivative (N2P),
%then the P2N of the 2nd derivative, then the N2P of the 3rd derivative
%(N2P2) and finally the finalP2N of the 4th derivative.
%&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&

 [N2P,P2N,N2P2, finalP2N] = n2pcrossover(LocalMax,threshold,PIP_sdx,PIP_s2dx,PIP_s3dx,PIP_s4dx,peak );
if ~isempty(N2P)
   processCode=1;
   finalThresh(1,1)=(N2P);
   if ~isempty(P2N)
       processCode=2;
       finalThresh(1,1)=threshold(P2N);
       if ~isempty(N2P2)
           processCode=3;
           finalThresh(1,1)=threshold(N2P2);
           if ~isempty(finalP2N)
               processCode=4;
              finalThresh(1,1)=threshold(finalP2N);
           end
       end
   end
else    %no N2P, P2N, N2P2, finalP2N found::
    processCode=-1;
    finalThresh(1,1)=255;
end
finalThresh(1,2) = sum(sum(editImage>finalThresh(1,1)))*100./(size(editImage,1)*size(editImage,2));




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%7
% second  threshold using the second peak
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
           
                %Now provide the max peak as an alternative threshold that could
                %exclude streaks
                if length(LocalMax(:,1)) > 1 && processCode ~= 0  
                    dispImage = editImage;
                    dispImage(dispImage < (LocalMax(2,1))) = 0;
                    [nr nc] = size(dispImage);
                    numWhite = length(find(dispImage ~= 0));
                    maxPeak(1,1)=LocalMax(2,1);
                    maxPeak(1,2) = numWhite*100 ./(nr*nc);
                    clear dispImage
                    
                else
                    %No max peak
                    maxPeak(1,1:2) = [255,0];

                end
                
                
            else
                %Here if findPeaksTroughs returned an empty LocalMax array
                %This means that there were no whitecaps
                
                finalThresh(1,1:2) = [255,0];
                maxPeak(1,1:2) = [255,0];
                processCode = 10;
            end
            else
            %we are here if the image wasn't read properly or image was too
            %dark indicating a nighttime image
            finalThresh(1,1:2) = [NaN,NaN];
            maxPeak(1,1:2) = [NaN,NaN];
            flag = NaN;
            opt = NaN;
            processCode = NaN;
            disp('Image Not Read Properly Or else too dark');
        end 

%     %Time to write final values to file ;;;; YEEEEE!!!!!
%         allData(ii).name = files(i).name;
%         allData(ii).finalValues = finalThresh;
%         allData(ii).maxPeak = maxPeak;
%         allData(ii).flag = flag;
%         allData(ii).option = 1;
%         allData(ii).processCode = processCode;
        
        disp([num2str(ii) ' of ' num2str(length(files))])

%$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
%                Full on Developer Noob mode Engaged!
%$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

 if tuning ==1 && ~isnan(processCode)
            statuss=1;
            t=finalThresh(1,1);
 
            while statuss==1 
                  %Plot the original and BW image
                  dispImage=editImage>t;
                  subplot(1,2,1),h1=imshow(editImage);
                  title(['# = ' num2str(ii) ' , Code = ' num2str(processCode),' opt= ' num2str(opt) ' normPix = ' num2str(normPix)]);
                  subplot(1,2,2);
                  h2=imshow(dispImage);
                  title(['threshold = ' num2str(t)...
                      ' ,   W(%) = ' num2str(sum(sum(dispImage)).*100./...
                      (size(editImage,1)*size(editImage,2))) ...
                      '  w/ streaks t = ' num2str(maxPeak(1,1))]);

set(gcf,'OuterPosition', [20 20 1920 1080])

                  
                  %Wait for a button to be pressed
                  while waitforbuttonpress~=1; end
                  adj=double(get(gcf,'CurrentCharacter'));
                  if adj == 31 && t>0    %         down arror key
                     t=t-1;
                  elseif adj == 30 && t<255    %     up arrow key
                     t=t+1;
                  elseif adj == 29     %  right arror key
                      if t<241
                      t=t+15;
                      else
                          t=255;
                      end
                  elseif adj == 28 && t>14     %   left arrow key
                     t=t-15;   
                  elseif adj == 13   %hit return key to finish the loop
                     statuss==0; close all; break;
                  end        
            end
% %Show the plot of PIP and its derivatives::
if derivShow==1
plot(threshold,smoothen,'k');
set(gcf,'OuterPosition', [20 20 1920 1080])
hold on;
plot((threshold),PIP_sdx,'r')
plot((threshold),PIP_s2dx,'g')
plot((threshold),PIP_s3dx,'b')
plot((threshold),PIP_s4dx,'m')
plot((threshold),roiDX,'r--')
%plot max and mins
if ~exist('LocalMin2', 'var')
   LocalMin2=[258 -1];
end
if ~exist('LocalMax2', 'var')
   LocalMax2=[258 -1];
end
if ~exist('LocalMin', 'var')
   LocalMin=[258 -1];
end
if ~exist('LocalMax', 'var')
   LocalMax=[258 -1];
end
if ~exist('firstPosNegCross', 'var')
    firstPosNegCross=[258 -1];
    firstNegPosCross=[258 -1];
end
if ~isempty(LocalMin)
plot(LocalMin(:,1),LocalMin(:,2),'vr')
end
if ~isempty(LocalMax) 
    plot(LocalMax(:,1),LocalMax(:,2),'^r')
end
if ~isempty(LocalMin2)
plot(LocalMin2(:,1),LocalMin2(:,2),'vg')
end
if ~isempty(LocalMax2)
plot(LocalMax2(:,1),LocalMax2(:,2),'^g')
end
% plot the neg2pos and pos2 neg
if ~isempty(P2N)
plot(threshold(P2N),PIP_s2dx(P2N(1)),'*r');
end
if ~isempty(N2P)
plot(N2P,PIP_sdx(bsearch(threshold,N2P),1),'sr');
end
plot(finalThresh(1,1),smoothen(bsearch(threshold,finalThresh(1,1)),1),'sk')
%update threshold values            
finalThresh(1,:)=[t sum(sum(dispImage)).*100./(size(editImage,...
                1)*size(editImage,2))]; %update the choices            
%plot the new threshold
plot(finalThresh(1,1),smoothen(bsearch(threshold,finalThresh(1,1)),1),'*k')
%legend and titles
xlabel('thresholds','fontsize',15); legend('PIP','dx','d2x','d3x','d4x','ROI','dx max','dx min','d2x max', 'd2x min','p2n','n2p','awe t', 'tuned t');
set(gca,'Xlim',[0 255]);
while waitforbuttonpress~=1; end       %press any key to abort ...wheres the 'any' key?  
 end
end
%$$$$$$$$$$$$$$$$$$$$$$$$$$$$ developer Mode ended %%%%%%%%%%%%%%%%%%%%%%%%

%&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
           %Stage A and stage B analysis
%$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
%Here I will use my old program as a function distinguish the whitecap
%pixels as either stage-A or stage-B::
if ~isnan(processCode) && WaWb_analysis==1
    close all
[Wa,Wb,W,PixIdx_A,PixIdx_B,rgb]=Wa_Wb_program(editImage,dispImage);

else 
    W=0; Wa=0; Wb=0; PixIdx_A=[]; PixIdx_B=[]; 
end
%write the W values to a 'WC.txt' file 
if writing==1 
fid = fopen('WC.txt', 'a');
fprintf(fid, '%d %s        %6.6f          %12.6f          %18.6f          \r\n', ii, files(ii).name(1:end-4),Wa,Wb,W);
fclose(fid);
%save the regionprops PixIdx data to file
imwrite(rgb, [files(ii).name(1:end-4) '.tiff']);
%save rgb image
save(files(ii).name(1:end-4),'PixIdx_A', 'PixIdx_B','rgb');
end

clear Wa Wb W PixIdx* rgb
    end
    
    

    
    
    
end
    
