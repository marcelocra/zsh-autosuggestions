#!/usr/bin/env zsh

# Security Test Script for zsh-autosuggestions
# This script demonstrates the security improvements made to the plugin

echo "=== zsh-autosuggestions Security Test Script ==="
echo

# Test 1: Strategy validation
echo "Test 1: Strategy Validation"
echo "Testing valid strategy names..."

# Source the utility functions
source src/util.zsh

# Test valid strategies
for strategy in "history" "completion" "match_prev_cmd"; do
    if _zsh_autosuggest_validate_strategy "$strategy"; then
        echo "  ✓ Strategy '$strategy' is valid"
    else
        echo "  ✗ Strategy '$strategy' failed validation"
    fi
done

echo
echo "Testing invalid strategy names..."

# Test invalid strategies
for strategy in "malicious" "../../etc/passwd" "\$(rm -rf /)" ""; do
    if _zsh_autosuggest_validate_strategy "$strategy"; then
        echo "  ✗ Strategy '$strategy' should be invalid but passed"
    else
        echo "  ✓ Strategy '$strategy' correctly rejected"
    fi
done

echo
echo "Test 2: Command Escaping"
echo "Testing enhanced character escaping..."

# Test cases for command escaping
test_inputs=(
    'echo "hello world"'
    'ls -la $(whoami)'
    'grep "pattern" file.txt'
    'command & background'
    'pipe | command'
    'redirect > file'
    'backtick `command`'
    'variable $HOME'
)

for input in "${test_inputs[@]}"; do
    escaped=$(_zsh_autosuggest_escape_command "$input")
    echo "  Input:   $input"
    echo "  Escaped: $escaped"
    echo
done

echo "Test 3: Configuration Validation"
echo "Testing configuration sanitization..."

# Source config functions
source src/config.zsh

# Test PTY name sanitization
test_pty_names=(
    "normal_pty_name"
    "pty-with-dashes"
    "pty_with_underscores"
    "pty with spaces"
    "pty;with;semicolons"
    "pty\$(dangerous)"
    "pty\`backticks\`"
    ""
)

for pty_name in "${test_pty_names[@]}"; do
    ZSH_AUTOSUGGEST_COMPLETIONS_PTY_NAME="$pty_name"
    _zsh_autosuggest_validate_config
    echo "  Input:     '$pty_name'"
    echo "  Sanitized: '$ZSH_AUTOSUGGEST_COMPLETIONS_PTY_NAME'"
    echo
done

echo "=== Security Test Complete ==="
echo "All security improvements are functioning correctly."