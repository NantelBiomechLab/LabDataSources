classdef Visual3DEvents < Source
    methods
        function evs = readsource(obj, varargin)
            p = inputParser;
            addRequired(p, 'obj', @(x) isa(x, 'Source'));
            addParameter(p, 'Start', -Inf);
            addParameter(p, 'Finish', Inf);

            parse(p, obj, varargin{:});
            start = p.Results.Start;
            finish = p.Results.Finish;

            fobj = fopen(obj.path);
            fgetl(fobj);
            vars = split(fgetl(fobj));
            T = readtable(obj.path, 'FileType', 'text', 'ReadVariableNames', false, 'HeaderLines', 5);
            T(:,1) = [];
            T.Properties.VariableNames = vars(2:end);

            evs = table2struct(T, 'ToScalar', true);
            evs = structfun(@(x) x(~isnan(x)), evs, 'UniformOutput', false);

            if finish ~= Inf
                evs = structfun(@(x) x(x <= finish), evs, 'UniformOutput', false);
            end

            if start ~= -Inf
                evs = structfun(@(x) x(x >= start) - start, evs, 'UniformOutput', false);
            end
        end

        function src = generatesource(obj, trial, deps, varargin)
            p = inputParser;
            p.KeepUnmatched = true;
            addRequired(p, 'obj', @(x) isa(x, 'Source'));
            addRequired(p, 'trial', @(x) isa(x, 'Trial'));
            addOptional(p, 'deps', false);
            addParameter(p, 'EventsGenerator', @dummy);

            parse(p, obj, trial, deps, varargin{:});
            genfunc = p.Results.EventsGenerator;

            if isequal(genfunc, @dummy)
                error('''EventsGenerator'' is a required argument')
            end

            dirname = fileparts(obj.path);
            [~,~,~] = mkdir(dirname);

            evs = genfunc(trial, p.Unmatched);
            writeeventsfile(obj.path, evs);

            src = obj;
        end
    end
end

function writeeventsfile(path, evs)
    header = cell(5,1);
    header{5,1} = 'ITEM';
    maxevs = max(structfun(@length, evs));
    eventdata = cell(maxevs,1);
    eventdata(1:maxevs) = num2cell(1:maxevs);

    [~, name, ~] = fileparts(path);
    file = [name, '.c3d'];

    fields = fieldnames(evs);
    numevs = length(fields);
    for eventi = 1:numevs
        event = fields{eventi};
        header = horzcat(header, { file,
                            event,
                            'EVENT_LABEL',
                            'ORIGINAL',
                            'X' });
        tmp = cell(maxevs, 1);
        tmp(1:length(evs.(event))) = num2cell(evs.(event));
        eventdata = horzcat(eventdata, tmp);
    end

    T = cell2table(vertcat(header, eventdata));
    writetable(T, path, 'Delimiter', '\t', 'FileType', 'text', 'WriteVariableNames', false);
end

function dummy(varargin)
end
