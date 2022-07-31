function AdaptiveEnhancement(Im)
% Authors: Karadi Shay & Tamir Karamani
%{
The following function applies the Adaptive Enhancement algorithm to non-uniform illumination images
in order to achieve illumination correction.
%}
%tic is used to calculate the run time of the function
tic
%Part 1 - Luminance Estimation Using Just-Noticeable-Difference-Based Filter
%Loading original RGB image
Original = imread(Im); 
%Grayscale image
Grayscale = rgb2gray(Original);
%Eq 1 - Y channel in YCbCr space
Y = double(0.2989 * Original(:,:,1) + 0.578 * Original(:,:,2) + 0.114 * Original(:,:,3)); 
%kernel window checks the neighbors of the center pixel which is '0'
kernel = [1 1 1; 1 0 1; 1 1 1];
%calculates the sum of all neighbors and store it at the center pixel
sumImage = conv2(Grayscale, kernel, 'full');
%counts the number of neighbours of the center pixel (8 or less)
countneighbers = conv2(ones(size(Grayscale)), kernel, 'full');
%L - background luminance of the pixel located at (i,j),formed by locally averaging operation within a small (3 ª 3) neighborhood.
L = sumImage(2:end - 1, 2:end - 1) ./ countneighbers(2:end - 1, 2:end - 1);
%Eq 3,4 - lightness adaptation as the dominant factor in JND estimation.
Pjnd = zeros(size(Y));
[row,col] = size(Y);
for i = 1:row
    for j = 1:col
        if L(i,j) <= 127            
            Pjnd(i,j) = 17 * (1 - sqrt(L(i,j) / 127)) + 3;
        else
            Pjnd(i,j) = (3 / 128) * (L(i,j) - 127) + 3;            
        end
    end
end
%Eq 5-7 - Yjnd(i,j) is the adaptively smoothed luminance 
Yjnd = zeros(size(Y));
%The standard deviation, sigma, chosen according to the article
sigma = 4;
[row,col] = size(Y); 
for i = 1:row
    for j = 1:col
        for s = [i-1,i,i+1]
            if s == 0 || s == row + 1
                continue
            end
            for t = [j - 1,j,j + 1] 
                if t == 0 || t==col + 1 || (s == i && t == j)
                    continue                  
                elseif Y(i,j) == 0 
                    continue                
                elseif (Y(s,t) - Y(i,j)) < -Pjnd(Y(i,j))
                    Q = double(Y(i,j)) - Pjnd(Y(i,j));                
                elseif abs(Y(s,t) - Y(i,j)) <= Pjnd(Y(i,j))
                    Q = double(Y(s,t));                
                elseif (Y(s,t) - Y(i,j)) > Pjnd(Y(i,j))
                    Q = double(Y(i,j)) + Pjnd(Y(i,j));
                end
                Yjnd(i,j) = Yjnd(i,j) + exp(( -1/(2 * sigma ^ 2)) * ((i - s) ^ 2 + (j - t) ^ 2)) * Q;
             end
        end            
    end
end    
%1/w is the normalization factor achieved by dividing Yjnd by its max value.   
w = max(max(Yjnd));
Yjnd = Yjnd ./ w; 
%Part 2 - Adaptive Modification to Luminance Eq 11-13
%Ymedian (Low & High) as the median intensity value in the input luminance image Y, and is used to represent global luminance.
%Arbitrary values according to the article.
Ymlow = 0.4;
Ymhigh = 0.6;
Ym = mean([Ymlow,Ymhigh]);
Hlow = Yjnd + 0.5 * Ymlow;
Hhigh = 2 * Yjnd * (1 - Ymhigh);
%The parameter T represents the pixel-wise demarcation between underexposure and overexposure.
T = (1 - Ym) ./ (1 + exp(10 * (Yjnd - 0.7)));
%Ysym is the modified luminance by SNRF (symmetric Naka–Rushton formula)
Ysym = zeros(size(Y));
Yn = Y ./ 255;
for i = 1:row
    for j = 1:col
         if Yn(i,j) <= T(i,j)
             Ysym(i,j) = Yn(i,j) * (T(i,j) + Hlow(i,j)) ./ (Yn(i,j) + Hlow(i,j));
         else
             Ysym(i,j) = 1 - (1 - Yn(i,j)) * ((1 - T(i,j)) + Hhigh(i,j)) ./ ((1 - Yn(i,j)) + Hhigh(i,j));
         end
    end
end
%Part 3 - Color Image Reconstruction Eq 15
I = zeros(size(Original));
for k=1:3
    I(:,:,k) = double(Original(:,:,k)) ./ 255 .* (Ysym ./ Yn) .^ (1 - sqrt(double(Original(:,:,k)) ./ 255));
end
%Part 4 - Local Contrast Compensation Eq 18
O = zeros(size(I));
%Apply bilateral filter to the image
BF = imbilatfilt(I);
for i = 1:row
    for j = 1:col
        for k = 1:3
            if I(i,j,k) <= BF(i,j,k)
               O(i,j,k) = I(i,j,k) ^ ((BF(i,j,k) / (I(i,j,k))) ^ 2);
            else
               O(i,j,k) = 1 - ((1 - I(i,j,k)) ^ (((1 - BF(i,j,k)) / (1 - I(i,j,k))) ^ 2));
            end
        end
    end
end
figure('Name','AdaptiveEnhancement','NumberTitle','off');
set(gcf, 'Units', 'Normalized', 'OuterPosition', [0, 0.5, 0.5, 0.5]);
sgtitle(Im(1:end-4));
subplot(3,2,1),imshow(Original),title("Original RGB");
subplot(3,2,2),imshow(Yjnd),title("Just-Noticeable-Difference-Based Filter");
subplot(3,2,3),imshow(Ysym),title("Luminance modification based on SNRF");
subplot(3,2,4),imshow(I),title("Color image reconstruction");
subplot(3,2,5),imshow(O,[]),title("Local contrast compensation");
figure('Name','AdaptiveEnhancement','NumberTitle','off');
set(gcf, 'Units', 'Normalized', 'OuterPosition', [0.5, 0.5, 0.5, 0.5]);
sgtitle("Original & Corrected"+newline+"Algorithm time: "+round(1000*toc)+" ms");
subplot(1,2,1),imshow(Original);
subplot(1,2,2),imshow(O,[]);


end

