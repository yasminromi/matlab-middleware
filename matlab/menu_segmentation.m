% User friendly interface to the program of segmentation


% Author: Renata Porciuncula Baptista
% r.baptista@poli.ufrj.br
% 03/11/2019

app = segmentationInterface(0);

while app.done == 0
 pause(0.05)
end
%%
a = getParameters(app);
app.delete;


%%
[masksActivated, volEstimated, volMasks] = segmentationUSImagesIG(a.closedOption, ...
                                        a.ratioPixelM, a.distanceBetweenLayers,...
                                        char(a.images), a.imagesFolder,...
                                        char(a.masks), a.masksFolder,...
                                        a.filter,...
                                        2,...
                                        a.tumor,...
                                        a.flagsave,...
                                        a.idx_layer_tumor,...
                                        a.outputPath);
                                    