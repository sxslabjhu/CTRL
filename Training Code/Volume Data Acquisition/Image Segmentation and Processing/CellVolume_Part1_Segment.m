clear all;
clc;
close all;

DataOutput = CellVolume_SegmentationFunc('experiment_name','experiment_date');
save('DataOutput','DataOutput');