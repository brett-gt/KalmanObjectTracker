function result = pointIsObject(Image, posX, posY)
    % Function tests the point (posX, posY).  If it is part of foreground, it labels
    % that object.  Idea is that if we have an object dead center, it is 
    % probably what we are looking for and assuming that can save a bunch of 
    % processing.  If it is, this blob is assumed to be the
    % blob we are looking for and it is returned. 
    %
    % Arguments:
    %      Image - image to be searched for blob
    %      posX, posY - location in image to be checked
    %
    % Returns:
    %      Blob if (posY,posX) = 1, if not return will be EMPTY
    %
    % TODO: Since most of this algorithm is part of ConnectedLabel, can
    % probably figure out a way to call this from it.

    
    %Connected-component matrix is initialized to size of image matrix.
    [M, N]=size(Image);
    Connected = zeros(M,N);

    Offsets = [-1; M; 1; -M]; %In linear index, this would be -X, +Y, X, -Y
    Index = [];
    Blobs = Blob;
	
   % A row-major scan is started for the entire image.
   % ** Linear index goes through column first
   
   % If an object pixel is detected, then following steps are repeated while (Index !=0)
   if(Image(posY,posX)==1)                                       % If a foreground object
        Index = ((posX-1)*M + posY);                             % Add this point to the index (2D to 1D dimension conversion)
        Connected(Index) = 1;                         

        Blobs = Blobs.AddPoint(posY,posX);                       % Have to set update = to itself for it to work

        while ~isempty(Index)                                    % Loop through Index array, this is all points left to check
            Image(Index) = 0;                                    % Set current pixel to 0 (so don't test in future)
            Neighbors = bsxfun(@plus, Index, Offsets');          % Creates an array of neighboring array elements, bsxfun: https://www.mathworks.com/help/matlab/ref/bsxfun.html
            Neighbors = unique(Neighbors(:));                    % The (:) linearizes the array.  Unique returns values found only once.
            Neighbors = Neighbors(find(Neighbors < M*N & Neighbors > 0));
            Index = Neighbors(find(Image(Neighbors)));           % Find returns only the non-zero indicees

            Connected(Index) = 1;                                % Update the map of connected objects

            for z=1:length(Index)                                % Loop through and update our Blobs
                linear = Index(z);                               % Grab this particular index
                col_ = ceil(linear/M);                           % Backout the column
                row_ = mod(linear-1,M) + 1;                      % Backout the row, note math here is because Matlab indexing starts with 1

                Blobs = Blobs.AddPoint(row_,col_);               %Add the point to the blob
            end
        end

       %Have already adjusted to scren coordinates since we reference
       %index off of posX and posY (as opposed to normal connected label
       %which deals only in sub-frame coordinates
       %Blobs = Blobs.ToScreenCoord(0, 0);
   end
   result = Blobs;    
end
   
    
  % REFRENCES
  
  %https://en.wikipedia.org/wiki/Connected-component_labeling
  
  %C# Implementation
  %https://www.geeksforgeeks.org/connected-components-in-an-undirected-graph/
  