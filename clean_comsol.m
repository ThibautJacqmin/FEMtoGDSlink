function clean_comsol
clear
removed = ComsolModeler.clear_generated_models();  % removes old Model_* leftovers
GeometrySession.clear_shared_comsol
if removed
    disp('Comsol model cleaned');
end
end