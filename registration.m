clc
clear variables
close all
%% Determening paths and setting folders
currdir = pwd;
addpath(pwd);
filedir = uigetdir();
cd(filedir);
files = dir(filedir);
dirFlags = [files.isdir];
subFolders = files(dirFlags);
numbers = zeros(2,1);
counter = 0;
%% folder names and numbers
for i = 1:numel(subFolders)
    if length(subFolders(i).name)>2
        counter = counter + 1;
        numbers(counter) = str2double(subFolders(i).name(end-3:end));
    end
end
numbers = sort(numbers);
name = subFolders(4).name(1:end-3);
%% loading images
for i = 1:length(numbers)
    if length(num2str(numbers(i)))== 1
        cd([filedir, '/', name, num2str(0), num2str(0), num2str(numbers(i))]);
    elseif length(num2str(numbers(i)))== 2
        cd([filedir, '/', name, num2str(0), num2str(numbers(i))]);
    elseif length(num2str(numbers(i)))== 3
        cd([filedir,'/', name, num2str(numbers(i))]);
    end
    a = imread('handCorrection.tif');
    array(i).img = a; 
    array2(i).img = imclearborder(imcomplement(array(i).img(2:end-1,2:end-1,1)),4);
    array2(i).img = bwareaopen(array2(i).img, 10,4);
end
cd(filedir)
if exist([filedir, '/registered'],'dir') == 0
    mkdir(filedir,'/registered');
end
reg_dir = [filedir, '/registered'];
cd(reg_dir);
cc = bwconncomp(array2(1).img(:,:,1),4);
array3(1).img = labelmatrix(cc);
array4(1).img = array3(1).img;
labels = regionprops(cc, array3(1).img,'MeanIntensity','Centroid');
image = figure;
imshow(array3(1).img, [0,1]);
hold on 
for k= 1:numel(labels)
    c_labels = text(labels(k).Centroid(1), labels(k).Centroid(2), sprintf('%d', labels(k).MeanIntensity),...
        'HorizontalAlignment', 'center',...
        'VerticalAlignment', 'middle', 'Fontsize', 12);
    set(c_labels,'Color',[1 0 0])
    hold on
end

% if length(num2str(numbers(i)))== 1
%     image_filename = [name, num2str(0), num2str(0), num2str(numbers(i))];
% elseif length(num2str(numbers(i)))== 2
%     image_filename = [name, num2str(0), num2str(numbers(i))];
% elseif length(num2str(numbers(i)))== 3
%     image_filename = [name, num2str(numbers(i))];
% end
image_filename = [name, num2str(0), num2str(numbers(1))];
print(image, '-dtiff', '-r150', image_filename);
close all
counter2 =uint32(max(array3(1).img(:)));

%% Registrations
for i = 2:length(numbers)
    cc = bwconncomp(array2(i).img(:,:,1),4);
    array3(i).img = labelmatrix(cc);
    array4(i).img = zeros(size(array3(1).img,1),size(array3(1).img,2));
    labels = regionprops(cc, array3(i).img,'MeanIntensity','Centroid','PixelList');
    number = zeros(numel(labels),1);
    for k=1:numel(labels)
        Pixels = array4(i-1).img(array3(i).img==k);
        if (length(Pixels(Pixels==mode(Pixels)))/length(Pixels)>0.5) && mode(Pixels)~=0
        number(k) = mode(array4(i-1).img(array3(i).img==k));
        elseif number(k) == 0
            counter2 = counter2 + 1;
            number(k) = counter2;
        end
        array4(i).img(array3(i).img==k) = number(k);
    end
    

    u=unique(number);
    n=histc(number,u);
    repeatedcell = u(n>1);
    if isempty(repeatedcell)==0
        for ll = 1:length(repeatedcell)
            data = regionprops(cc, array3(i).img,'MeanIntensity','Centroid');
            Int =cat(1,data.MeanIntensity);
            Center= cat(1,data.Centroid);
            cc_pre = bwconncomp(array2(i-1).img(:,:,1),4);
            data_pre = regionprops(cc_pre, array4(i-1).img,'MeanIntensity','Centroid');
            Int_pre = cat(1,data_pre.MeanIntensity);
            Center_pre= cat(1,data_pre.Centroid);
            cells2 = find(number == repeatedcell(ll));
            dist = zeros(length(cells2),1);
            for m = 1:length(cells2)
                dist(m) = sqrt((Center(Int == cells2(m),1) - Center_pre(Int_pre == repeatedcell(ll),1))^2 +...
                    (Center(Int == cells2(m),2) - Center_pre(Int_pre == repeatedcell(ll),2))^2);
            end
            [Num, Ind] = min(dist);
            for m = 1:length(cells2)
                if m ~= Ind
                    counter2 = counter2 + 1;
                    number(cells2(m)) = counter2;
                    array4(i).img(array3(i).img==cells2(m)) = number(cells2(m));
                end
            end
        end
    end
    
    labels2 = regionprops(cc, array4(i).img,'MeanIntensity','Centroid');
    image = figure;
    imshow(array4(i).img, [0,1]);
    hold on
    for k= 1:numel(labels2)
        c_labels = text(labels2(k).Centroid(1), labels2(k).Centroid(2), sprintf('%d', labels2(k).MeanIntensity),...
            'HorizontalAlignment', 'center',...
            'VerticalAlignment', 'middle', 'Fontsize', 12);
        set(c_labels,'Color',[1 0 0])
        hold on
    end
    if length(num2str(numbers(i)))== 1
        image_filename = [name, num2str(0), num2str(0), num2str(numbers(i))];
    elseif length(num2str(numbers(i)))== 2
        image_filename = [name, num2str(0), num2str(numbers(i))];
    elseif length(num2str(numbers(i)))== 3
        image_filename = [name, num2str(numbers(i))];
    end
    
    print(image, '-dtiff', '-r150', image_filename);
    close all
    if max(array4(i).img(:))>counter2
        counter2 = max(array4(i).img(:));
    end
end

%% Cell counting
cells = struct([]);
summary = zeros(1,3);
start = double(max(array4(1).img(:))+1);
if double(sum(array4(end).img(:)))==0
    finish = counter2;
else
    finish = double(min(array4(end).img(array4(end).img~=0))-1);
end
for i = start:finish
    temp = 0;
    for k = 2:(length(numbers)-1)
        count = nnz(array4(k).img==i);
        if count >0
            temp = temp +1;
            cells{i-start+1}(temp,1) = count;
        end
    end
    summary(i-start+1,1) = i;
    summary(i-start+1,2) = sum(cells{i-start+1});
    summary(i-start+1,3) = length(cells{i-start+1});
end
summary(summary(:,3) < 4,:) = [];
headers = {'cell', 'total area px', 'number of z-stack'};
Summary_filename = 'Summary.csv';
csvwrite_with_headers(Summary_filename,summary,headers);
cd(currdir);
clear variables
clc