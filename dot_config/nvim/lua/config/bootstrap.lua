local M = {}

function M.wait_for_installs()
  local ok, registry = pcall(require, "mason-registry")
  if not ok then
    return
  end

  local refreshed = false
  registry.refresh(function()
    refreshed = true
  end)

  if not vim.wait(60000, function()
    return refreshed
  end, 200) then
    error("Timed out while refreshing the Mason registry")
  end

  if not vim.wait(300000, function()
    for _, package in ipairs(registry.get_all_packages()) do
      if package:is_installing() then
        return false
      end
    end
    return true
  end, 250) then
    error("Timed out while installing Mason packages")
  end

  -- Allow asynchronous Tree-sitter parser builds to finish before headless exit.
  vim.wait(5000)
end

return M
