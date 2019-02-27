classdef CTRLRegressionLayer < nnet.layer.RegressionLayer
    methods
        function layer = CTRLRegressionLayer(name)
            layer.Name = name ;
            layer.Description = 'Regression Layer of CTRL Containing Customized Volume Loss Function' ;
        end
        
        function loss = forwardLoss (layer,Y,T)
           loss = sum(abs(sum(sum((Y - T),1),2)) / 512 / 512,4) / 5 ; % Volume Loss Function; 512: pixel size
        end
        
        function dLdY = backwardLoss (layer,Y,T)
           dLdY = sign(Y - T) / (1 * 5) / 512 / 512; % 1: rgb channel number; 5: mini batch size
        end
    end
end