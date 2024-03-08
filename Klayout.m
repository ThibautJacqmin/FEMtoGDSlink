classdef Klayout < handle
    properties
        pya
    end
    methods
        function obj = Klayout
            % Import python module lygadgets (layer on to of klayout)
            mod = py.importlib.import_module('lygadgets');
            obj.pya = mod.pya;
        end
    end
end
