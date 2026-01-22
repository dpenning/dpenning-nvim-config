local M = {}

function M.switch_source_header()
  local params = { uri = vim.uri_from_bufnr(0) }
  vim.lsp.buf_request(0, 'textDocument/switchSourceHeader', params, function(err, result)
    if err then
      vim.notify('Error switching source/header: ' .. tostring(err), vim.log.levels.ERROR)
      return
    end
    if result then
      vim.api.nvim_command('edit ' .. vim.uri_to_fname(result))
    else
      vim.notify('No corresponding file found', vim.log.levels.INFO)
    end
  end)
end

vim.api.nvim_create_user_command('SwitchSourceHeader', M.switch_source_header, {})

return M
