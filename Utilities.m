classdef Utilities
    methods (Static)
        function pts = bezier_fillet(p0, p1, p2, npoints)
            arguments
                p0 (1, 2) double
                p1 (1, 2) double
                p2 (1, 2) double
                npoints (1, 1) double {mustBeInteger, mustBeGreaterThanOrEqual(npoints, 2)} = 16
            end

            t = linspace(0, 1, npoints).';
            omt = 1 - t;
            pts = (omt.^2) .* p0 + (2 .* omt .* t) .* p1 + (t.^2) .* p2;
        end
    end
end
