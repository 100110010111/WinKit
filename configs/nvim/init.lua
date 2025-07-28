-- ~/.config/nvim/init.lua or ~/.config/nvim/lua/config/wezterm.lua

-- Basic Neovim settings
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.wrap = false
vim.opt.termguicolors = true

-- Leader key
vim.g.mapleader = " "

-- Better split navigation within Neovim
-- These work alongside WezTerm's pane navigation
vim.keymap.set('n', '<C-h>', '<C-w>h', { desc = 'Move to left split' })
vim.keymap.set('n', '<C-j>', '<C-w>j', { desc = 'Move to bottom split' })
vim.keymap.set('n', '<C-k>', '<C-w>k', { desc = 'Move to top split' })
vim.keymap.set('n', '<C-l>', '<C-w>l', { desc = 'Move to right split' })

-- Split management within Neovim
vim.keymap.set('n', '<leader>sv', '<C-w>v', { desc = 'Split vertically' })
vim.keymap.set('n', '<leader>sh', '<C-w>s', { desc = 'Split horizontally' })
vim.keymap.set('n', '<leader>se', '<C-w>=', { desc = 'Make splits equal size' })
vim.keymap.set('n', '<leader>sx', '<cmd>close<CR>', { desc = 'Close current split' })

-- Tab management within Neovim
vim.keymap.set('n', '<leader>to', '<cmd>tabnew<CR>', { desc = 'Open new tab' })
vim.keymap.set('n', '<leader>tx', '<cmd>tabclose<CR>', { desc = 'Close current tab' })
vim.keymap.set('n', '<leader>tn', '<cmd>tabn<CR>', { desc = 'Go to next tab' })
vim.keymap.set('n', '<leader>tp', '<cmd>tabp<CR>', { desc = 'Go to previous tab' })
vim.keymap.set('n', '<leader>tf', '<cmd>tabnew %<CR>', { desc = 'Open current buffer in new tab' })

-- Better terminal integration
vim.keymap.set('n', '<leader>tt', '<cmd>terminal<CR>', { desc = 'Open terminal' })
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- File explorer (if you're using netrw)
vim.keymap.set('n', '<leader>e', '<cmd>Explore<CR>', { desc = 'Open file explorer' })

-- Quick save and quit
vim.keymap.set('n', '<leader>w', '<cmd>write<CR>', { desc = 'Save file' })
vim.keymap.set('n', '<leader>q', '<cmd>quit<CR>', { desc = 'Quit' })
vim.keymap.set('n', '<leader>x', '<cmd>x<CR>', { desc = 'Save and quit' })

-- Clear search highlighting
vim.keymap.set('n', '<leader>nh', '<cmd>nohl<CR>', { desc = 'Clear search highlights' })

-- Better copy/paste integration with system clipboard
vim.opt.clipboard = "unnamedplus"

-- Disable arrow keys to encourage hjkl usage (optional)
-- vim.keymap.set('n', '<Left>', '<Nop>')
-- vim.keymap.set('n', '<Right>', '<Nop>')
-- vim.keymap.set('n', '<Up>', '<Nop>')
-- vim.keymap.set('n', '<Down>', '<Nop>')

-- Terminal settings for better integration
vim.api.nvim_create_autocmd('TermOpen', {
  pattern = '*',
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.cmd('startinsert')
  end,
})
