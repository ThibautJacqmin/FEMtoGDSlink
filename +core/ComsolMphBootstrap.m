classdef ComsolMphBootstrap
    % Bootstrap helper for COMSOL access through the Python MPh package.
    methods (Static)
        function mph_mod = ensure_ready(args)
            % Ensure Python and installed MPh are available.
            arguments
                args.strict_installed logical = true
            end

            try
                pe = pyenv();
            catch ex
                error("ComsolMphBootstrap:PyenvUnavailable", ...
                    "MATLAB Python bridge is unavailable: %s", ex.message);
            end

            if pe.Status == "NotLoaded"
                % Trigger Python startup early for clear error reporting.
                py.list();
            end

            try
                mph_mod = py.importlib.import_module('mph');
            catch ex
                error("ComsolMphBootstrap:MphImportFailed", ...
                    "Could not import Python package 'mph'. Install it in pyenv interpreter (%s): %s", ...
                    pe.Executable, ex.message);
            end

            if args.strict_installed
                module_file = string(char(py.getattr(mph_mod, "__file__")));
                local_repo = string(fullfile(pwd, "MPh"));
                if startsWith(lower(module_file), lower(local_repo))
                    error("ComsolMphBootstrap:LocalMphForbidden", ...
                        "Loaded local repo copy (%s). Install/use official Python package 'mph' instead.", ...
                        char(module_file));
                end
            end
        end
    end
end
