"======================================
"    Script Name:  vim-auto-save (http://www.vim.org/scripts/script.php?script_id=4521)
"    Plugin Name:  AutoSave
"        Version:  0.1.10
"======================================

if exists("g:auto_save_loaded")
  finish
else
  let g:auto_save_loaded = 1
endif

let s:save_cpo = &cpo
set cpo&vim

if !exists("g:auto_save")
  let g:auto_save = 0
endif

if !exists("g:auto_save_silent")
  let g:auto_save_silent = 0
endif

if !exists("g:auto_save_write_all_buffers")
  let g:auto_save_write_all_buffers = 0
endif

if !exists("g:auto_save_events")
  let g:auto_save_events = ["InsertLeave", "TextChanged"]
endif

" Check all used events exist
for event in g:auto_save_events
  if !exists("##" . event)
    let eventIndex = index(g:auto_save_events, event)
    if (eventIndex >= 0)
      call remove(g:auto_save_events, eventIndex)
      echo "(AutoSave) Save on " . event . " event is not supported for your Vim version!"
      echo "(AutoSave) " . event . " was removed from g:auto_save_events variable."
      echo "(AutoSave) Please, upgrade your Vim to a newer version or use other events in g:auto_save_events!"
    endif
  endif
endfor

augroup auto_save
  autocmd!
  for event in g:auto_save_events
    execute "au " . event . " * nested call AutoSave()"
  endfor
augroup END

command AutoSaveToggle :call AutoSaveToggle()

func DoSaveCallback(timer)
  let was_modified = s:IsModified()
  if !was_modified
    return
  end

  if exists("g:auto_save_presave_hook")
    let g:auto_save_abort = 0
    execute "" . g:auto_save_presave_hook
    if g:auto_save_abort >= 1
      return
    endif
  endif

  " Preserve marks that are used to remember start and
  " end position of the last changed or yanked text (`:h '[`).
  let first_char_pos = getpos("'[")
  let last_char_pos = getpos("']")

  call DoSave()

  call setpos("'[", first_char_pos)
  call setpos("']", last_char_pos)

  if was_modified && !&modified
    if exists("g:auto_save_postsave_hook")
      execute "" . g:auto_save_postsave_hook
    endif

    if g:auto_save_silent == 0
      echo "(AutoSave) saved at " . strftime("%H:%M:%S")
    endif
  endif
endf

function AutoSave()
  if g:auto_save == 0
    return
  end
  if exists('s:timer')
      call timer_stop(s:timer)
  endif
  let s:timer = timer_start(500, 'DoSaveCallback')
endfunction

function s:IsModified()
  if g:auto_save_write_all_buffers >= 1
    let buffers = filter(range(1, bufnr('$')), 'bufexists(v:val)')
    call filter(buffers, 'getbufvar(v:val, "&modified")')
    return len(buffers) > 0
  else
    return &modified
  endif
endfunction

function DoSave()
  if g:auto_save_write_all_buffers >= 1
    silent! wa
  else
    silent! w
  endif
endfunction

function AutoSaveToggle()
  if g:auto_save >= 1
    let g:auto_save = 0
    echo "(AutoSave) OFF"
  else
    let g:auto_save = 1
    echo "(AutoSave) ON"
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
