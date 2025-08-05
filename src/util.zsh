
#--------------------------------------------------------------------#
# Utility Functions                                                  #
#--------------------------------------------------------------------#

_zsh_autosuggest_escape_command() {
	setopt localoptions EXTENDED_GLOB

	# Escape special chars in the string (requires EXTENDED_GLOB)
	# Enhanced to include more shell metacharacters for better security
	echo -E "${1//(#m)[\"\'\\()\[\]|*?~\$\`&;<>]/\\$MATCH}"
}

# Validate strategy names to prevent injection attacks
_zsh_autosuggest_validate_strategy() {
	local strategy="$1"
	case "$strategy" in
		history|completion|match_prev_cmd) return 0 ;;
		*) return 1 ;;
	esac
}
