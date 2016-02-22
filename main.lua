require 'torch'
require 'gnuplot'
local data_loader = require 'datasets/loader'
-- local loader = data_loader.import_data()
-- loader:save_data()

local opt={
  batches=100,
  iterations=1000,
  save_every=100,
  savefile='model_autosave'
  loadfile='model_autosave'
}
local loader = data_loader:load_data()
local input_batch,target_batch=loader:getBatchData(100)
-- print(#input_batch)
-- print(#target_batch)
-- gnuplot.plot(input_batch[{10,1,{},1}])
local model,criterion = require('models/create_model')()
local params, grad_params = model:getParameters()

function feval()
  ------------------ get minibatch -------------------
  local input,target = loader:getBatchData(opt.batches)
  --ff
  local output = model:forward(input)
  local loss = criterion:forward(model.output, target)
  model:zeroGradParameters()
  --bp
  criterion:backward(model.output, target)
  model:backward(input, criterion.gradInput)
  return loss, grad_params
end

--[
-- optimization stuff
local losses = {}
-- local optim_state = {learningRate = 1e-1}
local optim_state = {learningRate=1e-4,momentum=0.9,weightDecay=0}
local time = 0
for i = 1, opt.iterations do
    -- local _, loss = optim.adagrad(feval, params, optim_state)
    local timer = torch.Timer()
    local _, loss = optim.sgd(feval, params, optim_state)
    losses[#losses + 1] = loss[1]
    time = time + timer:time().real
    if i % opt.save_every == 0 then
        torch.save(opt.savefile, {model,criterion})
        print(string.format("iteration %4d, loss = %6.8f,gradnorm = %6.4e, time = %6.4f", i, loss[1],grad_params:norm(),time))
        time=0
    end
end

--]]
