function [closedImg] = generateClosedContour(img, method)
%Generate Closed contour 
% Two methods: convex hull matlab, linear custom 

  % Initialize output
  closedImg = zeros(size(img));
  aux = zeros(size(img));
  if ~exist('method','var')
    method = 'hull';
  end
  
  %--------------------- Method most rudimentar
  if strcmp(method,'hull')
    closedImg = bwconvhull(img);
    
  %---------------------- Caxeiro viajante 
  elseif strcmp(method, 'tsp')
     closedImg = tsp(img);
     
  %---------------------- Matlab implementation
  elseif strcmp(method, 'linear_matlab')
    aux = squeeze(img);
    [Xpoly, Ypoly] = ind2sub(size(aux), find(aux));
    closedImg = poly2mask(Xpoly,Ypoly,size(aux,1),size(aux,2));
    
  %--------------------- first degree interpolation
  elseif strcmp(method,'linear') || strcmp(method, 'linear_imp')...
          || strcmp(method, 'linear_centroid') ||  strcmp(method, 'knn')
   
    % Getting points in contour
   % fh = figure();
   % imshow(zeros(size(img)),'InitialMagnification',100);
      % disp('here')
      if strcmp(method, 'linear')
            [Xorder, Yorder] =  sortPointsPolar(img);
      elseif strcmp(method, 'linear_centroid')
            %       disp('here')
            [Xorder, Yorder] =  sortPointsPolar(img, true);
      elseif strcmp(method, 'knn')
           aux = squeeze(img);
           [Xpoly, Ypoly] = ind2sub(size(aux), find(aux));
           [Xorder, Yorder] = points2contour(Xpoly,Ypoly,1,'cw');
           Yorder = Yorder';
           Xorder = Xorder';
      end
     % initialize answer
     ptsNotConnected = 0;
     for idx_pt=1:size(Xorder,1)-1
         
         % Getting limits of grid of interested
         minX = min(Xorder(idx_pt), Xorder(idx_pt+1));
         maxX = max(Xorder(idx_pt), Xorder(idx_pt+1));
         minY = min(Yorder(idx_pt), Yorder(idx_pt+1));
         maxY = max(Yorder(idx_pt), Yorder(idx_pt+1));
         
         % verifying if points are not already neighboors
         if ( (maxX-minX)^2 + (maxY-minY)^2 > 2)

             ptsNotConnected = ptsNotConnected + 1;
             
             % If interpolation is possible
             if (Xorder(idx_pt) ~= Xorder(idx_pt+1) && ...
                 Yorder(idx_pt) ~= Yorder(idx_pt+1) )
                 [Vq,gridX,gridY] = setValuesInterpolation(Xorder(idx_pt),...
                                              Xorder(idx_pt+1),...
                                              Yorder(idx_pt),...
                                              Yorder(idx_pt+1));

             % Matlab function need 2 x and 2 y distincts
             else 
                 if(Xorder(idx_pt)== Xorder(idx_pt +1 ))
                       [Vq,gridX,gridY] = setValuesInterpolation(Xorder(idx_pt),...
                                              Xorder(idx_pt+1)+1e-10,...
                                              Yorder(idx_pt),...
                                              Yorder(idx_pt+1));

                 else
                       [Vq,gridX,gridY] = setValuesInterpolation(Xorder(idx_pt),...
                                              Xorder(idx_pt+1),...
                                              Yorder(idx_pt),...
                                              Yorder(idx_pt+1)+1e-10);
                 end
                 
            end

            % Threshold to consider point 
              Vq(Vq>=0.5) = 1;
             
            % Filling points that equal to one
 
             [IdxX, IdxY] = ind2sub(size(Vq), find(Vq));
             ind = sub2ind(size(img), uint64(gridX(IdxX)),...
                                     uint64(gridY(IdxY)));
               
           % tic;
        %    for i=1:size(IdxX,1)
        %        closedImg(uint64(gridX(IdxX(i))),uint64(gridY(IdxY(i)))) = 255;
        %    end
           % toc;
           % tic;
            closedImg(ind) = 255;
           % toc;
           
         end
         
     end
      if(strcmp(method,'knn'))
           aux = squeeze(closedImg);
           [Xpoly, Ypoly] = ind2sub(size(aux), find(aux));
           [Xorder, Yorder] = points2contour(Xpoly,Ypoly,1,'cw');
           YpolySorted = Yorder';
           XpolySorted = Xorder';
      else
        [XpolySorted, YpolySorted] = sortPointsPolar(closedImg);
      end
      closedImg = poly2mask(YpolySorted,...
                             XpolySorted,...
                             size(closedImg,1),...
                             size(closedImg,2));
      
%   fprintf('\tOut %d\n', sum(closedImg(ind)));

 %  fprintf('\tPoints not connected %d out of %d\n', ptsNotConnected, size(Xorder,1));
  elseif strcmp(method,'linear_centroid')
      
  % -------------------- Other case
  else 
     msg = 'This method is not implemented yet, try one of the following list: hull, linear, linear_imp';
     disp(msg);
     %error('This method is not implemented yet, try one of the following list: hull, linear')
  end

end

