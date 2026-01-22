
-- lsp integration for clangd

return {
  {
    'neovim/nvim-lspconfig',
    dependencies = { 'hrsh7th/cmp-nvim-lsp' }, -- Example dependency for completion
    config = function()
      local lspconfig = require('lspconfig')

      -- Setup clangd
      lspconfig.clangd.setup{}

      -- Basic Zig language server support via zls
      lspconfig.zls.setup{}

      -- Keymaps for LSP actions (optional, but recommended)
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('UserLspConfig', {}),
        callback = function(ev)
          local opts = { buffer = ev.buf, noremap = true, silent = true }
          vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
          vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
          vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
          vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
          vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
          -- Add other mappings as desired (e.g., for references, rename)
        end,
      })
    end
  }
}
