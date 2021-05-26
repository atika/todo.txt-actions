# My Todo.txt actions

This repository contains some of my actions for the __todo.txt__ cli program to help me manage my todo list from the command line. Some actions have been written by me, other actions have been modified to work on `macOS` and `Linux`.

## Actions

* [adda](#adda)
* [addx](#addx)
* [clean](#clean)
* [due](#due)
* [eyesight](#eyesight)
* [list](#list)
* [lsd](#lsd)
* [many](#many)
* [note](#note)
* [setdue](#setdue)
* [sub](#sub)
* [today](#today)

### _helpers

File containing some methods used on different actions.

<a name="adda"></a>
### adda ([source](http://github.com/ginatrapani/todo.txt-cli/blob/addons/.todo.actions.d/adda))

Add a todo and prioritize with (A)

<a name="addx"></a>
### addx ([source](http://github.com/ginatrapani/todo.txt-cli/blob/addons/.todo.actions.d/addx))

Add a todo and prioritize with (X)

### archive -> note

Overwrite `archive` action to also archive the note attached to the todo.

### clean

Remove blank lines from todo.txt (and renumber the tasks)

### cv -> eyesight

Context view: `todo.sh cv` or `todo.sh eyesight context`

### del -> note

Overwrite `del` action to also move the note attached to the todo to the notes trash folder.

### due

Display a list of all todos with a __due date__ in categories like: overdue, today, tomorrow, due in x days or later.

__Usage:__

```sh
todo.sh due
todo.sh due today
todo.sh due tomorrow
todo.sh due +2
todo.sh due -10
```

### edit ([source](https://github.com/the1ts/todo.txt-plugins))

Edit the todo.txt file.

### eyesight

Display a context, project or today view of your todo.txt

```sh
eyesight project # shortcut pv
eyesight context # shortcut cv
eyesight today   # execute action: due
```

### list

Display your todos as a list but remove all the dates.

### ls -> list

Shortcut for list

### lsd

The original `list` action, with the dates.

### many

Apply the same action to `many` todos.

<a name="note"></a>
### note (modified version)

Add notes to our todos. This modified version organize notes in folders and keep the note when the task is archived. You can view archived or orphan notes (in the trash) and manage them as you want.

You can also choose your extension like `md` and add a filter when showing the note (like coloring markdown note files).

List notes and their associated task with: `todo.sh note ls`
or you can use: `add`, `edit`, `show` or for archived items: `edit archive #ITEM`, `show archive #ITEM`

__Settings:__

```sh
export TODO_NOTE_EDITOR=/usr/local/bin/code
export TODO_NOTE_EXT=".md"                    # custom note extension
export TODO_NOTE_FILTER="mdless -IP -w 50"    # note show filter
```

### pv -> eyesight

Project view: `todo.sh pv` or `todo.sh eyesight project`

### rm -> note

Overwrite `rm` action to manage the notes (same as `del`).

<a name="setdue"></a>
### setdue ([source](https://github.com/severoraz/todo.txt-cli-setdue)) (modified version)

Set due date to your todos. Need `gdate` on macOS.

### sub

Replace text in your todos without opening an editor.

### today

Display a view with todos due for today.

## More

### Cache your todo list to display at login

__BASHRC__
```sh
# shell logout script
_logout () {
    nohup $HOME/.logoutscript 2>&1 >/dev/null &
}
trap _logout EXIT

if exist "todo.sh"
then
  alias t="todo.sh -d $HOME/.todo/config"
  # display todos if the cache file exists
  # and if there are only one ssh session or the user is in the first tmux pane (%0).
  if [[ -f /var/tmp/${USER}.todo.list ]] && test `who | awk -v p=${TMUX_PANE:-no} '/tmux/{if(p=="%0"||p=="no"){next}} /ttys|pts/{c+=1} END{print c}'` -le 1
  then
    cat /var/tmp/${USER}.todo.list
  fi
fi
```


__Logout Script__
```sh
#!/bin/bash

# $HOME/.logoutscript

# Todo.txt cache
# ===================================================================
# Find in tmp a file named $USER.todo.list newer than todo.txt
# If the file does not exists or is not newer then create the file
# ===================================================================
TODO_TXT="$HOME/.todo/todo.txt"

todosl () { echo -e "\\033[1;30m—— \\0033[0mTodos\\033[1;30m ——————————————————————————————\033[0m"; }
todoel () { echo -e "\\033[1;30m---------------------------------------\\033[0m"; }

todosh () { /usr/local/bin/todo.sh -d ${HOME}/.todo/config "$@"; }
todock () { sed '$d' | sed '$d' | grep --color=never . || echo "No todos, good job!"; }
todols () {
  echo
  todosh help today 2>&1 >/dev/null && todosh today | todock || {
    todosl
    todosh ls | todock
  }
  todoel
}

if [[ -f ${TODO_TXT} ]] && [[ -x /usr/local/bin/todo.sh ]]
then
  find /var/tmp/ -type f -name "$USER.todo.list" -newer ${TODO_TXT} 2>/dev/null | grep -q . || todols | (umask 0177 && cat > /var/tmp/$USER.todo.list);
fi
~
```

### Configuration tip

Configuration to use a todo.txt file in the current directory or to __edit a todo.txt__ file on a different directory or with a different name.

```sh
# If exist use the todo.txt in the current directory
if [[ -f todo.txt ]]
then
	export TODO_DIR="$PWD"
fi

# Use a custom todo file (ending with .txt) or a todo.txt file in a different directory.
# If TODO_FILE is an absolute path it will define the TODO_DIR to the directory containing the custom todo file.
# ex: test.txt (done file will be: test_done.txt, report file will be: test_report.txt)
#
# CAUTION: without an absolute path (just the name), it will create all the files
#          in the current directory, don't export TODO_FILE or it will sow todo files
#          every times your change the directory.
#
if [[ ${TODO_FILE} == *".txt" ]]
then
	# Set the directory of custom todo file
	[[ ${TODO_FILE} == "/"* ]] && export TODO_DIR="`dirname ${TODO_FILE}`" || export TODO_DIR="$PWD"
	# Set TODO_FILE as the filename only
	export TODO_FILE=`basename "${TODO_FILE}"`
	# Prepend a prefix to other files (done file)
	# if the name is different than todo.txt
	[[ ${TODO_FILE} != "todo.txt" ]] && prefix="${TODO_FILE%.*}_"
fi

# Your todo/done/report.txt default locations
export TODO_FILE="${TODO_DIR}/${TODO_FILE:-todo.txt}"
export DONE_FILE="${TODO_DIR}/${prefix}done.txt"
export REPORT_FILE="${TODO_DIR}/${prefix}report.txt"
```

Some prioritization colors (orange):

```sh
export PRI_A='\033[38;5;214m'
export PRI_B='\033[38;5;208m'
export PRI_C='\033[38;5;209m'
export PRI_D='\033[38;5;223m'
export PRI_X=$WHITE
```

And other colors:

```sh
export COLOR_NUMBER='\033[38;5;95m'
export COLOR_DATE='\033[38;5;96m'
export COLOR_CONTEXT='\033[38;5;85m'
export COLOR_PROJECT='\033[38;5;197m'
export COLOR_META='\033[38;5;50m'
export COLOR_DONE='\033[38;5;102m'
```

