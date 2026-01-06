-- Setup for the terminal within nvim

-- Check the system's default shell
local system_shell = os.getenv("SHELL") or "/bin/bash"
local shell_cmd = system_shell

-- Logic to determine shell configuration
if system_shell:match("bash$") then
    -- Check if local bash profile exists
    local bash_profile = vim.fn.expand("~/.bash_profile")
    if vim.fn.filereadable(bash_profile) == 1 then
        -- Use the local bash profile without using login shell (--rcfile)
        shell_cmd = system_shell .. " --rcfile " .. bash_profile
    end
elseif system_shell:match("zsh$") then
    -- For zsh, standard interactive shell will read .zshrc
    shell_cmd = system_shell
end

-- Set the shell option
vim.o.shell = shell_cmd