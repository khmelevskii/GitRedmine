" Vim plugin for integrate Git and Redmine. 
" This plugin requires:
"   - fugitive.vim (https://github.com/tpope/vim-fugitive)
"   - vim-redmine (https://github.com/toritori0318/vim-redmine)
"
" Maintainer: Yurii Khmelevskii <y@uwinart.com>
" Version:    0.1 (2013-02-01)
" License:    GPL

if exists('g:GitRedmine_auto')
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

let g:GitRedmine_auto = 1

" FUNCTION: GitRedmine#AddBranch {{{
"  
" Add branch in git from opened progect task in redmine. If branch exists, 
" then switch
" 
function! GitRedmine#AddBranch()
  let cond = {
        \   'author_id' : g:redmine_author_id
        \ }
  let cond['project_id'] = g:redmine_project_id

  let url = RedmineCreateCommand('issue_list', '', cond)
  let ret = webapi#http#get(url)
  if ret.content == ' '
    return 0
  endif

  let num = 0
  let dom = webapi#xml#parse(ret.content)
  let s:data = []
  let s:refs = []
  call add(s:data, 'Create branch for open project task:')
  call add(s:refs, '')
  let i = 1
  for elem in dom.findAll("issue")
    let id = elem.find("id").value()
    let subject = elem.find("subject").value()
    if strlen(subject) > 110
      let subject = strpart(subject, 0, 110)
      let subject = strpart( subject, 0, strridx(subject, ' ') ) . '...'
    endif

    let branch_exists = system('git branch | grep refs\#' . id . '$')
    if branch_exists != ''
      let branch_exists = '***'
    endif

    call add(s:data, i . ".  refs#" . id . ' - ' . branch_exists . subject)
    call add(s:refs, id)
    let num += 1
    let i += 1
  endfor

  call inputrestore()
  let s:current_branch = inputlist(s:data)

  if s:current_branch != '' 
    " if branch not exists - create it
    let id = s:refs[s:current_branch]
    let branch_exists = system('git branch | grep refs\#' . id . '$')
    if branch_exists == ''
      execute 'silent !git branch refs\#' . id
    endif

    execute 'silent !git checkout refs\#' . id |redraw!
    " start tracking spent time on branch
    call TimeKeeper_StartTracking()
  endif

  return num
endfunction " }}}


" FUNCTION: GitRedmine#GetListBranches {{{
"  
" ???
" 
function! GitRedmine#GetListBranches()
  call inputsave()
  let s:branches = system('git for-each-ref refs/heads/')
  let s:data = []
  let s:refs = []
  let i = 1
  call add(s:data, 'Exists branches:')
  call add(s:refs, '')

  for s:line in split(s:branches, '\n')
    let s:branch = substitute(s:line, '^.*/', '', 'g')
    let s:branch_id = substitute(s:branch, '^.*#', '', 'g')
    let s:task_name = RedmineGetTicket(s:branch_id)
    

    if s:task_name == '0' 
      let s:task_name = ''
    else
      let s:task_name = ' - ' . s:task_name
    endif

    call add( s:data, i . '.  ' . s:branch . s:task_name)
    call add(s:refs, s:branch)
    let i = i +1
  endfor

  call inputrestore()
  let s:current_branch = inputlist(s:data)

  if s:current_branch != '' 
    let s:command = s:refs[s:current_branch]
    execute 'silent !git checkout ' . substitute(s:command, '#', '\\#', '') |redraw!
    call TimeKeeper_StartTracking()
  endif
endfunction " }}}


" FUNCTION: GitRedmine#DeleteBranch {{{
"  
" ???
" 
function! GitRedmine#DeleteBranch()
  call inputsave()
  let s:branches = system('git for-each-ref refs/heads/')
  let s:data = []
  let s:refs = []
  let i = 1
  call add(s:data, 'Exists branches:')
  call add(s:refs, '')

  for s:line in split(s:branches, '\n')
    let s:branch = substitute(s:line, '^.*/', '', 'g')
    let s:branch_id = substitute(s:branch, '^.*#', '', 'g')
    let s:task_name = RedmineGetTicket(s:branch_id)
    

    if s:task_name == '0' 
      let s:task_name = ''
    else
      let s:task_name = ' - ' . s:task_name
    endif

    call add( s:data, i . '.  ' . s:branch . s:task_name)
    call add(s:refs, s:branch)
    let i = i +1
  endfor

  let s:current_branch = inputlist(s:data)
  call inputrestore()

  if s:current_branch != '' 
    let s:command = s:refs[s:current_branch]
    execute 'silent !git branch -D ' . substitute(s:command, '#', '\\#', '') |redraw!
  endif
endfunction " }}}


" FUNCTION: GitRedmine#MergeBranch {{{
"  
" ???
" 
function! GitRedmine#MergeBranch()
  let s:branch = system('git rev-parse --abbrev-ref HEAD')
  execute 'silent !git checkout master'
  execute '!git merge ' . substitute(s:branch, '#', '\\#', '')
  execute '!git branch -d ' . substitute(s:branch, '#', '\\#', '')
endfunction " }}}


" FUNCTION: GitRedmine#GetListTags {{{
"  
" ???
" 
function! GitRedmine#GetListTags()
  let s:tags = system('git for-each-ref --sort=-*taggerdate refs/tags')
  let s:data = []
  echo 'Теги проекта:'
  for s:line in split(s:tags, '\n')
    call insert( s:data, substitute(s:line, '^.*tags/', '', 'g') )
  endfor

  for s:line in s:data
    echo '  ' . s:line
  endfor
endfunction " }}}


" FUNCTION: GitRedmine#DeleteTag {{{
"  
" ???
" 
function! GitRedmine#DeleteTag()
  call inputsave()
  let s:branches = system('git tag -l')
  let s:data = []
  let i = 1
  call add(s:data, 'Delete tag:')
  for s:line in split(s:branches, '\n')
    call add( s:data, i . '.  ' . s:line )
    let i = i +1
  endfor

  let s:branch = inputlist(s:data)
  call inputrestore()

  if s:branch != '' 
    let s:command = substitute(s:data[s:branch], '\d\.\s*', '', '')
    execute '!git tag -d ' . s:command
  endif
endfunction " }}}


" vim:fdm=marker:nowrap:ts=2:
