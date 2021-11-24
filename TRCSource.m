classdef TRCSource < Source
    methods
        function mkrs = readsource(obj, varargin)
            p = inputParser;
            addRequired(p, 'obj', @(x) isa(x, 'Source'));
            addParameter(p, 'Markers', {});
            addParameter(p, 'Start', -Inf);
            addParameter(p, 'Finish', Inf);

            parse(p, obj, varargin{:});
            start = p.Results.Start;
            finish = p.Results.Finish;
            mkrlabels = p.Results.Markers;

            trc = TimeSeriesTableVec3(obj.path);

            fs = str2double(trc.getTableMetaDataAsString('DataRate'));
            lastTime = str2double(trc.getTableMetaDataAsString('NumFrames'))/fs;

            if start > -Inf && start < 0
                error('time begins from zero; try a different start time')
            end
            if finish > lastTime
                error('trial is shorter than requested finish time')
            end

            if start ~= -Inf
                trc.trimFrom(start);
            end
            if finish ~= Inf
                trc.trimTo(finish);
            end

            rm_mkrs = setdiff(trc.getColumnLabels(), mkrlabels);
            for i = 1:length(rm_mkrs)
                trc.removeColumn(rm_mkrs(i));
            end

            mkrs = osimTableToStruct(trc);
        end

        function src = generatesource(obj, trial, deps, varargin)
            p = inputParser;
            p.KeepUnmatched = true;
            addRequired(p, 'obj', @(x) isa(x, 'Source'));
            addRequired(p, 'trial', @(x) isa(x, 'Trial'));
            addOptional(p, 'deps', false);

            parse(p, obj, trial, deps, varargin{:});

            c3dsrc = getsource(trial, C3DSource);
            c3d = osimC3D(c3dsrc.path, 1);

            %TODO: Figure out if filtering using the osim functionality is possible
            mkrs = c3d.getTable_markers();
            TRCFileAdaptor().write(mkrs, obj.path);

            src = obj;
        end
    end
end