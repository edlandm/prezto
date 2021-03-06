#
# Initializes Prezto.
#
# Authors:
#   Sorin Ionescu <sorin.ionescu@gmail.com>
#

#
# Version Check
#

# Check for the minimum supported version.
min_zsh_version='4.3.11'
if ! autoload -Uz is-at-least || ! is-at-least "$min_zsh_version"; then
  print "prezto: old shell detected, minimum required: $min_zsh_version" >&2
  return 1
fi
unset min_zsh_version

#
# Module Loader
#

# Loads Prezto modules.
function pmodload {
  local -a pmodules
  local pmodule
  local pfunction_glob='^([_.]*|prompt_*_setup|README*)(-.N:t)'

  # $argv is overridden in the anonymous function.
  pmodules=("$argv[@]")

  # ZHOME
  ZHOME=$HOME/.zsh

  # Add functions to $fpath.
  fpath=(${pmodules:+${ZDOTDIR:-$ZHOME}/modules/${^pmodules}/functions(/FN)} $fpath)

  function {
    local pfunction

    # Extended globbing is needed for listing autoloadable function directories.
    setopt LOCAL_OPTIONS EXTENDED_GLOB

    # Load Prezto functions.
    for pfunction in ${ZDOTDIR:-$ZHOME}/modules/${^pmodules}/functions/$~pfunction_glob; do
      autoload -Uz "$pfunction"
    done
  }

  # Load Prezto modules.
  for pmodule in "$pmodules[@]"; do
    if zstyle -t ":prezto:module:$pmodule" loaded 'yes' 'no'; then
      continue
    elif [[ ! -d "${ZDOTDIR:-$ZHOME}/modules/$pmodule" ]]; then
      print "$0: no such module: $pmodule" >&2
      continue
    else
      if [[ -s "${ZDOTDIR:-$ZHOME}/modules/$pmodule/init.zsh" ]]; then
        source "${ZDOTDIR:-$ZHOME}/modules/$pmodule/init.zsh"
      fi

      if (( $? == 0 )); then
        zstyle ":prezto:module:$pmodule" loaded 'yes'
      else
        # Remove the $fpath entry.
        fpath[(r)${ZDOTDIR:-$ZHOME}/modules/${pmodule}/functions]=()

        function {
          local pfunction

          # Extended globbing is needed for listing autoloadable function
          # directories.
          setopt LOCAL_OPTIONS EXTENDED_GLOB

          # Unload Prezto functions.
          for pfunction in ${ZDOTDIR:-$ZHOME}/modules/$pmodule/functions/$~pfunction_glob; do
            unfunction "$pfunction"
          done
        }

        zstyle ":prezto:module:$pmodule" loaded 'no'
      fi
    fi
  done
}

#
# Prezto Initialization
#

# Path for zsh files (mostly ones that get sourced
ZHOME=$HOME/.zsh

# Source the Prezto configuration file.
if [[ -s "${ZDOTDIR:-$ZHOME}/runcoms/zpreztorc" ]]; then
  source "${ZDOTDIR:-$ZHOME}/runcoms/zpreztorc"
fi

if [[ "$HOST" == 'shutupmiles' ]]; then
    h="laptop"
else
    h="$HOST"
fi

# Source all files for the correct host
runcoms=$ZHOME/runcoms
for f in `ls -1 $runcoms \
    | grep -Ee "^z\w*$" -e "^z\w*\.$h$" | grep -v -e 'login' -e 'logout'`; do
    source $runcoms/$f
done

# Disable color and theme in dumb terminals.
if [[ "$TERM" == 'dumb' ]]; then
  zstyle ':prezto:*:*' color 'no'
  zstyle ':prezto:module:prompt' theme 'off'
fi

# Load Zsh modules.
zstyle -a ':prezto:load' zmodule 'zmodules'
for zmodule ("$zmodules[@]") zmodload "zsh/${(z)zmodule}"
unset zmodule{s,}

# Autoload Zsh functions.
zstyle -a ':prezto:load' zfunction 'zfunctions'
for zfunction ("$zfunctions[@]") autoload -Uz "$zfunction"
unset zfunction{s,}

# Load Prezto modules.
zstyle -a ':prezto:load' pmodule 'pmodules'
pmodload "$pmodules[@]"
unset pmodules

