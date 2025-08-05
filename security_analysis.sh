#!/bin/bash
# Security Vulnerability Analysis Tool for zsh-autosuggestions
# This script demonstrates the security vulnerabilities found in the audit

echo "=== zsh-autosuggestions Security Vulnerability Analysis ==="
echo "This tool analyzes the codebase for the vulnerabilities identified in the security audit."
echo

# V-01: Code Injection via Dynamic Eval
echo "V-01: Code Injection via Dynamic Eval"
echo "-----------------------------------"
echo "Searching for eval statements that could be exploited..."
grep -n "eval.*widget" src/bind.zsh | head -5
echo
echo "Risk: Widget names could potentially contain malicious code if not properly sanitized."
echo "File: src/bind.zsh, Lines: 37, 44, 54"
echo

# V-02 & V-03: Command Injection via History Pattern
echo "V-02/V-03: Command Injection via History Pattern"
echo "----------------------------------------------"
echo "Searching for history pattern usage..."
grep -n "history\[(r)\|history\[(R)" src/strategies/*.zsh
echo
echo "Risk: User input used directly in glob patterns without proper validation."
echo "Files: src/strategies/history.zsh:31, src/strategies/match_prev_cmd.zsh:43"
echo

# V-04: Race Condition in Process Management
echo "V-04: Race Condition in Process Management"
echo "----------------------------------------"
echo "Searching for potential race conditions in async operations..."
grep -n -A3 -B1 "kill.*CHILD_PID" src/async.zsh
echo
echo "Risk: Race condition between checking FD validity and killing processes."
echo "File: src/async.zsh, Lines: 24, 29"
echo

# V-05: File Descriptor Leak
echo "V-05: File Descriptor Leak"
echo "-------------------------"
echo "Searching for file descriptor handling..."
grep -n "exec.*<&" src/async.zsh
echo
echo "Risk: File descriptors may not be properly closed in error conditions."
echo "File: src/async.zsh, Line: 71"
echo

# V-06: Process Injection in Kill Operations
echo "V-06: Process Injection in Kill Operations"
echo "-----------------------------------------"
echo "Searching for potentially unsafe kill operations..."
grep -n "kill.*\$\$" src/strategies/completion.zsh
echo
echo "Risk: Process ID could potentially be manipulated."
echo "File: src/strategies/completion.zsh, Line: 57"
echo

# Additional analysis: Check for command execution patterns
echo "Additional Security Analysis"
echo "---------------------------"
echo "Checking for other potentially dangerous patterns..."
echo
echo "1. Use of zpty (pseudo-terminal) which can execute commands:"
grep -n "zpty" src/strategies/completion.zsh | head -3
echo
echo "2. Direct command execution patterns:"
grep -n "command\|exec" src/ -R | grep -v "exec.*<&" | head -3
echo
echo "3. Input sanitization mechanisms:"
grep -n "escape\|sanitize" src/ -R
echo

echo "=== Analysis Complete ==="
echo "See SECURITY_AUDIT.md for detailed findings and remediation steps."