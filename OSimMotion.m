classdef OSimMotion < Source
    methods
        function name = srcname_default(obj)
            name = 'ik';
        end

        function ext = srcext(obj)
            ext = srcext@Source(obj);
            if isempty(ext)
                ext = '.mot';
            end
        end

        function deps = dependencies(obj)
            deps = {OSimModel(), TRCSource()};
        end

        function data = readsource(obj, varargin)
            % data = readtable(obj.path, 'FileType','text', 'ReadVariableNames',true,...
            %     'HeaderLines',10);
            import org.opensim.modeling.*
            data = TimeSeriesTable(obj.path);
        end

        function src = generatesource(obj, trial, deps, varargin)
            p = inputParser;
            addRequired(p, 'obj');
            addRequired(p, 'trial', @(x) isa(x, 'Trial'));
            addRequired(p, 'deps');
            addOptional(p, 'SetupFile', '');
            addOptional(p, 'StartTime', -Inf);
            addOptional(p, 'FinishTime', Inf);

            parse(p, obj, trial, deps, varargin{:});
            setupfile = p.Results.SetupFile;
            starttime = p.Results.StartTime;
            finishtime = p.Results.FinishTime;

            [objdir,~,~] = fileparts(obj.path);
            if ~isdir(objdir)
                mkdir(objdir);
            end

            import org.opensim.modeling.*

            modelsrc = deps(cellfun(@(x) isa(x, 'OSimModel'), deps));
            modelsrc = getsource(trial, modelsrc{1});
            model = Model(modelsrc.path);
            model.initSystem();

            trcsrc = deps(cellfun(@(x) isa(x, 'TRCSource'), deps));
            trc = getsource(trial, trcsrc{1});

            if isempty(setupfile)
                iktool = InverseKinematicsTool();
            else
                iktool = InverseKinematicsTool(setupfile, false);
            end

            iktool.setModel(model);
            iktool.set_model_file(model.getInputFileName())
            iktool.setMarkerDataFileName(trc.path);
            iktool.setStartTime(starttime);
            iktool.setEndTime(finishtime);
            iktool.setOutputMotionFileName(obj.path);

            xmlfn = [tempname '.xml'];
            iktool.print(xmlfn);

            status = system(['opensim-cmd --log error run-tool ' xmlfn]);
            assert(status == 0)

            src = obj;
        end
    end
end
