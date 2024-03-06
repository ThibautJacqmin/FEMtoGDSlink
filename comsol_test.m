import com.comsol.model.*
import com.comsol.model.util.*

% Creat new model
model = ModelUtil.create('Model');

% Link to model from server
%model = ModelUtil.model('Model');

% Load model from  .mph file
%model = mphopen(<filename>)

% Activate progress bar
ModelUtil.showProgress(true)

% Disable Comsol model history
model.hist.disable

% Launch Comsol Desktop for given model
%mphlaunch(model)