classdef OSimModel < Source
    methods
        function name = srcname_default(obj)
            name = 'model';
        end

        function ext = srcext(obj)
            ext = '.osim';
        end
    end
end
