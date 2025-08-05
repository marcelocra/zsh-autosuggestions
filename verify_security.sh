#!/bin/bash

# Security Verification Script for zsh-autosuggestions
# Verifies that security improvements have been implemented

echo "=== Security Implementation Verification ==="
echo

# Check if security improvements are present in source files
echo "1. Checking for enhanced character escaping..."
if grep -q '\$\\`&;<>' src/util.zsh; then
    echo "   ✓ Enhanced character escaping implemented"
else
    echo "   ✗ Enhanced character escaping not found"
fi

echo
echo "2. Checking for strategy validation function..."
if grep -q '_zsh_autosuggest_validate_strategy' src/util.zsh; then
    echo "   ✓ Strategy validation function implemented"
else
    echo "   ✗ Strategy validation function not found"
fi

echo
echo "3. Checking for strategy validation usage..."
if grep -q '_zsh_autosuggest_validate_strategy' src/fetch.zsh; then
    echo "   ✓ Strategy validation is being used"
else
    echo "   ✗ Strategy validation not used in fetch logic"
fi

echo
echo "4. Checking for process verification..."
if grep -q 'kill -0.*_ZSH_AUTOSUGGEST_CHILD_PID' src/async.zsh; then
    echo "   ✓ Process verification before kill implemented"
else
    echo "   ✗ Process verification not found"
fi

echo
echo "5. Checking for configuration validation..."
if grep -q '_zsh_autosuggest_validate_config' src/config.zsh; then
    echo "   ✓ Configuration validation function implemented"
else
    echo "   ✗ Configuration validation function not found"
fi

echo
echo "6. Checking if main plugin file was rebuilt..."
if grep -q '_zsh_autosuggest_validate_strategy' zsh-autosuggestions.zsh; then
    echo "   ✓ Main plugin file includes security improvements"
else
    echo "   ✗ Main plugin file needs to be rebuilt"
fi

echo
echo "7. Verifying documentation exists..."
if [[ -f "SECURITY_REVIEW.md" ]]; then
    echo "   ✓ Comprehensive security review document created"
    echo "     Size: $(wc -l < SECURITY_REVIEW.md) lines"
else
    echo "   ✗ Security review document not found"
fi

if [[ -f "SECURITY_ISSUES.md" ]]; then
    echo "   ✓ Security issues summary created"
    echo "     Size: $(wc -l < SECURITY_ISSUES.md) lines"
else
    echo "   ✗ Security issues summary not found"
fi

echo
echo "=== Verification Complete ==="

# Count total improvements
improvements=0
grep -q '\$\\`&;<>' src/util.zsh && ((improvements++))
grep -q '_zsh_autosuggest_validate_strategy' src/util.zsh && ((improvements++))
grep -q '_zsh_autosuggest_validate_strategy' src/fetch.zsh && ((improvements++))
grep -q 'kill -0.*_ZSH_AUTOSUGGEST_CHILD_PID' src/async.zsh && ((improvements++))
grep -q '_zsh_autosuggest_validate_config' src/config.zsh && ((improvements++))
grep -q '_zsh_autosuggest_validate_strategy' zsh-autosuggestions.zsh && ((improvements++))

echo "Security improvements implemented: $improvements/6"

if [[ $improvements -eq 6 ]]; then
    echo "✓ All security improvements successfully implemented!"
    exit 0
else
    echo "⚠ Some security improvements may be missing"
    exit 1
fi