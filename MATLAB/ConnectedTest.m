currAxes = axes;
A = imread('golf2.jpg');
C = [0, 0, 0, 0, 0, 0, 0, 1, 1;      %1 9  17 25 33 41 49 57 65
     0, 1, 1, 1, 0, 0, 0, 1, 1;      %2 10 18 26 34 42 50 58 66
     0, 1, 1, 1, 0, 0, 0, 0, 1;      %3 11 19 27 35 43 51 59 67
     0, 1, 1, 1, 0, 0, 0, 0, 0;      %4 12 20 28 36 44 52 60 68
     0, 0, 0, 0, 0, 0, 0, 1, 0;      %5 13 21 29 37 45 53 61 69
     0, 0, 0, 0, 0, 0, 0, 0, 0;      %6 14 22 30 38 46 54 62 70
     1, 1, 1, 1, 1, 0, 0, 0, 0;      %7 15 23 31 39 47 55 63 71
     0, 0, 0, 1, 1, 0, 0, 0, 0];     %8 16 24 32 40 48 56 64 72
 
D = [0, 0, 0, 0, 0, 0, 0, 0, 0;      %1 9  17 25 33 41 49 57 65
     0, 1, 1, 1, 0, 0, 0, 0, 0;      %2 10 18 26 34 42 50 58 66
     0, 1, 1, 1, 0, 0, 0, 0, 0;      %3 11 19 27 35 43 51 59 67
     0, 1, 1, 1, 0, 0, 0, 0, 0;      %4 12 20 28 36 44 52 60 68
     0, 0, 0, 0, 0, 0, 0, 0, 0;      %5 13 21 29 37 45 53 61 69
     0, 0, 0, 0, 0, 0, 0, 0, 0;      %6 14 22 30 38 46 54 62 70
     1, 1, 1, 1, 1, 0, 0, 0, 0;      %7 15 23 31 39 47 55 63 71
     0, 0, 0, 1, 1, 0, 0, 0, 0];     %8 16 24 32 40 48 56 64 72
 
 
B = colorChop(A, 100);

Image = B;
imshow(Image);
% Blobs = ConnectedLabel(Image, 0, 0);
% 
% for m = 1:size(Blobs)
%      Blobs(m).FindCenterOfMass();
%      box_X = Blobs(m).MinCol;
%      box_Y = Blobs(m).MinRow;
%      box_W = Blobs(m).MaxCol - Blobs(m).MinCol;
%      box_H = Blobs(m).MaxRow - Blobs(m).MinRow;
%      rectangle('Position',[box_X,box_Y,box_W,box_H],'Edgecolor', 'r');    
% end

Blob2 = ConnectedFind(Image, 1000, 1);
box_X = Blob2.MinCol;
box_Y = Blob2.MinRow;
box_W = Blob2.MaxCol - Blob2.MinCol;
box_H = Blob2.MaxRow - Blob2.MinRow;
rectangle('Position',[box_X,box_Y,box_W,box_H],'Edgecolor', 'r');  
