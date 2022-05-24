classdef OSimSTO < Source
    methods
        function name = srcname_default(obj)
            name = 'sto';
        end

        function ext = srcext(obj)
            ext = srcext@Source(obj);
            if isempty(ext)
                ext = '.sto';
            end
        end

        function deps = dependencies(obj)
            deps = {OSimModel(), OSimMotion()};
        end

        function data = readsource(obj, varargin)
            import org.opensim.modeling.*
            if endsWith(obj.path, 'OutputsVec3.sto')
                data = TimeSeriesTableVec3(obj.path);
            else
                data = TimeSeriesTableVec3(obj.path);
            end
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
            state = model.initSystem();

            motsrc = deps(cellfun(@(x) isa(x, 'OSimMotion'), deps));
            mot = getsource(trial, motsrc{1});

            if isempty(setupfile)
                atool = AnalyzeTool();
            else
                atool = AnalyzeTool(setupfile, false);
            end

            atool.setModel(model);
            atool.setModelFilename(model.getInputFileName())
            atool.setName(trial.name);
            atool.setCoordinatesFileName(mot.path);
            atool.setInitialTime(starttime);
            atool.setFinalTime(finishtime);
            atool.setResultsDir(objdir);
            
            xmlfn = [tempname '.xml'];
            atool.print(xmlfn);
            
            status = system(['opensim-cmd --log error run-tool ' xmlfn]);
            assert(status == 0)

            src = obj;
        end
    end
end
