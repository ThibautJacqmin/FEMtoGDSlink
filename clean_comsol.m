function clean_comsol
clear
removed = femtogds.core.ComsolModeler.clear_generated_models();  % removes old Model_* leftovers
femtogds.core.GeometrySession.clear_shared_comsol
if removed
    disp('Comsol model cleaned');
end
end

