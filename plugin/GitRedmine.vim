if exists('g:GitRedmine')
  finish
endif

if !exists("g:loaded_fugitive") 
  echomsg "GitRedmine: requires fugitive.vim(https://github.com/tpope/vim-fugitive)."

  finish
endif

if !exists("g:redmine_loaded")
  echomsg "GitRedmine: requires redmine.vim(https://github.com/tpope/vim-fugitive)."

  finish
endif

let g:GitRedmine = 1

command! -nargs=0 AddBranch     :call GitRedmine#AddBranch()
command! -nargs=0 ListBranches  :call GitRedmine#GetListBranches()
command! -nargs=0 DeleteBranch  :call GitRedmine#DeleteBranch()
command! -nargs=0 MergeBranch   :call GitRedmine#MergeBranch()
command! -nargs=0 ListTags      :call GitRedmine#GetListTags()
command! -nargs=0 DeleteTag     :call GitRedmine#DeleteTag()
