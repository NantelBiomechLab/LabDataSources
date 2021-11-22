classdef Visual3DExport < Source
    methods
        function [fs, evs, series] = readsource(obj, varargin)
            p = inputParser;
            addRequired(p, 'obj', @(x) isa(x, 'Source'));
            addParameter(p, 'Events', {});
            addParameter(p, 'Timeseries', {});
            addParameter(p, 'Start', -Inf);
            addParameter(p, 'Finish', Inf);

            parse(p, obj, varargin{:});
            start = p.Results.Start;
            finish = p.Results.Finish;
            loadevs = p.Results.Events;
            tseries = p.Results.Timeseries;

            if (start ~= -Inf || finish ~= Inf) && any(startsWith(tseries, 'FP'))
                error('time trimming only works with the marker frame rate. try reading FP data separately without ''Start'' or ''Finish'' specified')
            end

            tmpfs = load(obj.path, 'FRAME_RATE');
            fs = tmpfs.FRAME_RATE{1};
            if start > -Inf && start < 0
                error('time begins from zero; try a different start time')
            end
            series = load(obj.path, tseries{:});
            if finish > totime(size(series.(tseries{1}){1}, 1), fs)
                error('trial is shorter than requested finish time')
            end
            evs = load(obj.path, loadevs{:});

            for eventi = 1:length(loadevs)
                evs.(loadevs{eventi}) = evs.(loadevs{eventi}){1};
            end

            for seriesi = 1:length(tseries)
                series.(tseries{seriesi}) = series.(tseries{seriesi}){1};
            end

            if finish ~= Inf
                evs = structfun(@(x) x(x <= finish), evs, 'UniformOutput', false);
                fin = toindices(finish, fs);
                series = structfun(@(x) x(1:fin), series, 'UniformOutput', false);
            end

            if start ~= -Inf
                evs = structfun(@(x) x(x >= start) - start, evs, 'UniformOutput', false);
                starti = toindices(start, fs);
                series = structfun(@(x) x(starti:end), series, 'UniformOutput', false);
            end
        end
    end
end

function t = toindices(time, fs)
    t = round(time * fs) + 1;
end

function t = totime(indices, fs)
    t = (indices - 1)/fs;
end
