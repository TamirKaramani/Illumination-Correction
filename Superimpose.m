function Superimpose(I)
% Authors: Karadi Shay & Tamir Karamani
%{
The following function applies the superimpose algorithm to non-uniform illumination images
in order to achieve illumination correction.
%}
%tic is used to calculate the run time of the function
tic
%loading RGB Image
Original = imread(I);
%if the input is an RGB image, then convert to grayscale. else, continue.
if length(size(Original))==3
    Grayscale = rgb2gray(Original); 
else
    Grayscale = Original;
end
%LPF[I(x,y)] - circular filter radius of 10
LPF = imfilter(Grayscale, fspecial('disk',10), 'replicate');
%G(x,y) - gaussian filter window size of 50 x 50 & deviation of 0.5
GaussianFilter = imfilter(Grayscale, fspecial('gaussian',50,0.5),'replicate');
%P = LPF[I(x,y)] - G(x,y) + Mean(G(x,y))
ProposedMethod = LPF - GaussianFilter + uint8(mean(GaussianFilter)); 
%plot results
figure('Name','Superimpose LPF & Gaussian filter','NumberTitle','off');
set(gcf, 'Units', 'Normalized', 'OuterPosition', [0, 0.5, 0.5, 0.5]);
sgtitle(I(1:end-4));
subplot(2,3,1),imshow(Original),title("Original RGB");
subplot(2,3,2),imshow(Grayscale),title("Grayscale");
subplot(2,3,3),imshow(LPF),title("Low Pass Filter");
subplot(2,3,4),imshow(GaussianFilter),title("Gaussian Filter");
subplot(2,3,5),imshow(ProposedMethod),title("Proposed Method");
figure('Name','Superimpose LPF & Gaussian filter','NumberTitle','off');
set(gcf, 'Units', 'Normalized', 'OuterPosition', [0.5, 0.5, 0.5, 0.5]);
sgtitle("Original & Corrected"+newline+"Algorithm time: "+round(1000*toc)+" ms");
subplot(1,2,1),imshow(Original);
subplot(1,2,2),imshow(ProposedMethod);
end



