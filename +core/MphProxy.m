classdef MphProxy < handle
    % Lightweight MATLAB wrapper over Python/JPype COMSOL objects.
    properties (SetAccess=private)
        py_obj
    end
    properties (Dependent)
        geom
        param
        component
        variable
        study
        hist
        mesh
        physics
        material
        result
        sol
        func
    end

    methods
        function obj = MphProxy(py_obj)
            obj.py_obj = py_obj;
        end

        function out = get.geom(obj), out = obj.call('geom'); end
        function out = get.param(obj), out = obj.call('param'); end
        function out = get.component(obj), out = obj.call('component'); end
        function out = get.variable(obj), out = obj.call('variable'); end
        function out = get.study(obj), out = obj.call('study'); end
        function out = get.hist(obj), out = obj.call('hist'); end
        function out = get.mesh(obj), out = obj.call('mesh'); end
        function out = get.physics(obj), out = obj.call('physics'); end
        function out = get.material(obj), out = obj.call('material'); end
        function out = get.result(obj), out = obj.call('result'); end
        function out = get.sol(obj), out = obj.call('sol'); end
        function out = get.func(obj), out = obj.call('func'); end

        function out = create(obj, varargin), out = obj.call('create', varargin{:}); end
        function out = set(obj, varargin), out = obj.call('set', varargin{:}); end
        function out = getv(obj, varargin), out = obj.call('get', varargin{:}); end
        function out = run(obj, varargin), out = obj.call('run', varargin{:}); end
        function out = runPre(obj, varargin), out = obj.call('runPre', varargin{:}); end
        function out = selection(obj, varargin), out = obj.call('selection', varargin{:}); end
        function out = feature(obj, varargin), out = obj.call('feature', varargin{:}); end
        function out = propertyGroup(obj, varargin), out = obj.call('propertyGroup', varargin{:}); end
        function out = label(obj, varargin), out = obj.call('label', varargin{:}); end
        function out = lengthUnit(obj, varargin), out = obj.call('lengthUnit', varargin{:}); end
        function out = modelPath(obj, varargin), out = obj.call('modelPath', varargin{:}); end
        function out = clear(obj, varargin), out = obj.call('clear', varargin{:}); end
        function out = remove(obj, varargin), out = obj.call('remove', varargin{:}); end
        function out = tags(obj, varargin), out = obj.call('tags', varargin{:}); end
        function out = varnames(obj, varargin), out = obj.call('varnames', varargin{:}); end
        function out = save(obj, varargin), out = obj.call('save', varargin{:}); end
        function out = disable(obj, varargin), out = obj.call('disable', varargin{:}); end
        function out = getNBoundaries(obj, varargin), out = obj.call('getNBoundaries', varargin{:}); end
        function out = name(obj, varargin), out = obj.call('name', varargin{:}); end
        function out = loadPreferences(obj, varargin), out = obj.call('loadPreferences', varargin{:}); end
        function out = setPreference(obj, varargin), out = obj.call('setPreference', varargin{:}); end
        function out = uniquetag(obj, varargin), out = obj.call('uniquetag', varargin{:}); end
        function out = createUnique(obj, varargin), out = obj.call('createUnique', varargin{:}); end

        function out = call(obj, method_name, varargin)
            % Invoke a method on wrapped Python object and wrap returned handles.
            out_raw = obj.call_raw(method_name, varargin{:});
            out = core.MphProxy.wrap_out(out_raw);
        end

        function out = call_raw(obj, method_name, varargin)
            fn = py.getattr(obj.py_obj, char(string(method_name)));
            args = cell(1, numel(varargin));
            for i = 1:numel(varargin)
                args{i} = core.MphProxy.to_py(varargin{i});
            end
            out = fn(args{:});
        end
    end

    methods (Static)
        function py_val = unwrap(val)
            if isa(val, 'core.MphProxy')
                py_val = val.py_obj;
            else
                py_val = val;
            end
        end
    end

    methods (Static, Access=private)
        function out = wrap_out(v)
            if isempty(v)
                out = v;
                return;
            end
            if ~isobject(v)
                out = v;
                return;
            end

            try
                cls = string(class(v));
            catch
                % Some JPype-backed Java proxies expose class names MATLAB
                % cannot resolve as MATLAB classes. Treat them as opaque
                % Python objects and keep proxy wrapping enabled.
                out = core.MphProxy(v);
                return;
            end
            if startsWith(cls, "py.")
                raw_classes = [ ...
                    "py.NoneType", "py.str", "py.int", "py.float", ...
                    "py.bool", "py.list", "py.tuple", "py.dict" ...
                ];
                if any(cls == raw_classes)
                    out = v;
                else
                    out = core.MphProxy(v);
                end
                return;
            end

            out = v;
        end

        function py_v = to_py(v)
            if isa(v, 'core.MphProxy')
                py_v = v.py_obj;
                return;
            end
            if isstring(v)
                if isscalar(v)
                    py_v = char(v);
                else
                    py_v = py.list(cellstr(v(:).'));
                end
                return;
            end
            if ischar(v)
                py_v = v;
                return;
            end
            if islogical(v)
                if isscalar(v)
                    py_v = py.bool(v);
                else
                    cells = arrayfun(@(x) py.bool(x), v(:).', 'UniformOutput', false);
                    py_v = py.list(cells);
                end
                return;
            end
            if isnumeric(v)
                if isscalar(v)
                    py_v = v;
                    return;
                end
                if isvector(v)
                    cells = arrayfun(@(x) x, v(:).', 'UniformOutput', false);
                    py_v = py.list(cells);
                else
                    rows = cell(size(v, 1), 1);
                    for r = 1:size(v, 1)
                        rows{r} = core.MphProxy.to_py(v(r, :));
                    end
                    py_v = py.list(rows);
                end
                return;
            end
            if iscell(v)
                items = cell(1, numel(v));
                for i = 1:numel(v)
                    items{i} = core.MphProxy.to_py(v{i});
                end
                py_v = py.list(items);
                return;
            end
            py_v = v;
        end
    end
end
