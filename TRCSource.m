classdef TRCSource < Source
    methods
        function src = TRCSource(path)
            if nargin == 0
                src.path = [tempname, '.trc'];
            else
                src.path = path;
            end
        end

        function ext = srcext(obj)
            ext = srcext@Source(obj);
            if isempty(ext)
                ext = '.trc';
            end
        end

        function deps = dependencies(obj)
            deps = {C3DSource()};
        end

        function mkrs = readsource(obj, varargin)
            p = inputParser;
            addRequired(p, 'obj', @(x) isa(x, 'TRCSource'));
            addParameter(p, 'Markers', {});
            addParameter(p, 'Start', -Inf);
            addParameter(p, 'Finish', Inf);

            parse(p, obj, varargin{:});
            start = p.Results.Start;
            finish = p.Results.Finish;
            mkrlabels = p.Results.Markers;

            import org.opensim.modeling.*

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
            addRequired(p, 'obj', @(x) isa(x, 'TRCSource'));
            addRequired(p, 'trial', @(x) isa(x, 'Trial'));
            addOptional(p, 'deps', false);
            addOptional(p, 'Filter', false);
            addOptional(p, 'CutoffFrequency', false);

            parse(p, obj, trial, deps, varargin{:});
            filtflag = p.Results.Filter;
            fc = p.Results.CutoffFrequency;
            if filtflag && fc == false
                error('''CutoffFrequency'' must be given if ''Filter'' is set to true')
            end

            import org.opensim.modeling.*

            c3dsrc = getsource(trial, C3DSource);
            c3d = osimC3D(c3dsrc.path, 1);

            mkrs = c3d.getTable_markers();
            if filtflag
                flat_mkrs = flatten(mkrs);
                TableUtilities.filterLowpass(flat_mkrs, fc);
                mkrs = packVec3(flat_mkrs);
            end
            TRCFileAdapter().write(mkrs, obj.path);

            src = obj;
        end
    end
end
