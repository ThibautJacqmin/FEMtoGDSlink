classdef Klayout < handle
    properties
        pya
    end
    methods
        function obj = Klayout
            % Load KLayout Python bindings, preferring direct modules.
            obj.pya = core.Klayout.import_pya();
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

            error("KLayout Python bindings not found. A valid pya handle is expected.");
        end
    end
end
