export TMPDIR=${TMPDIR:-/tmp}

log() {
  # $1: message
  # $2: json
  local message="$(date -u '+%F %T') - $1"
  if [ -n "$2" ]; then
   message+=" - $(hide_password "$2")"
  fi
  echo "$message" >&2
}

hide_password() {
  if ! echo "$1" | jq -c '.' > /dev/null 2> /dev/null; then
    echo "(invalid json: $1)>"
    exit 1
  fi

  local paths=$(echo "${1:-{\} }" | jq -c "paths")
  local query=""
  if [ -n "$paths" ]; then
    while read path; do
      local parts=$(echo "$path" | jq -r '.[]')
      local selection=""
      local found=""
      while read part; do
        selection+=".$part"
        if [ "$part" == "password" ]; then
          found="true"
        fi
      done <<< "$parts"

      if [ -n "$found" ]; then
        query+=" | jq -c '$selection = \"*******\"'"
      fi
    done <<< "$paths"
  fi

  local json="${1//\"/\\\"}"
  eval "echo \"$json\" $query"
}

copy_preserve_folder() {
  # Move specified files to a specified folder preserving directory structure.
  # Based on answers at:
  # http://stackoverflow.com/questions/1650164/bash-copy-named-files-recursively-preserving-folder-structure
  local length=$(($#-1))
  local array=${@:1:$length}

  if [ ${#@} -lt 2 ]; then
    log "USAGE: copy_preserve_folder file [file file ...] directory"
  else
    tar cf - $array | (cd ${@:${#@}} ; tar xf -)
  fi
}

contains_element() {
  local e
  for e in "${@:2}"; do [[ "$e" == "$1" ]] && return 0; done
  return 1
}

replace () {
  local source="${1//\//\\\/}"
  local search="${2//\//\\\/}"
  local replace="${3//\//\\\/}"

  echo "${source//$search/$replace}"
}

replace_placeholder () {
  local source="$1"
  local placeholder="$2"
  local value="$3"

  replace "$source" "%%$placeholder%%" "$value"
}

unique_sibling_elements() {
  # $1: JSON payload holding groups
  # $2: selector to search in
  # $4: name of selector to filter on
  # $3: element key for to look for in selector

  local payload="$1"
  local selector="$2"
  local name="$3"
  local element="$4"

  # query in words: get all elements for $selector with $name and select those elements that are NOT in elements included in others selectors
  jq -c ".$selector[] | select(.name == \"$name\") | .$element // [] | map(select(in(
      $(jq -c ".$selector[] | select(.name != \"$name\") | .$element // []" < "$payload" | array_as_object_with_values_as_keys)
    ) | not))" < "$payload"
}

array_as_object_with_values_as_keys() {
  # $1: key to use in case it is array of objects
  jq "reduce .[] as \$item ({}; . + { (\$item$1): \$item })"
}

