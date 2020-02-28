function result = GetClosestBlob(Blobs, PredCenter, PredSize, minSize)
    % Search through the blobs that are found and pick most likely one that
    % is our object.
    %
    % Key criteria of this function is to not lock on to false positives.
    % Several methods that could do that:
    %    1. Make sure area is as expected (implemented).  Areas that are
    %    radically different will be rejected.
    %    2. Look for movement in expected direction.  This would probably
    %    require nominating candidate blobs and monitoring what they do
    %    over several frames.  **Not implemented yet**
  
    % Pcnt difference in area allowed
    AREA_CUTOFF_RANGE = 0.4;
    
    predArea = PredSize(1) * PredSize(2);
    target = [];
    minRank = 1000000;
    
    for m = 1:size(Blobs)  
        blobArea = Blobs(m).Width * Blobs(m).Height;
        
        if(blobArea > minSize)
            Blobs(m) = Blobs(m).MakeSquare();                                  %Have to do this to get adjusted sizes
            dist = Distance(PredCenter, Blobs(m).adjCenter);
            areaDiff = abs(predArea - blobArea);

            %Size cutoff check
            if(abs(areaDiff) <= AREA_CUTOFF_RANGE * blobArea)
                   
                %BEST CANDIDATE CHECK
                %TODO: Can judge best candidate by a combination of distance
                %from expected spot and differnece from expected area
                if(dist  < minRank)
                    minRank = dist ;
                    target = Blobs(m);
                end
            end
        end
    end

    result = target;    
end