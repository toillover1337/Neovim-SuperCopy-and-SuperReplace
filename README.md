# Neovim SuperCopy and SuperReplace
Neovim tweaks meant to improve workflow when replacing words and copying between system register and nvim register. 

# SuperCopy
A Neovim config .lua file meant to improve copy, cut, and paste workflow. 

This file should placed in Neovim's config directory; ensure clipboard is NOT set to "unnammedplus". Then add "require("config.supercopy")" to init.lua beneath plugin loader require line.

It changes keybinds such that standard y, p, and d all behavior as normal, but super/Alt + p/y/d will use the system level register rather than the nvim register.
Additionally, this file causes the x nvim bind to send copy results to void, allowing you to use x on text you want deleted and not saved. 

# SuperReplace
A Neovim config/plugin that creates a new search and replace function. 

This plugin requires two files, the init.lua should be placed in a directory titled "superreplace" which can be put inside the nvim plugins directory. You will also need to add the superreplace.lua file into the nvim plugin directory.

Use by inputting Super/Alt + / ; this will bring up a search bar allowing you to search for the text you want to replace. You can navigate through this menu as a normal search buffer and see the instances of your prompt in the document.

While in the search and replace buffer, you can navigate to the highlighted search text and input r for a single replacement prompt which will drop you back into your searcha nd replcae buffer, or R for a replace all prompt that will replace all highlighted instances with 
