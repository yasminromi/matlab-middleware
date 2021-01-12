package br.com.middleware.matlab;

import java.io.File;
import java.util.ArrayList;
import java.util.concurrent.ExecutionException;

import com.mathworks.engine.MatlabEngine;

import br.com.middleware.matlab.model.SegmentationUSImageID;

public class Main {
	
	private static SegmentationUSImageID model = new SegmentationUSImageID();

	public static void main(String[] args) {
	
		try {
			
			populate(args[0], Double.parseDouble(args[1]), Double.parseDouble(args[2]), args[3], args[4], args[5], args[6], args[7], Boolean.parseBoolean(args[8]), Boolean.parseBoolean(args[9]), args[10]);
			
			callMatlab();
			
		} catch (Exception e) {
			System.out.print("Erro " + e.getMessage());
		}
	}
	
	private static void populate(String function, double pixel, double distance, 
			String imagesPath, String masksPath, String filter, 
			String levelProcessing, String tumorLayer, boolean layerIndex, 
			boolean saveContext, String directoryToSave) {
		
		
		model.setOcf(function);
		model.setRpm(pixel);
		model.setDbl(distance);
		model.setRootImages(imagesPath);
		model.setRootMask(masksPath);
		model.setTypeFilter(filter);
		model.setLevelProcessing(levelProcessing);
		model.setStringTumorLayer(tumorLayer);
		model.setIdxLayer(layerIndex);
		model.setSave(saveContext);
		model.setRoot(directoryToSave);
		
	}
	
	private static void callMatlab()  {
		String path = new File(".").getAbsolutePath();
		final String MATLAB_PATH = (path + "/matlab");
		try {
			MatlabEngine ml = MatlabEngine.startMatlab();
			ml.eval("cd '" + MATLAB_PATH + "'");
			Object[] variables = {
					"hull",
					6E-6,
					2.5E-5,
					getFilesInPath(model.getRootImages()),
					(model.getRootImages().toCharArray()),
					getFilesInPath(model.getRootMask()),
					(model.getRootMask().toCharArray()),
					"None",
					2,
					"Tumor",
					false,
					0,
					(model.getRootImages().toCharArray())
			};

			ml.feval("segmentationUSImagesIG", variables);
		} catch (InterruptedException e) {
			e.printStackTrace();
		} catch (ExecutionException e) {
			e.printStackTrace();
		}
	}
	
	private static char[][] getFilesInPath(String path) {
		ArrayList<char[]> _files = new ArrayList<char[]>();
	
		File folder = new File(path);
		File[] files = folder.listFiles();

		if (files != null) {
			for (File file : files) {
				 if (file != null) {
					 _files.add((file.getName().toCharArray()));
				}
			}
		}

		return _files.toArray(new char[0][0]);
	}

}
