
-- lsp integration for clangd

return {
  {
    'neovim/nvim-lspconfig',
    dependencies = { 'hrsh7th/cmp-nvim-lsp' }, -- Example dependency for completion
    config = function()
      -- Setup clangd
      -- Enable the language server.
      -- To customize, use vim.lsp.config('clangd', { ... }) before enabling.
      vim.lsp.enable('clangd')

      -- Basic Zig language server support via zls
      vim.lsp.enable('zls')

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
