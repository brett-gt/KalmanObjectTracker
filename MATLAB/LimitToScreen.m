function result = LimitToScreen(X, Y, W, H, screenW, screenH)
    % Given a box defined by X,Y,W,H where (X,Y) = lower left corner, this
    % function returns a (XLL,YLL) and (XUR, YUR) where XLL,YLL are lower
    % left coordinates and XUR, YUR are upper right coordinates.  The
    % coordinates are bounded to be within the screen on all sides.
    
    if(X < 1)
        X = 1;
    end
    if(Y < 1)
        Y = 1;
    end
    
    endX = X + W;
    if(endX > screenW)
        endX = screenW;
    end
    
    endY = Y + H;
    if(endY > screenH)
        endY = screenH;
    end
    
    result = [Y, X, endY, endX];
end