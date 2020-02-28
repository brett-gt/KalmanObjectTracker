function result = gotLucky(Image, posX, posY)
    % ConnectedFind - searches through Image to locate blob
    %
    % To save processing time, algorithm first looks as (posY, posX) to see
    % if it is part of a blob.  If it is, this blob is assumed to be the
    % blob we are looking for and it is returned.  Otherwise, a connected
    % component labeling algorithm is used to find the object.
    %
    % Arguments:
    %      Image - image to be searched for blob
    %      posX, posY - suspected location of ideal blob
    %
    % Returns:
    %      Array of all blobs found, if none are found array will be EMPTY

    
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

       Blobs = Blobs.Finish(0, 0);
   end
   result = Blobs;    
end
   
    
  % REFRENCES
  
  %https://en.wikipedia.org/wiki/Connected-component_labeling
  
  %C# Implementation
  %https://www.geeksforgeeks.org/connected-components-in-an-undirected-graph/
  
  
                        
%                       Neighbors = []
%                       if(row > 1)
%                         Neighbors = [Neighbors;((col-1)*M + row-1)];    
%                       end
%                       if(row < M)
%                          Neighbors = [Neighbors;((col-1)*M + row+1)];  
%                       end
%                       if(col > 1)
%                         Neighbors = [Neighbors;((col-2)*M + row)];  
%                       end
%                       if(col < N)
%                         Neighbors = [Neighbors;((col)*M + row)];
%                       end