vim.pack.add({
  'https://github.com/SmiteshP/nvim-navic',
  'https://github.com/lewis6991/gitsigns.nvim',
  'https://github.com/neovim/nvim-lspconfig',
  'https://github.com/nvim-lua/plenary.nvim',
  'https://github.com/nvim-telescope/telescope.nvim',
  'https://github.com/nvim-treesitter/nvim-treesitter',
  'https://tpope.io/vim/fugitive',
  { src = 'https://codeberg.org/lifepillar/vim-solarized8', version = 'neovim' },
})

vim.cmd('colorscheme solarized8_high')

-- Set <space> as the leader key
-- See `:help mapleader`
-- NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = ' '

-- [[ Setting options ]] See `:h vim.o`
-- NOTE: You can change these options as you wish!
-- For more options, you can see `:help option-list`
-- To see documentation for an option, you can use `:h 'optionname'`, for example `:h 'number'`
-- (Note the single quotes)

-- Print the line number in front of each line
vim.o.number = true

-- Sync clipboard between OS and Neovim. Schedule the setting after `UiEnter` because it can
-- increase startup-time. Remove this option if you want your OS clipboard to remain independent.
-- See `:help 'clipboard'`
vim.api.nvim_create_autocmd('UIEnter', {
  callback = function()
    vim.o.clipboard = 'unnamedplus'
  end,
})

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
-- vim.o.ignorecase = true
-- vim.o.smartcase = true

-- Highlight the line where the cursor is on
vim.o.cursorline = true

-- Apply theme colors to the terminal's cursor
vim.o.guicursor = 'n-v-c-sm:block-Cursor,i-ci-ve:ver25-Cursor,r-cr-o:hor20-Cursor'

-- Minimal number of screen lines to keep above and below the cursor.
vim.o.scrolloff = 10

-- Show <tab> and trailing spaces
vim.o.list = true
vim.o.listchars = 'tab:» ,trail:·,nbsp:+,lead:·'

-- if performing an operation that would fail due to unsaved changes in the buffer (like `:q`),
-- instead raise a dialog asking if you wish to save the current file(s) See `:help 'confirm'`
vim.o.confirm = true

-- vim.o.foldcolumn = '1'
-- vim.o.foldlevel = 99
-- vim.o.foldmethod = 'indent'
-- vim.o.foldtext = ''

-- vim.o.jumpoptions = 'view'

vim.o.signcolumn = 'yes'
vim.o.statusline = '%!v:lua.StatusLine()'
vim.o.swapfile = false

-- prevent the built-in vim.lsp.completion autotrigger from selecting the first item
vim.opt.completeopt = { "menu", "popup", "longest" } -- += longest

-- prevent colorscheme from setting bg color
-- vim.cmd(':highlight Normal guibg=NONE guifg=NONE ctermbg=NONE ctermfg=NONE')

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
      vim.wo.foldexpr = 'v:lua.vim.lsp.foldexpr()'
    end
  end,
})

require('nvim-navic').setup({ lsp = { auto_attach = true } })

require('telescope').setup({
  defaults = { layout_strategy = 'vertical' },
  pickers = { 
    colorscheme = {
      enable_preview = true,
      previewer = false,
      theme = 'dropdown'
    }
  }
})
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
vim.keymap.set('n', '<leader>cs', builtin.colorscheme, { desc = 'Telescope colorscehemes' })
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

-- Map <A-j>, <A-k>, <A-h>, <A-l> to navigate between windows in any modes
vim.keymap.set({ 't', 'i' }, '<A-h>', '<C-\\><C-n><C-w>h')
vim.keymap.set({ 't', 'i' }, '<A-j>', '<C-\\><C-n><C-w>j')
vim.keymap.set({ 't', 'i' }, '<A-k>', '<C-\\><C-n><C-w>k')
vim.keymap.set({ 't', 'i' }, '<A-l>', '<C-\\><C-n><C-w>l')
vim.keymap.set({ 'n' }, '<A-h>', '<C-w>h')
vim.keymap.set({ 'n' }, '<A-j>', '<C-w>j')
vim.keymap.set({ 'n' }, '<A-k>', '<C-w>k')
vim.keymap.set({ 'n' }, '<A-l>', '<C-w>l')

-- Grep for string under cursor
vim.keymap.set('n', '<leader>gr', ':grep <C-r><C-w>')

-- [[ Basic Autocommands ]].
-- See `:h lua-guide-autocommands`, `:h autocmd`, `:h nvim_create_autocmd()`

-- Highlight when yanking (copying) text.
-- Try it with `yap` in normal mode. See `:h vim.hl.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  callback = function()
    vim.hl.on_yank()
  end,
})

-- [[ Create user commands ]]
-- See `:h nvim_create_user_command()` and `:h user-commands`

-- Create a command `:GitBlameLine` that print the git blame for the current line
-- vim.api.nvim_create_user_command('GitBlameLine', function()
--   local line_number = vim.fn.line('.') -- Get the current line number. See `:h line()`
--   local filename = vim.api.nvim_buf_get_name(0)
--   print(vim.fn.system({ 'git', 'blame', '-L', line_number .. ',+1', filename }))
-- end, { desc = 'Print the git blame for the current line' })

-- [[ Add optional packages ]]
-- Nvim comes bundled with a set of packages that are not enabled by
-- default. You can enable any of them by using the `:packadd` command.

-- For example, to add the "nohlsearch" package to automatically turn off search highlighting after
-- 'updatetime' and when going to insert mode
vim.cmd('packadd! nohlsearch')

-- The "cfilter" package allows filtering the quickfix list using :Cfilter and :Lfilter
vim.cmd('packadd! cfilter')

-- statusline
function StatusLine()
  local location = require('nvim-navic').get_location()
  if location ~= '' then location = ' > ' .. location end
  return '%<%f%( %h%w%m%r%)' .. location .. '%= %{&filetype} %{&fileencoding} %{&fileformat} · %-14.(%l,%c%V%) %P'
end

-- vim: expandtab softtabstop=2 shiftwidth=2 tabstop=2
