vim.cmd.colorscheme 'catppuccin-mocha'

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

vim.o.cursorline = true
vim.o.foldcolumn = '1'
vim.o.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
vim.o.foldlevel = 99
vim.o.foldmethod = 'expr'
vim.o.foldtext = ''
vim.o.list = true
vim.o.number = true
vim.o.scrolloff = 10
vim.o.signcolumn = 'yes'
vim.o.statusline = '%!v:lua.StatusLine()'
vim.o.swapfile = false
vim.o.winborder = 'rounded'

-- prevent the built-in vim.lsp.completion autotrigger from selecting the first item
vim.opt.completeopt = { "menuone", "noselect", "popup" }

-- The "virtual_text" handler is disabled by default. Enable with
vim.diagnostic.config({ virtual_text = true })

vim.lsp.enable('clangd')

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client:supports_method('textDocument/completion') then
      vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
      vim.keymap.set("i", "<C-space>", vim.lsp.completion.get, { desc = "trigger autocompletion" })
    end
    if client:supports_method('textDocument/foldingRange') then
      local win = vim.api.nvim_get_current_win()
      vim.wo[win][0].foldexpr = 'v:lua.vim.lsp.foldexpr()'
    end
    if client:supports_method('textDocument/documentSymbols') then
      require('nvim-navic').attach(client, ev.buf)
    end
  end,
})

require('telescope').setup({ defaults = { layout_strategy = 'vertical' } })
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope find files' })
vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' })
vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })
vim.keymap.set('n', '<leader>fr', builtin.resume, { desc = 'Telescope resume' })
vim.keymap.set('n', '<leader>fs', builtin.grep_string, { desc = 'Telescope grep string' })

local gitsigns = require('gitsigns')
gitsigns.setup({
  on_attach = function()
    vim.keymap.set('n', ']c', function() if vim.wo.diff then vim.cmd.normal({']c', bang = true}) else gitsigns.nav_hunk('next') end end)
    vim.keymap.set('n', '[c', function() if vim.wo.diff then vim.cmd.normal({'[c', bang = true}) else gitsigns.nav_hunk('prev') end end)
  end
})

-- [[ Set up keymaps ]] See `:h vim.keymap.set()`, `:h mapping`, `:h keycodes`

-- Use <Esc> to exit terminal mode
vim.keymap.set('t', '<Esc>', '<C-\\><C-n>')

-- Grep for string under cursor
vim.keymap.set('n', '<leader>gr', ':grep <C-r><C-w>')

-- statusline
function StatusLine()
  local location = require('nvim-navic').get_location()
  if location ~= '' then location = ' > ' .. location end
  return '%<%f%( %h%w%m%r%)' .. location .. '%= %{&filetype} %{&fileencoding} %{&fileformat} · %-14.(%l,%c%V%) %P'
end

-- vim: expandtab softtabstop=2 shiftwidth=2 tabstop=2
