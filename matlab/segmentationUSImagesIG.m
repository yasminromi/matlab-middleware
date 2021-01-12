% Projeto final -  Segmenta��o de colon de camundongos
% 
% Author: Renata Porciuncula Baptista - r.baptista@poli.ufrj.br
% Orientador: Joao Carlos Machado - jcm@peb.ufrj.br
% Date: 16 August 2019, v1.1 
%        07 September 2019, v2.0


function [masksActivated,...
         volTotalEstimated,...
         volMasks] = segmentationUSImagesIG(optionClosedFunction, ...
                                        ratioPixelMeter, distanceBetweenLayer,...
                                        images_filename, rootImages, ...
                                        GT_filename, rootMask,...
                                        type_filter,...
                                        level_processing,...
                                        stringTumorLayer,...
                                        IDX_LAYER,...
                                        save_option, root)
    
   
    % Warningss
    warning('off', 'Images:initSize:adjustingMag'); % turning off warning size image

    % Briefing about the code
    fprintf('--------------------------------------------------------\n\n');
    fprintf('               SEGMENTATION US SCRIPT                   \n\n');
    fprintf('Author: Renata Baptista\n');
    fprintf('Email: r.baptista@poli.ufrj.br\n');
    fprintf('v3 - 22/1/2019 \n');
    fprintf('--------------------------------------------------------\n\n');

    fprintf('optionClosedFunction ')
    fprintf(jsonencode(optionClosedFunction))
    fprintf('\n')
    fprintf('ratioPixelMeter ')
    fprintf(jsonencode(ratioPixelMeter))
    fprintf('\n')
    fprintf('distanceBetweenLayer ')
    fprintf(jsonencode(distanceBetweenLayer))
    fprintf('\n')
    fprintf('images_filename ')
    fprintf(jsonencode(images_filename))
    fprintf('\n')
    fprintf('rootImages ')
    fprintf(jsonencode(rootImages))
    fprintf('\n')
    fprintf('GT_filename ')
    fprintf(jsonencode(GT_filename))
    fprintf('\n')
    fprintf('rootMask ')
    fprintf(jsonencode(rootMask))
    fprintf('\n')
    fprintf('type_filter ')
    fprintf(jsonencode(type_filter))
    fprintf('\n')
    fprintf('level_processing ')
    fprintf(jsonencode(level_processing))
    fprintf('\n')
    fprintf('stringTumorLayer ')
    fprintf(jsonencode(stringTumorLayer))
    fprintf('\n')
    fprintf('IDX_LAYER ')
    fprintf(jsonencode(IDX_LAYER))
    fprintf('\n')
    fprintf('save_option ')
    fprintf(jsonencode(save_option))
    fprintf('\n')
    fprintf('root ')
    fprintf(jsonencode(root))
    fprintf('\n')


    % ---------------------- TREATING OPTIONAL ARGUMENTS
    if ~exist('save_option','var')
      save_option = false;
    end
    if ~exist('type_init','var')
      type_init = 'hull';
    end
    if  ~exist('level_processing', 'var')
        level_processing = 2;
    end
    

       
    % ------------------------ PATHS, INITIALIZATION
    % Root path 
    % Constants
    INITIAL_MASK = 1;
    %NB_IMG = size(images_filename, 1);

    % Load data
    fprintf('Loading images:\n')
    tic;

    % Data
    images = imReadArray(images_filename, rootImages, false);
    masks = imReadArray(GT_filename, rootMask, true);
    idxMasksToNotCompute = getIndexFromName(images_filename,GT_filename);
    steps_vector = diff(idxMasksToNotCompute);
    idxMaskToCompute = setdiff(1:size(images_filename,1), idxMasksToNotCompute);
    % Constant
    NB_MASK = size(masks, 1);

    % Output
    masksInterpolated = zeros(size(images));
    masksActivated = zeros(size(images));
    toc;
    
    %% Filtering
    fprintf('\nFiltering images:\n')
    tic;
    if strcmp(type_filter,'None')
         disp(['User opt for not filter images'])
    else
       images = filterArray(images, type_filter);
    end
    toc;
    %% Interpolating
    % first, getting contours
    masksGrad = imGradientArray(masks);

    fprintf('\nInterpolating images between well defined masks:\n')
    tic;
    % coordinates of non null
    cum_step = 0;
    for iMask = 1:NB_MASK - 1
        maskCurrent = squeeze(masksGrad(iMask,:,:));
        maskNext = squeeze(masksGrad(iMask+1,:,:));
        % Finding points non null mask Current
        [Xcur, Ycur] = ind2sub(size(maskCurrent), find(maskCurrent));
        [Xnext, Ynext] = ind2sub(size(maskNext), find(maskNext));

        Zcur = ones(size(Xcur)) * (INITIAL_MASK + cum_step);
        cum_step = cum_step+abs(steps_vector(iMask));
        Znext = ones(size(Xnext)) * (INITIAL_MASK + cum_step);

        for idxPt=1:size(Xcur,1) % for each point non null in maskCur,
                              % find closest in mask Next
                              % then determine all the points on the line
                              % between and draw then as one in the
                              % maskInterpolated
            ptA = [Xcur(idxPt), Ycur(idxPt), Zcur(idxPt)];
            closestB = findClosestPoint(ptA, [Xnext, Ynext, Znext]);
            coordinates = getCoordinatesOnTheLine(ptA, closestB, steps_vector(iMask));
            XYZ = round(coordinates);

            % linear indexing to change all points at once
            ind = sub2ind(size(masksInterpolated), XYZ(:,3),XYZ(:,1),XYZ(:,2));  
            masksInterpolated(ind) = 255;

        end
    end
    toc;

    % Works well, problem is not continous

    %% Closing the mask to initialize active contour
    fprintf('\nClosing initial contour:\n')
    tic;
    closedContour = zeros(size(images));

    for idx = idxMaskToCompute 
        img = squeeze(masksInterpolated(idx,:,:));
        closedContour(idx,:,:) = generateClosedContour(img, optionClosedFunction);
      %  figure(idx)
      %  imshow(squeeze(closedContour(idx,:,:)),[])
    end
    toc;

    %% Improving contour with active contour
    if level_processing == 2 
        fprintf('\nImproving contours with active contour:\n')
        tic;
        for idx = idxMaskToCompute 
            closedPoly = squeeze(closedContour(idx,:,:));
            closedPoly(closedPoly>0) = 255;
            figure(idx)
            img = squeeze(masksInterpolated(idx,:,:));
            masksActivated(idx,:,:) = activecontour(squeeze(images(idx,:,:)),...
                                                    closedPoly,...
                                                    'edge',...
                                                    'SmoothFactor',...
                                                    1.,...
                                                    'ContractionBias',...
                                                    0.0);
            contour = squeeze(masksActivated(idx,:,:));
            imshow([img closedPoly contour])
        end

        toc;
    else
        tic;
           masksActivated = masksInterpolated;
        toc;
    end
        
    %% Visualizing final results

    for idx = idxMaskToCompute 

        % Principal variables
        contour = squeeze(masksActivated(idx,:,:));
        image = squeeze(images(idx,:,:));
        valmax = max(max(image));

        % getting contour monochromatic
        SE = strel('disk',1);
        grad = imdilate(contour,SE) - imerode(contour,SE);
        resu = max(image,2.0*valmax*grad);

    end
    %% Computing area
    fprintf('\nComputing volumes:\n')
    tic;
    masksComputed = zeros(size(idxMaskToCompute,2), size(image,1), size(image,2));
    count = 1;
    for idx = idxMaskToCompute
        masksComputed(count,:,:) = masksActivated(idx,:,:);
        count = count+ 1;
    end    
    [volTotalEstimated, arrayVolEstimated] = computeVolumeFromMasks(masksComputed,...
                                                                    distanceBetweenLayer,...
                                                                    ratioPixelMeter);
     fprintf('\t Estimated computed: %.2f mm3 \n', volTotalEstimated*1e9);
     masks = abs(1 -masks);
     [volMasks, ~] = computeVolumeFromMasks(masks,...
                                                                    distanceBetweenLayer,...
                                                                    ratioPixelMeter);
      fprintf('\t Vol mask passed to the algorithm computed: %.2f mm3 \n', volMasks*1e9);

    toc;
    %% Saving images
    if (save_option==true || save_option == 1)
        fprintf('\nSaving images:\n')
        tic;
        if (sum(abs(diff(steps_vector))))==0
            aux_step = strcat("mask_algo_step_",num2str(steps_vector(1)));
        else
            aux_step = "mask_algo_step_variavel";
        end  
        aux_lay = strcat("_",stringTumorLayer,"_",num2str(IDX_LAYER));
        name_exp = strcat(aux_step,...
                                aux_lay,...
                                "_option_",optionClosedFunction,...
                                "filter_", type_filter);
        mask_algo_filename = createMaskFilename(images_filename, name_exp);
        for idx=1:size(masksActivated,1)
            img = squeeze(masksActivated(idx,:,:));
            i_filename = mask_algo_filename(idx,:);
            imwrite(img,fullfile(root,i_filename));
        end
        toc;
    else
        fprintf('\nUser-choice: NOT save images!\n')
    end
   
    
end