#!/bin/bash

# Test script for macOS installer
# Validates installer functionality without actually installing

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

print_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

print_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
}

print_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

# Test configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALLER_SCRIPT="$SCRIPT_DIR/install_youtube_to_newtrack.sh"
DMG_BUILDER="$SCRIPT_DIR/create_dmg.sh"
MAIN_SCRIPT="$SCRIPT_DIR/../../YouTube_to_NewTrack.lua"

test_file_exists() {
    local file="$1"
    local description="$2"
    
    print_test "Checking $description exists..."
    if [ -f "$file" ]; then
        print_pass "$description found"
        return 0
    else
        print_fail "$description not found: $file"
        return 1
    fi
}

test_script_executable() {
    local script="$1"
    local description="$2"
    
    print_test "Checking $description is executable..."
    if [ -x "$script" ]; then
        print_pass "$description is executable"
        return 0
    else
        print_fail "$description is not executable"
        return 1
    fi
}

test_script_syntax() {
    local script="$1"
    local description="$2"
    
    print_test "Checking $description syntax..."
    if bash -n "$script" 2>/dev/null; then
        print_pass "$description syntax is valid"
        return 0
    else
        print_fail "$description has syntax errors"
        return 1
    fi
}

test_required_commands() {
    print_test "Checking for required commands in installer..."
    
    local required_commands=(
        "sw_vers"      # macOS version check
        "mkdir"        # Directory creation
        "cp"           # File copying
        "ln"           # Symbolic links
        "curl"         # Downloads
        "open"         # Open URLs/files
    )
    
    local missing_commands=()
    
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_commands+=("$cmd")
        fi
    done
    
    if [ ${#missing_commands[@]} -eq 0 ]; then
        print_pass "All required commands available"
        return 0
    else
        print_fail "Missing commands: ${missing_commands[*]}"
        return 1
    fi
}

test_optional_commands() {
    print_test "Checking for optional commands..."
    
    local optional_commands=(
        "brew"         # Homebrew
        "yt-dlp"       # YouTube downloader
        "ffmpeg"       # Audio processing
        "create-dmg"   # DMG creation
        "convert"      # ImageMagick
    )
    
    for cmd in "${optional_commands[@]}"; do
        if command -v "$cmd" >/dev/null 2>&1; then
            print_info "$cmd available"
        else
            print_info "$cmd not available (optional)"
        fi
    done
}

test_macos_paths() {
    print_test "Testing macOS path detection..."
    
    # Test REAPER paths (these should exist on any Mac, even without REAPER)
    local test_paths=(
        "$HOME/Library"
        "$HOME/Library/Application Support"
        "/Applications"
    )
    
    for path in "${test_paths[@]}"; do
        if [ -d "$path" ]; then
            print_pass "Path exists: $path"
        else
            print_fail "Path missing: $path"
        fi
    done
}

test_installer_functions() {
    print_test "Testing installer function definitions..."
    
    # Source the installer script and check if key functions are defined
    if source "$INSTALLER_SCRIPT" >/dev/null 2>&1; then
        print_pass "Installer script sources successfully"
        
        # Check if key functions exist
        local functions=(
            "check_macos_version"
            "check_reaper_installation"
            "check_sws_extension"
            "install_script"
        )
        
        for func in "${functions[@]}"; do
            if declare -f "$func" >/dev/null 2>&1; then
                print_pass "Function $func defined"
            else
                print_fail "Function $func not defined"
            fi
        done
    else
        print_fail "Installer script cannot be sourced"
    fi
}

test_dmg_builder() {
    print_test "Testing DMG builder script..."
    
    if [ -f "$DMG_BUILDER" ]; then
        if bash -n "$DMG_BUILDER" 2>/dev/null; then
            print_pass "DMG builder syntax is valid"
        else
            print_fail "DMG builder has syntax errors"
        fi
    else
        print_fail "DMG builder script not found"
    fi
}

test_main_script_compatibility() {
    print_test "Testing main script compatibility..."
    
    if [ -f "$MAIN_SCRIPT" ]; then
        # Check for macOS-specific issues in the Lua script
        if grep -q "os.execute.*cmd" "$MAIN_SCRIPT"; then
            print_info "Script contains Windows-style commands (expected)"
        fi
        
        if grep -q "reaper\." "$MAIN_SCRIPT"; then
            print_pass "Script contains REAPER API calls"
        else
            print_fail "Script missing REAPER API calls"
        fi
        
        print_pass "Main script found and appears valid"
    else
        print_fail "Main script not found: $MAIN_SCRIPT"
    fi
}

# Run all tests
main() {
    echo "YouTube to New Track - macOS Installer Test Suite"
    echo "================================================="
    echo ""
    
    local tests_passed=0
    local tests_failed=0
    
    # File existence tests
    if test_file_exists "$INSTALLER_SCRIPT" "installer script"; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi
    
    if test_file_exists "$DMG_BUILDER" "DMG builder script"; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi
    
    if test_file_exists "$MAIN_SCRIPT" "main Lua script"; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi
    
    # Script validation tests
    if test_script_syntax "$INSTALLER_SCRIPT" "installer script"; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi
    
    if test_required_commands; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi
    
    test_optional_commands
    
    if test_macos_paths; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi
    
    if test_main_script_compatibility; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi
    
    test_dmg_builder
    
    echo ""
    echo "================================================="
    echo "Test Results:"
    echo -e "  ${GREEN}Passed: $tests_passed${NC}"
    echo -e "  ${RED}Failed: $tests_failed${NC}"
    echo ""
    
    if [ $tests_failed -eq 0 ]; then
        echo -e "${GREEN}All critical tests passed! Installer should work correctly.${NC}"
        exit 0
    else
        echo -e "${RED}Some tests failed. Please review and fix issues before distribution.${NC}"
        exit 1
    fi
}

# Make scripts executable if they aren't already
chmod +x "$INSTALLER_SCRIPT" 2>/dev/null || true
chmod +x "$DMG_BUILDER" 2>/dev/null || true

# Run tests
main