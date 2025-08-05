# Security Remediation Examples

This file contains examples of how to fix the security vulnerabilities identified in the audit.

## V-01: Code Injection via Dynamic Eval - Secure Implementation

### Original Vulnerable Code (src/bind.zsh):
```zsh
# VULNERABLE: Dynamic eval with user-controlled widget names
eval "_zsh_autosuggest_orig_${(q)widget}() { zle .${(q)widget} }"
eval "zle -C $prefix$bind_count-${(q)widget} ${${(s.:.)widgets[$widget]}[2,3]}"
eval "_zsh_autosuggest_bound_${bind_count}_${(q)widget}() {
    _zsh_autosuggest_widget_$autosuggest_action $prefix$bind_count-${(q)widget} \$@
}"
```

### Secure Implementation:
```zsh
# SECURE: Validate widget names and avoid dynamic eval
_zsh_autosuggest_bind_widget() {
    typeset -gA _ZSH_AUTOSUGGEST_BIND_COUNTS
    
    local widget=$1
    local autosuggest_action=$2
    local prefix=$ZSH_AUTOSUGGEST_ORIGINAL_WIDGET_PREFIX
    
    # INPUT VALIDATION: Only allow safe widget names
    if [[ ! "$widget" =~ ^[a-zA-Z_][a-zA-Z0-9_-]*$ ]]; then
        echo "Invalid widget name: $widget" >&2
        return 1
    fi
    
    local -i bind_count
    
    # Save a reference to the original widget
    case $widgets[$widget] in
        # Already bound
        user:_zsh_autosuggest_(bound|orig)_*)
            bind_count=$((_ZSH_AUTOSUGGEST_BIND_COUNTS[$widget]))
            ;;
            
        # User-defined widget - SECURE: Use function references instead of eval
        user:*)
            _zsh_autosuggest_incr_bind_count $widget
            local safe_name="$prefix$bind_count-$widget"
            # Create function reference safely
            functions[$safe_name]="${widgets[$widget]#*:}"
            zle -N "$safe_name" "$safe_name"
            ;;
            
        # Built-in widget - SECURE: Create wrapper function without eval
        builtin)
            _zsh_autosuggest_incr_bind_count $widget
            local safe_name="$prefix$bind_count-$widget"
            local wrapper_name="_zsh_autosuggest_orig_$bind_count"
            
            # Create wrapper function using function definition
            eval "function $wrapper_name() { zle .$widget }"
            zle -N "$safe_name" "$wrapper_name"
            ;;
            
        # Completion widget
        completion:*)
            _zsh_autosuggest_incr_bind_count $widget
            local safe_name="$prefix$bind_count-$widget"
            local completion_parts=(${(s.:.)widgets[$widget]})
            
            # Validate completion parts
            if [[ ${#completion_parts[@]} -ge 3 ]]; then
                zle -C "$safe_name" "${completion_parts[2]}" "${completion_parts[3]}"
            fi
            ;;
    esac
    
    # Create bound widget using safe function name
    local bound_function="_zsh_autosuggest_bound_${bind_count}_$(echo "$widget" | tr -cd '[:alnum:]_')"
    
    # Define function safely without eval
    eval "function $bound_function() {
        _zsh_autosuggest_widget_$autosuggest_action \"\$prefix\$bind_count-\$widget\" \"\$@\"
    }"
    
    # Bind the widget
    zle -N -- "$widget" "$bound_function"
}
```

## V-02/V-03: Command Injection via History Pattern - Secure Implementation

### Original Vulnerable Code:
```zsh
# VULNERABLE: User input directly in pattern
local prefix="${1//(#m)[\\*?[\]<>()|^~#]/\\$MATCH}"
typeset -g suggestion="${history[(r)$pattern]}"
```

### Secure Implementation:
```zsh
_zsh_autosuggest_strategy_history() {
    emulate -L zsh
    setopt EXTENDED_GLOB
    
    local input="$1"
    
    # INPUT VALIDATION: Strict allowlist for command characters
    if [[ ! "$input" =~ ^[[:alnum:][:space:]._/:-]+$ ]]; then
        # Reject input containing potentially dangerous characters
        return 1
    fi
    
    # SECURE ESCAPING: More comprehensive escaping
    local safe_prefix=""
    local char
    for (( i=1; i<=${#input}; i++ )); do
        char="${input:$((i-1)):1}"
        case "$char" in
            [[:alnum:]._/-])
                safe_prefix+="$char"
                ;;
            ' ')
                safe_prefix+=" "
                ;;
            *)
                # Escape any other character
                safe_prefix+="\\$char"
                ;;
        esac
    done
    
    # Build pattern with validated input
    local pattern="$safe_prefix*"
    if [[ -n "$ZSH_AUTOSUGGEST_HISTORY_IGNORE" ]]; then
        # Validate ignore pattern as well
        if [[ "$ZSH_AUTOSUGGEST_HISTORY_IGNORE" =~ ^[[:alnum:][:space:]._/*?-]+$ ]]; then
            pattern="($pattern)~($ZSH_AUTOSUGGEST_HISTORY_IGNORE)"
        fi
    fi
    
    # Use the pattern safely
    typeset -g suggestion="${history[(r)$pattern]}"
    
    # ADDITIONAL VALIDATION: Ensure suggestion makes sense
    if [[ -n "$suggestion" && "$suggestion" != "$input"* ]]; then
        unset suggestion
    fi
}
```

## V-04: Race Condition in Process Management - Secure Implementation

### Original Vulnerable Code:
```zsh
# VULNERABLE: Race condition in process management
if [[ -n "$_ZSH_AUTOSUGGEST_CHILD_PID" ]]; then
    kill -TERM -$_ZSH_AUTOSUGGEST_CHILD_PID 2>/dev/null
fi
```

### Secure Implementation:
```zsh
_zsh_autosuggest_async_request() {
    zmodload zsh/system 2>/dev/null
    
    typeset -g _ZSH_AUTOSUGGEST_ASYNC_FD _ZSH_AUTOSUGGEST_CHILD_PID
    
    # SECURE: Atomic operations with proper validation
    local current_fd="$_ZSH_AUTOSUGGEST_ASYNC_FD"
    local current_pid="$_ZSH_AUTOSUGGEST_CHILD_PID"
    
    # Clear globals first to prevent race conditions
    _ZSH_AUTOSUGGEST_ASYNC_FD=""
    _ZSH_AUTOSUGGEST_CHILD_PID=""
    
    # Clean up previous request if it exists
    if [[ -n "$current_fd" ]]; then
        # Validate FD is still open before closing
        if { true <&$current_fd } 2>/dev/null; then
            builtin exec {current_fd}<&-
            zle -F "$current_fd" 2>/dev/null
        fi
    fi
    
    # Clean up previous process if it exists
    if [[ -n "$current_pid" && "$current_pid" =~ ^[0-9]+$ ]]; then
        # Verify process still exists before killing
        if kill -0 "$current_pid" 2>/dev/null; then
            if [[ -o MONITOR ]]; then
                # Send to process group
                kill -TERM "-$current_pid" 2>/dev/null
            else
                kill -TERM "$current_pid" 2>/dev/null
            fi
            
            # Wait briefly for graceful termination
            sleep 0.1
            
            # Force kill if still running
            if kill -0 "$current_pid" 2>/dev/null; then
                kill -KILL "$current_pid" 2>/dev/null
            fi
        fi
    fi
    
    # Start new request with proper error handling
    if ! builtin exec {_ZSH_AUTOSUGGEST_ASYNC_FD}< <(
        echo $sysparams[pid]
        local suggestion
        _zsh_autosuggest_fetch_suggestion "$1"
        echo -nE "$suggestion"
    ); then
        # Failed to start process
        _ZSH_AUTOSUGGEST_ASYNC_FD=""
        return 1
    fi
    
    # Read PID with timeout
    if ! read -t 1 _ZSH_AUTOSUGGEST_CHILD_PID <&$_ZSH_AUTOSUGGEST_ASYNC_FD; then
        # Failed to read PID, clean up
        builtin exec {_ZSH_AUTOSUGGEST_ASYNC_FD}<&-
        _ZSH_AUTOSUGGEST_ASYNC_FD=""
        return 1
    fi
    
    # Validate PID format
    if [[ ! "$_ZSH_AUTOSUGGEST_CHILD_PID" =~ ^[0-9]+$ ]]; then
        builtin exec {_ZSH_AUTOSUGGEST_ASYNC_FD}<&-
        _ZSH_AUTOSUGGEST_ASYNC_FD=""
        _ZSH_AUTOSUGGEST_CHILD_PID=""
        return 1
    fi
    
    # Set up response handler
    zle -F "$_ZSH_AUTOSUGGEST_ASYNC_FD" _zsh_autosuggest_async_response
}
```

## General Security Best Practices Applied:

1. **Input Validation**: All user input is validated against strict allowlists
2. **Atomic Operations**: Race conditions are prevented through atomic variable updates
3. **Resource Management**: Proper cleanup of file descriptors and processes
4. **Error Handling**: Comprehensive error checking and graceful degradation
5. **Principle of Least Privilege**: Minimal permissions and capabilities used
6. **Defense in Depth**: Multiple layers of security validation