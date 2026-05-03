#compdef todo.sh t

# Completion for todo.sh and the 't' alias.
# Uses -p (plain mode) to avoid ANSI codes in output.
# Projects/contexts are cached to minimize SSH round-trips.

setopt localoptions braceccl
zmodload -F zsh/stat b:zstat 2>/dev/null

local expl curcontext="$curcontext" state line pri nextstate item
local -a cmdlist itemlist match mbegin mend
integer NORMARG

_arguments -s -n : \
  '-@[hide context names]' \
  '-\+[hide project names]' \
  '-c[color mode]' \
  '-d[alternate config file]:config file:_files' \
  '-f[force, no confirmation]' \
  '-h[display help]' \
  '-p[plain mode, no colours]' \
  '-P[hide priority labels]' \
  "-a[don't auto-archive tasks when done]" \
  '-A[auto-archive tasks when done]' \
  '-n[automatically remove blank lines]' \
  '-N[preserve line numbers]' \
  '-t[add current date to task on creation]' \
  "-T[don't add current date to task]" \
  '-v[verbose mode, confirmation messages]' \
  '-vv[extra verbose (debug)]' \
  '-V[display version etc.]' \
  '-x[disable final filter]' \
  '1:command:->commands' \
  '*:arguments:->arguments' && return 0

local projmsg="context or project"
local txtmsg="text with contexts or projects"

# Skip "command" as command prefix if words after
if [[ $words[NORMARG] == command && NORMARG -lt CURRENT ]]; then
  (( NORMARG++ ))
fi

case $state in
  (commands)
  cmdlist=(
    "add:add TODO ITEM to todo.txt."
    "addm:add TODO ITEMs, one per line, to todo.txt."
    "addto:add text to file (not item)"
    "adda:add and prioritize A in one step."
    "addx:add and mark as done in one step."
    "append:adds to item on line NUMBER the text TEXT."
    "archive:moves done items from todo.txt to done.txt."
    "clean:removes blank lines from todo.txt."
    "command:run internal commands only"
    "cv:context view of tasks."
    "deduplicate:removes duplicate lines from todo.txt."
    "del:deletes the item on line NUMBER in todo.txt."
    "depri:remove prioritization from item"
    "done:marks task(s) on line ITEM# as done in todo.txt"
    "do:marks item on line NUMBER as done in todo.txt."
    "due:show tasks by due dates."
    "edit:open todo.txt in \$EDITOR."
    "eyesight:visual view of tasks."
    "help:display help"
    "list:displays all todo items without the date."
    "listall:displays items including done ones containing TERM(s)"
    "listaddons:lists all added and overridden actions in the actions directory."
    "listcon:list all contexts"
    "listfile:display all files in .todo directory"
    "listpri:displays all items prioritized at PRIORITY."
    "listproj:lists all the projects in todo.txt."
    "ls:same as list, without the date."
    "lsd:same as ls command with the date."
    "many:apply an action to multiple items."
    "move:move item between files"
    "note:manage notes attached to a task."
    "prepend:adds to the beginning of the item on line NUMBER text TEXT."
    "pri:adds or replace in NUMBER the priority PRIORITY (upper case letter)."
    "pv:project view of tasks."
    "replace:replace in NUMBER the TEXT."
    "report:adds the number of open and done items to report.txt."
    "rls:list tasks for all remote hosts."
    "rm:deletes the item on line NUMBER (alias for del)."
    "setdue:set or change the due date of task(s)."
    "showhelp:list the one-line usage of all built-in and add-on actions."
    "sub:replace TERM (regex) on line ITEM# with NEWTERM."
    "today:today view of all tasks."
  )
  _describe -t todo-commands 'todo.sh command' cmdlist
  ;;

  (arguments)
  case $words[NORMARG] in
    (append|command|del|rm|move|mv|prepend|pri|replace|sub)
    if (( NORMARG == CURRENT - 1 )); then
      nextstate=item
    else
      case $words[NORMARG] in
        (pri)
        nextstate=pri
        ;;
        (append|prepend|sub)
        nextstate=proj
        ;;
        (move|mv)
        nextstate=file
        ;;
        (replace)
        item=${words[CURRENT-1]##0##}
        compadd -Q -- "${(qq)$(todo.sh -p list "^[ 0]*$item " | sed '/^--/,$d')##<-> (\([A-Z]\) |)}"
        ;;
      esac
    fi
    ;;

    (depri|do|done|dp)
    nextstate=item
    ;;

    (a|add|addm|adda|addx|list|ls|lsd|listall|lsa|eyesight|cv|pv|rls|many)
    nextstate=proj
    ;;

    (due|today)
    local due_terms=(
      "today:tasks due today"
      "tomorrow:tasks due tomorrow"
      "+1:tasks due tomorrow"
    )
    _describe -t due-terms 'due filter' due_terms
    nextstate=proj
    ;;

    (setdue)
    if (( NORMARG == CURRENT - 1 )); then
      local date_specs=(
        "nw:next week (same weekday)"
        "mon:next Monday"
        "tue:next Tuesday"
        "wed:next Wednesday"
        "thu:next Thursday"
        "fri:next Friday"
        "sat:next Saturday"
        "sun:next Sunday"
        "+N:in N days  (+1 +7 +14 ...)"
        "-N:N days ago  (-1 -7 ...)"
        "---DD:day DD of current month  (---15 ---01 ...)"
        "--MM-DD:date in current year  (--03-15 --12-31 ...)"
        "---:remove due date"
      )
      _describe -t date-specs 'date specification' date_specs
    else
      nextstate=item
    fi
    ;;

    (edit)
    local edit_targets=(
      "todo:edit todo.txt"
      "done:edit done.txt"
      "cfg:edit config file"
    )
    _describe -t edit-targets 'file to edit' edit_targets
    ;;

    (note)
    local pos=$(( CURRENT - NORMARG ))
    if (( pos == 1 )); then
      local note_cmds=(
        "add:add a note to ITEM#  (a)"
        "edit:open note in \$EDITOR  (e) [archive|ITEM#]"
        "show:show note for ITEM#  (s) [archive|ITEM#]"
        "list:list all notes  (ls)"
      )
      _describe -t note-commands 'note subcommand' note_cmds
    elif (( pos == 2 )); then
      case $words[NORMARG+1] in
        (edit|e|show|s)
        local -a note_targets
        note_targets=("archive:open the notes archive")
        # Only items that already have a note attached (note:xxx.md tag)
        note_targets+=( ${${(M)${(f)"$(todo.sh -p list 2>/dev/null | grep 'note:[^ ]*' | sed '/^--/,$d')"}##<-> *}/(#b)(<->) (*)/${match[1]}:${match[2]}} )
        _describe -t note-targets 'note target' note_targets
        ;;
        (add|a)
        nextstate=item
        ;;
      esac
    elif (( pos == 3 )); then
      case $words[NORMARG+1] in
        (edit|e|show|s)
        # Items from done.txt that have a note attached
        local -a done_items
        done_items=( ${${(M)${(f)"$(todo.sh -p listfile done 2>/dev/null | grep 'note:[^ ]*' | sed '/^--/,$d')"}##<-> *}/(#b)(<->) (*)/${match[1]}:${match[2]}} )
        _describe -t done-items 'done item with note' done_items
        ;;
      esac
    fi
    ;;

    (addto)
    if (( NORMARG == CURRENT - 1 )); then
      nextstate=file
    else
      nextstate=proj
    fi
    ;;

    (listfile|lf)
    if (( NORMARG == CURRENT - 1 )); then
      nextstate=file
    else
      _message "Term to search file for"
    fi
    ;;

    (listpri|lsp)
    nextstate=pri
    ;;

    (*)
    return 1
    ;;
  esac
  ;;
esac

case $nextstate in
  (file)
  _path_files -W ~/.todo
  ;;

  (item)
  itemlist=(${${(M)${(f)"$(todo.sh -p list | sed '/^--/,$d')"}##<-> *}/(#b)(<->) (*)/${match[1]}:${match[2]}})
  _describe -t todo-items 'todo item' itemlist
  ;;

  (pri)
  if [[ $words[CURRENT] = (|[A-Z]) ]]; then
    if [[ $words[CURRENT] = (|Z) ]]; then
      pri=A
    else
      pri=$words[CURRENT]
      pri=${(#)$(( #pri + 1 ))}
    fi
    _wanted priority expl 'priority' compadd -U -S '' -- $pri
  else
    _wanted priority expl 'priority' compadd {A-Z}
  fi
  ;;

  (proj)
  if [[ ! -prefix + && ! -prefix @ ]]; then
    projmsg=$txtmsg
  fi
  compset -P '*[[:space:]]'
  local _proj_cache="/tmp/${USER}.todo.proj"
  local _mtime=0
  zstat -A _mtime +mtime "$_proj_cache" 2>/dev/null
  if (( $(date +%s) - _mtime > 300 )) || [[ ! -s $_proj_cache ]]; then
    { todo.sh lsprj 2>/dev/null; todo.sh lsc 2>/dev/null; } >| "$_proj_cache"
  fi
  _wanted search expl $projmsg \
    compadd $(< "$_proj_cache")
  ;;
esac
