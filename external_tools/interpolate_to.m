function source = interpolate_to(source, n_points)
    if n_points && ~isempty(source)
        was_mat = false;
        if ~iscell(source)
            source = {source};
            was_mat = true;
        end
        for el = 1:numel(source)
            if size(source{el}, 2) < size(source{el}, 1)
                source{el} = source{el}';
            end
            if size(source{el}, 1) == 1
                source{el} = interp1(1:size(source{el}, 2),   source{el}',   linspace(1,size(source{el},2),n_points));
            else
                source{el} = interp1(1:size(source{el}, 2),   source{el}',   linspace(1,size(source{el},2),n_points))';
            end
        end 
        
        if was_mat
            source = cell2mat(source);
        end
    end
end