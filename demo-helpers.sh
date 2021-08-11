#! /bin/bash
# shellcheck disable=SC2034


##################################################
## Color definitions & terminal manipulation
##################################################

# See: http://mywiki.wooledge.org/BashFAQ/037
fg_black="$(tput setaf 0)"
fg_red="$(tput setaf 1)"
fg_green="$(tput setaf 2)"
fg_yellow="$(tput setaf 3)"
fg_blue="$(tput setaf 4)"
fg_magenta="$(tput setaf 5)"
fg_cyan="$(tput setaf 6)"
fg_white="$(tput setaf 7)"

bg_black="$(tput setab 0)"
bg_red="$(tput setab 1)"
bg_green="$(tput setab 2)"
bg_yellow="$(tput setab 3)"
bg_blue="$(tput setab 4)"
bg_magenta="$(tput setab 5)"
bg_cyan="$(tput setab 6)"
bg_white="$(tput setab 7)"

cursor_hide="$(tput civis)"
bold="$(tput bold)"
underline="$(tput smul)"
blink="$(tput blink)"
standout="$(tput smso)"
italic="$(tput sitm)"
reset="$(tput sgr0)$(tput cnorm)"



##################################################
## Customizable settings
##################################################

# Typing characteristics for commands
TYPING_DELAY_MS=100   # inter-char delay
TYPING_JITTER_MS=150  # inter-char jitter

# The styles for printing to the terminal
STYLE_HEADING="${bold}${fg_red}"
STYLE_MESSAGE="${bold}${fg_green}"
STYLE_COMMAND="${bold}${fg_yellow}"
STYLE_PAUSE="${bold}${fg_white}"



##################################################
## Implementation
##################################################

# Return terminal to normal on exit
function resetterm {
  echo -n "${reset}"
}
trap resetterm EXIT

# Print a sample of formats to the screen
function demonstrateCapabilities {
  echo "Text styles:"
  echo "Normal ${blink}Blinking${reset} ${bold}Bold${reset}" \
       "${italic}Italic${reset} ${standout}Standout${reset}" \
       "${underline}Underline${reset}"
  echo ""
  colors=("black" "red" "green" "yellow" "blue" "magenta" "cyan" "white")
  echo "Normal color chart:"
  for bg in "${colors[@]}"; do
    bgc="bg_${bg}"
    for fg in "${colors[@]}"; do
      fgc="fg_${fg}"
      echo -n " ${!fgc}${!bgc}${fg}${reset} "
    done
    echo ""
  done
  echo ""
  echo "${bold}Bold${reset} color chart:"
  for bg in "${colors[@]}"; do
    bgc="bg_${bg}"
    for fg in "${colors[@]}"; do
      fgc="fg_${fg}"
      echo -n " ${bold}${!fgc}${!bgc}${fg}${reset} "
    done
    echo ""
  done
}


##################################################
## Helper functions
##################################################
function typeit {
  string="$*"
  for (( idx=0; idx<${#string}; idx++ )); do
    echo -n "${string:$idx:1}"
    if [[ TYPING_DELAY_MS -gt 0 ]]; then
      jitter=$(( (RANDOM % 100 - 50) * TYPING_JITTER_MS / 50 ))
      delay=$(printf %.3f\\n "$((TYPING_DELAY_MS + jitter))e-3")
      sleep "$delay" > /dev/null 2>&1
    fi
  done
}

# Like cmd, but don't actually execute the command
function showCmd {
  echo -n "${STYLE_COMMAND}\$ "
  typeit "$*"
  echo "${reset}"
}

# Execute a command: cmd <command> [<args>...]
function cmd {
  showCmd "$@"
  "$@"
}

# Print a message: print <message>...
function print {
  echo "${STYLE_MESSAGE}$*${reset}"
}

# Wait for a keypress: pressAnyKey [<message>...]
function pressAnyKey {
  text="$*"
  if [[ -z $text ]]; then
    text="Press any key to continue..."
  fi
  read -N1 -rs -p "${STYLE_PAUSE}$text${reset}${cursor_hide}"
  echo "${reset}"
}

# Print a heading: heading <message>...
function heading {
  echo "${STYLE_HEADING}$*${reset}"
}

# Auto-incrementing demo steps: step <message>...
STEP_INDEX=0
function step {
  STEP_INDEX=$(( STEP_INDEX + 1 ))
  print "Step ${STEP_INDEX}: $*"
}

# Run a command that uses a HEREDOC
# hereCmd <TAG> <HEREVAR> <command>...
function hereCmd {
  tag="$1"; shift
  here="$1"; shift
  thecmd=("$@")
  thecmd+=("<<" "$tag")
  showCmd "${thecmd[@]}"
  sleep 2
  echo "$here"
  sleep 1
  echo -n "$STYLE_COMMAND"
  typeit "$tag"
  echo "${reset}"
  # shellcheck disable=SC2048
  $* <<< "$here"
}

if [[ $(basename "$0") == "demo-helpers.sh" ]]; then
  demonstrateCapabilities

  heading "Headings look like this via heading"
  print "You can print simple messages via print"
  showCmd "Commands are run via cmd or just printed via showCmd"
  step "the step command"
  step "provides auto-numbered steps"
  step "hereCmd can be used to run commands using heredoc"
  CONTENTS=$(cat - <<THETAG
apiVersion: scribe.backube/v1alpha1
kind: ReplicationDestination
metadata:
  name: foo
spec:
  rsync:
    serviceType: LoadBalancer
    copyMethod: Snapshot
    capacity: 700Gi
    accessModes: [ReadWriteOnce]
THETAG
)
  hereCmd "EOF" "$CONTENTS" "cat -"
fi
