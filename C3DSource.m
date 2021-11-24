classdef C3DSource < Source
    methods
        function c3d = readsource(obj, varargin)
            p = inputParser;
            addRequired(p, 'obj', @(x) isa(x, 'C3DSource'));
            addParameter(p, 'Start', -Inf);
            addParameter(p, 'Finish', Inf);
            addParameter(p, 'ForceLocation', 1);

            parse(p, obj, varargin{:});
            start = p.Results.Start;
            finish = p.Results.Finish;
            forceLoc = p.Results.ForceLocation;

            c3d = osimC3D(obj.path, forceLoc);
        end
    end
end


