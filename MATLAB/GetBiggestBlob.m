function result = GetBiggestBlob(Blobs)
    bigArea = 0;
    largest = Blobs(1);
    
    
    for m = 1:size(Blobs)   
        if(getArea(Blobs(m)) > bigArea)
            largest = Blobs(m);
            bigArea = getArea(Blobs(m));
        end
    end
    result = largest;
end