classdef Klayout < handle
    properties
        pya
    end
    methods
        function obj = Klayout
            % Load KLayout Python bindings, preferring direct modules.
            obj.pya = femtogds.core.Klayout.import_pya();
        end
    end
    methods (Static, Access=private)
        function pya_mod = import_pya()
            % Prefer direct KLayout modules over wrapper packages.
            direct_modules = {"pya", "klayout.db"};
            for i = 1:numel(direct_modules)
                try
                    pya_mod = py.importlib.import_module(direct_modules{i});
                    return;
                catch
                end
            end

            % Backward-compatibility path: lygadgets exposes `.pya`.
            try
                mod = py.importlib.import_module('lygadgets');
                if logical(py.hasattr(mod, 'pya')) && ~isa(mod.pya, 'py.NoneType')
                    pya_mod = mod.pya;
                    return;
                end
            catch
            end

            error("KLayout Python bindings not found. Expected one of: pya, klayout.db, or lygadgets with a valid pya handle.");
        end
    end
end
