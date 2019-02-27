function [ Svect ] = movmeanch( vect,num )
%MOVINGMEAN Summary of this function goes here
%   Detailed explanation goes here

%num must be odd

Svect = nan*vect;

L = length(vect);
bound = (num-1)/2;
for i = 1:bound; %#ok<*NOSEL>
    Svect(i) = nanmean(vect(1:i+bound));
end

for i = bound+1:L-bound;
    Svect(i) = nanmean(vect(i-bound:i+bound));
end

for i = L-bound+1:L;
    Svect(i) = nanmean(vect(i-bound:end));
end

