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
            deps = {OSimModel(), TRCFile()};
        end

        function data = readsource(obj)
            % data = readtable(obj.path, 'FileType','text', 'ReadVariableNames',true,...
            %     'HeaderLines',10);
            import org.opensim.modeling.*
            data = TimeSeriesTable(obj.path);
        end

        function src = generatesource(obj, trial, deps, varargin)
            p = inputParser;
            addRequired(p, 'obj', @(x) isa(x, 'OSimMotion'));
            addRequired(p, 'trial', @(x) isa(x, 'Trial'));
            addRequired(p, 'deps');
            addOptional(p, 'IKSetupFile', '');
            addOptional(p, 'StartTime', -Inf);
            addOptional(p, 'FinishTime', Inf);

            parse(p, obj, trial, deps, varargin{:});
            iksetupfile = p.Results.IKSetupFile;
            starttime = p.Results.StartTime;
            finishtime = p.Results.FinishTime;

            [objdir,~,~] = fileparts(obj.path);
            if ~isdir(objdir)
                mkdir(objdir);
            end

            import org.opensim.modeling.*

            modelsrc = deps(cellfun(@(x) isa(x, 'OSimModel'), deps));
            model = Model(getsource(trial, modelsrc{1}));
            model.initSystem();

            trcsrc = deps(cellfun(@(x) isa(x, 'TRCFile'), deps));
            trc = getsource(trial, trcsrc{1});

            if isempty(iksetupfile)
                ikTool = InverseKinematicsTool();
            else
                ikTool = InverseKinematicsTool(iksetupfile);
            end

            ikTool.setModel(model);
            ikTool.setMarkerDataFileName(trc.path);
            ikTool.setStartTime(starttime);
            ikTool.setEndTime(finishtime);
            ikTool.setOutputMotionFileName(obj.path);

            ikTool.run();

            src = obj;
        end
    end
end
