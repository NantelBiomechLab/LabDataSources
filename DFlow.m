classdef DFlow < Source
    methods
        function ext = srcext(obj)
            ext = srcext@Source(obj);
            if isempty(ext)
                ext = '.txt';
            end
        end

        function T = readsource(obj, varargin)
            p = inputParser;
            addRequired(p, 'obj', @(x) isa(x, 'Source'));
            addParameter(p, 'Start', -Inf);
            addParameter(p, 'Finish', Inf);

            parse(p, obj, varargin{:});
            start = p.Results.Start;
            finish = p.Results.Finish;

            fobj = fopen(obj.path);
            fgetl(fobj);
            fgetl(fobj);
            fgetl(fobj);
            fgetl(fobj);
            fgetl(fobj);
            fgetl(fobj);
            vars = split(fgetl(fobj), sprintf('\t'));
            vars = vars(1:end-1);
            T = readtable(obj.path, 'FileType', 'text');
            T(:,end) = [];

            % evs = table2struct(T, 'ToScalar', true);
            % evs = structfun(@(x) x(~isnan(x)), evs, 'UniformOutput', false);

            % if finish ~= Inf
            %     evs = structfun(@(x) x(x <= finish), evs, 'UniformOutput', false);
            % end

            % if start ~= -Inf
            %     evs = structfun(@(x) x(x >= start) - start, evs, 'UniformOutput', false);
            % end
        end
    end
end

