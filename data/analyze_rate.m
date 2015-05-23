fn = files('rate*mat');
conditions = [31:60; 61:90; 1:30];



for i = 1:length(fn)
    
    load(fn{i});
    for r = 1:2
        
        cseek = Seeker(Seeker(:,2)==r,:);
        
        for c = 1:3
            
            ccseek = cseek(ismember(cseek(:,1),conditions(c,:)),:);
            data{r}(i,c) = nanmean(ccseek(:,3));
            if r==1
                cccseek = ccseek; 
                cccseek(:,3) = abs(cccseek(:,3)-5);
            int(i,c) = nanmean(cccseek(:,3));
            end
            
        end
    end
end
            
    
    
