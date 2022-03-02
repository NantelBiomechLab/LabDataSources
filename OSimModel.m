classdef OSimModel < Source
    methods
        function name = srcname_default(obj)
            name = 'model';
        end

        function ext = srcext(obj)
            ext = srcext@Source(obj);
            if isempty(ext)
                ext = '.osim';
            end
        end
    end
end
