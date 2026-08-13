-- Plug-ins {{{
vim.pack.add({
  'https://github.com/folke/which-key.nvim',
  'https://github.com/kotarac/vim-vinegar',
  'https://github.com/lewis6991/gitsigns.nvim',
  'https://github.com/neovim/nvim-lspconfig',
  'https://github.com/nvim-lua/plenary.nvim',
  'https://github.com/nvim-telescope/telescope.nvim',
  'https://github.com/nvim-treesitter/nvim-treesitter-context',
  'https://tpope.io/vim/fugitive',
})
-- }}}

-- Colorscheme {{{
vim.cmd('colorscheme catppuccin') -- catppuccin was added to vnim 0.12!
vim.cmd('let g:colortemplate_toolbar = 0') -- fixes colortemplate on nvim
vim.cmd('command DarkMode set background=dark|colorscheme catppuccin')
vim.cmd('command LightMode set background=light|colorscheme solarized8_high')
-- }}}

-- Configuration {{{
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
vim.o.relativenumber = true

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
-- vim.o.ignorecase = true
-- vim.o.smartcase = true

-- Apply theme colors to the terminal's cursor
vim.o.guicursor = 'n-v-c-sm:block-Cursor,i-ci-ve:ver25-Cursor,r-cr-o:hor20-Cursor'

-- Show <tab> and trailing spaces
vim.o.list = true
vim.o.listchars = 'tab:» ,trail:·,nbsp:␣,lead:·'

-- if performing an operation that would fail due to unsaved changes in the buffer (like `:q`),
-- instead raise a dialog asking if you wish to save the current file(s) See `:help 'confirm'`
vim.o.confirm = true

-- TODO: learn how to use folding productively
vim.o.foldlevel = 99
vim.o.foldcolumn = '0'
vim.o.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
vim.o.foldmethod = 'expr'
vim.o.foldnestmax = 4
vim.o.foldtext = ''

-- vim.o.jumpoptions = 'view'

vim.o.signcolumn = 'yes'
vim.o.swapfile = false
vim.o.updatetime = 500
vim.o.winborder = 'rounded'

-- Configure how new splits should be opened
vim.o.splitright = true
vim.o.splitbelow = true

-- Stop .mm files being loaded as filetype=nroff if first 20 lines don't contain "include" or "import"
vim.filetype.add({ extension = { mm = 'objcpp' } })

-- }}}

-- Diagnostic Config & Keymaps {{{
--  See `:help vim.diagnostic.Opts`
vim.diagnostic.config {
  update_in_insert = false,
  severity_sort = true,
  float = { border = 'rounded', source = 'if_many' },
  underline = { severity = { min = vim.diagnostic.severity.WARN } },

  -- Can switch between these as you prefer
  virtual_text = true, -- Text shows up at the end of the line
  virtual_lines = false, -- Text shows up underneath the line, with virtual lines

  -- Auto open the float, so you can easily read the errors when jumping with `[d` and `]d`
  jump = {
    on_jump = function(_, bufnr)
      vim.diagnostic.open_float {
        bufnr = bufnr,
        scope = 'cursor',
        focus = false,
      }
    end,
  },
}

vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })
-- }}}

-- Treesitter {{{
-- Arborist installs treesitter queries so that TS syntax higlighting works
-- It also installs new parsers on demand when opening files
vim.pack.add({'https://github.com/arborist-ts/arborist.nvim'})
require("arborist").setup({
  install_popular = false,
  prefer_wasm = false,
  update_cadence = 'manual'
})

require('treesitter-context').setup({
  multiline_threshold = 1, -- Much better for Xfer's coding style
})

-- If not using Arborist, something like this would be needed:
-- vim.api.nvim_create_autocmd('FileType', {
--   callback = function(ev)
--     local language = vim.treesitter.language.get_lang(ev.match)
--     if vim.treesitter.language.add(language) then 
--       -- vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
--       -- vim.wo.foldmethod = 'expr'
--     end
--   end
-- })
-- }}}

-- LSP {{{
-- editsNearCursor = false to prevent completion clobbering "->" for non-trivial pointers
vim.lsp.config('clangd', { capabilities = { textDocument = { completion = { editsNearCursor = false } } } })
vim.lsp.enable('clangd')

-- Allow lua_ls to resolve vim module
vim.lsp.config('lua_ls', { settings = { Lua = { workspace = { library = vim.api.nvim_get_runtime_file("", true) } } } })
vim.lsp.enable('lua_ls')

vim.lsp.config('pylsp', {})
vim.lsp.enable('pylsp')

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client == nil then return end
    if client.server_capabilities.documentHighlightProvider then
      local group = vim.api.nvim_create_augroup('LspHighlighReferences', { clear = true })
      vim.api.nvim_create_autocmd({ 'CursorHold' },
        { buf = ev.buf, group = group, callback = vim.lsp.buf.document_highlight })
      vim.api.nvim_create_autocmd({ 'CursorMoved', 'InsertEnter' },
        { buf = ev.buf, group = group, callback = vim.lsp.buf.clear_references })
    end
    if client.server_capabilities.completionProvider then
      vim.keymap.set('i', '<c-space>', vim.lsp.completion.get)
      vim.keymap.set('i', '<C-]>', vim.lsp.completion.get)
      -- Manual completion, works nicely without noselect
      vim.lsp.completion.enable(true, client.id, ev.buf)
      --
      -- neovim 0.12 autocomplete [ins-autocompletion]
      -- Seems to have some issues with async nature of LSP results; 'autocompletedelay' and
      -- 'autocompletetimeout' don't work, and LSP results appear at bottom of list, and o^5
      -- does not implement the limit of 5 results for example.
      -- It's also quite weird to have autocomplete kick in when writing comments.
      -- vim.bo.autocomplete = true
      -- vim.bo.complete = '.^5,w^5,b^5,u^5,o^5'
      -- vim.bo.completeopt = 'menu,popup,noselect'
      --
      -- LSP-driven auto-completion [lsp-completion]
      -- FIXME: why is this breaking i_CTRL-N e.g. when entering string literals?
      -- local chars = {}; for i = 32, 126 do table.insert(chars, string.char(i)) end
      -- client.server_capabilities.completionProvider.triggerCharacters = chars
      -- vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
      -- vim.bo.completeopt = 'menu,popup,noselect'
    end
    if client.name == 'clangd' then
      vim.keymap.set("n", "gh", "<cmd>LspClangdSwitchSourceHeader<cr>", {
        buffer = ev.buf,
        desc = "Switch source/header",
      })
    end
  end,
})
-- }}}

-- Telescope {{{
require('telescope').setup({
  defaults = { layout_strategy = 'vertical' },
  pickers = {
    colorscheme = {
      enable_preview = true,
      previewer = false,
      theme = 'dropdown'
    },
    lsp_document_symbols = {symbol_width = 50},
    lsp_dynamic_workspace_symbols = {symbol_width = 50},
  }
})
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
vim.keymap.set({ 'n', 'v' }, '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
vim.keymap.set('n', '<leader>sc', builtin.commands, { desc = '[S]earch [C]ommands' })
vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })

-- Add Telescope-based LSP pickers when an LSP attaches to a buffer.
-- If you later switch picker plugins, this is where to update these mappings.
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(event)
    local buf = event.buf

    -- Find references for the word under your cursor.
    vim.keymap.set('n', '<leader>grr', builtin.lsp_references, { buffer = buf, desc = '[G]oto [R]eferences' })

    -- Jump to the implementation of the word under your cursor.
    -- Useful when your language has ways of declaring types without an actual implementation.
    vim.keymap.set('n', '<leader>gri', builtin.lsp_implementations, { buffer = buf, desc = '[G]oto [I]mplementation' })

    -- Jump to the definition of the word under your cursor.
    -- This is where a variable was first declared, or where a function is defined, etc.
    -- To jump back, press <C-t>.
    vim.keymap.set('n', '<leader>grd', builtin.lsp_definitions, { buffer = buf, desc = '[G]oto [D]efinition' })

    -- Fuzzy find all the symbols in your current document.
    -- Symbols are things like variables, functions, types, etc.
    vim.keymap.set('n', 'gO', builtin.lsp_document_symbols, { buffer = buf, desc = 'Open Document Symbols' })

    -- Fuzzy find all the symbols in your current workspace.
    -- Similar to document symbols, except searches over your entire project.
    vim.keymap.set('n', 'gW', builtin.lsp_dynamic_workspace_symbols, { buffer = buf, desc = 'Open Workspace Symbols' })

    -- Jump to the type of the word under your cursor.
    -- Useful when you're not sure what type a variable is and you want to see
    -- the definition of its *type*, not where it was *defined*.
    vim.keymap.set('n', '<leader>grt', builtin.lsp_type_definitions, { buffer = buf, desc = '[G]oto [T]ype Definition' })
  end,
})

-- Override default behavior and theme when searching
vim.keymap.set('n', '<leader>/', function()
  -- You can pass additional configuration to Telescope to change the theme, layout, etc.
  builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
    winblend = 10,
    previewer = false,
  })
end, { desc = '[/] Fuzzily search in current buffer' })

-- It's also possible to pass additional configuration options.
--  See `:help telescope.builtin.live_grep()` for information about particular keys
vim.keymap.set(
  'n',
  '<leader>s/',
  function()
    builtin.live_grep {
      grep_open_files = true,
      prompt_title = 'Live Grep in Open Files',
    }
  end,
  { desc = '[S]earch [/] in Open Files' }
)

-- Shortcut for searching your Neovim configuration files
vim.keymap.set('n', '<leader>sn', function() builtin.find_files { cwd = vim.fn.stdpath 'config' } end, { desc = '[S]earch [N]eovim files' })
-- }}}

-- Gitsigns {{{
local gitsigns = require('gitsigns')
gitsigns.setup({
  on_attach = function()
    vim.keymap.set('n', ']c', function() if vim.wo.diff then vim.cmd.normal({']c', bang = true}) else gitsigns.nav_hunk('next') end end)
    vim.keymap.set('n', '[c', function() if vim.wo.diff then vim.cmd.normal({'[c', bang = true}) else gitsigns.nav_hunk('prev') end end)
  end
})
-- }}}

-- [[ Set up keymaps ]] See `:h vim.keymap.set()`, `:h mapping`, `:h keycodes` {{{

-- Allow entering these keys when using Ghostty with macos-option-as-alt = true
if vim.env.TERM == 'xterm-ghostty' and vim.fn.has('maxunix') then
  vim.keymap.set('i', '<M-2>', '€')
  vim.keymap.set('i', '<M-3>', '#')
end

-- Use <Esc> to exit terminal mode
vim.keymap.set('t', '<Esc>', '<C-\\><C-n>')
vim.keymap.set('t', '<C-[>', '<C-\\><C-n>')

-- TIP: Disable arrow keys in normal mode
vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- From ThePrimeagen
vim.keymap.set('n', '<C-d>', '<C-d>zz')
vim.keymap.set('n', '<C-u>', '<C-u>zz')

-- Copy / paste from system keyboard
vim.keymap.set({ 'n', 'v', 'x' }, '<leader>d', '"+d')
vim.keymap.set({ 'n', 'v', 'x' }, '<leader>y', '"+y')
vim.keymap.set('n', '<leader>Y', '"+Y')
vim.keymap.set('n', '<leader>p', '"+p')

-- Make <Tab> cycle through insert-mode completion items, <CR> always select
-- https://vimtricks.wiki/posts/pumvisible-smart-completion-map
vim.cmd([[
  inoremap <expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
  inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
  inoremap <expr> <CR>    pumvisible() ? "\<C-y>" : "\<CR>"
]])

-- }}}

-- [[ Basic Autocommands ]] {{{
-- See `:h lua-guide-autocommands`, `:h autocmd`, `:h nvim_create_autocmd()`

-- Highlight when yanking (copying) text.
-- Try it with `yap` in normal mode. See `:h vim.hl.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', { callback = function() vim.hl.on_yank() end })

-- show cursorline only in active window
vim.api.nvim_create_autocmd({'WinEnter', 'BufEnter'}, { callback = function() vim.opt_local.cursorline = true end })
vim.api.nvim_create_autocmd({'WinLeave', 'BufLeave'}, { callback = function() vim.opt_local.cursorline = false end })
-- }}}

-- [[ Create user commands ]] {{{
-- See `:h nvim_create_user_command()` and `:h user-commands`

-- Create a command `:GitBlameLine` that print the git blame for the current line
-- vim.api.nvim_create_user_command('GitBlameLine', function()
--   local line_number = vim.fn.line('.') -- Get the current line number. See `:h line()`
--   local filename = vim.api.nvim_buf_get_name(0)
--   print(vim.fn.system({ 'git', 'blame', '-L', line_number .. ',+1', filename }))
-- end, { desc = 'Print the git blame for the current line' })

vim.api.nvim_create_user_command('TransparentBG', function()
  vim.cmd(':highlight Normal guibg=NONE guifg=NONE ctermbg=NONE ctermfg=NONE')
end, {})
-- }}}

-- PLUGINS {{{
--
-- See `:h :packadd`, `:h vim.pack`

-- Add the "nohlsearch" package to automatically disable search highlighting after
-- 'updatetime' and when going to insert mode.
vim.cmd('packadd! cfilter') -- Filter the quickfix list using :Cfilter and :Lfilter
vim.cmd('packadd! nohlsearch')
vim.cmd('packadd! nvim.difftool')
vim.cmd('packadd! nvim.undotree')

vim.g.colortemplate_toolbar = 0
vim.g.fugitive_legacy_commands = false

-- }}}

-- vim: foldmethod=marker expandtab softtabstop=2 shiftwidth=2 tabstop=2
