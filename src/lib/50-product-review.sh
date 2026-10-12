#!/usr/bin/env bash
set -euo pipefail
# =============================================================================
# Module 50: Product Review
# =============================================================================
# Description: Product review layer for AI-assisted development
#              Captures business goals, success metrics, user personas, and problem statements
#              Before any code is written, ensure product thinking is documented
# Source: HumanLayer 4-stage design process
# Status: ACTIVE
# Dependencies: 00-core.sh, 05-logging.sh
# =============================================================================

# NOTE: sourced by setup.sh — set -euo pipefail is idempotent there (setup.sh already strict).

# Module metadata

# Import dependencies
# shellcheck source=/dev/null
# Guard: only source core/logging when running standalone (avoid double-source under setup.sh)
# ── Idempotent module constants (safe under repeated sourcing) ──
MODULE_50_VERSION="${MODULE_50_VERSION:-"1.0.0"}"
MODULE_50_NAME="${MODULE_50_NAME:-"product-review"}"
MODULE_50_DIR="${MODULE_50_DIR:-"${OPENCODE_ROOT:-$PWD}/.opencode/product-reviews"}"
MODULE_50_TEMPLATE_DIR="${MODULE_50_TEMPLATE_DIR:-"${OPENCODE_ROOT:-$PWD}/src/templates/product-review"}"

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then

  source "${OPENCODE_ROOT:-$PWD}/src/lib/00-core.sh" || { echo "ERROR: Cannot load core"; exit 1; }
# shellcheck source=/dev/null
  source "${OPENCODE_ROOT:-$PWD}/src/lib/00y-logging.sh" || { echo "ERROR: Cannot load logging"; exit 1; }
fi

# =============================================================================
# Product Review Template
# =============================================================================
generate_product_review_template() {
    local feature_name="${1:-}"
    local output_file="${2:-}"
    
    if [[ -z "$feature_name" ]]; then
        log_error "Feature name is required"
        return 1
    fi
    
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local feature_slug
    feature_slug=$(echo "$feature_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g')
    
    cat > "${output_file:-${MODULE_50_DIR}/${feature_slug}.md}" << EOF
# Product Review: ${feature_name}

**Status:** DRAFT  
**Created:** ${timestamp}  
**Author:** \${USER:-unknown}  
**Reviewers:** [TBD]  
**Target Wave:** [TBD]

---

## 1. Problem Statement

### 1.1 What problem are we solving?
<!-- Describe the user pain point or business opportunity in 2-3 sentences -->


### 1.2 Who experiences this problem?
<!-- Define user personas affected by this problem -->


### 1.3 Current workarounds
<!-- How do users solve this problem today? -->


---

## 2. Business Goals

### 2.1 Primary Goal
<!-- Single most important outcome -->


### 2.2 Secondary Goals
<!-- Additional benefits -->
- 
- 
- 

### 2.3 Non-Goals
<!-- What we are explicitly NOT solving -->
- 
- 

---

## 3. Success Metrics

### 3.1 Key Performance Indicators (KPIs)
| Metric | Baseline | Target | Measurement Method |
|--------|----------|--------|-------------------|
| [Metric 1] | [Current] | [Target] | [How to measure] |
| [Metric 2] | [Current] | [Target] | [How to measure] |

### 3.2 Leading Indicators
<!-- Early signals of success -->
- 
- 

### 3.3 Lagging Indicators
<!-- Long-term outcomes -->
- 
- 

---

## 4. User Personas

### Persona 1: [Name]
- **Role:** [Job title/function]
- **Goals:** [What they want to achieve]
- **Frustrations:** [Current pain points]
- **Technical Level:** [Beginner/Intermediate/Advanced]

### Persona 2: [Name]
- **Role:** [Job title/function]
- **Goals:** [What they want to achieve]
- **Frustrations:** [Current pain points]
- **Technical Level:** [Beginner/Intermediate/Advanced]

---

## 5. User Stories

### US-001: [Story Title]
**As a** [persona],  
**I want to** [action],  
**So that** [benefit].

**Acceptance Criteria:**
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

**Priority:** Must have / Should have / Could have / Won't have  
**Effort Estimate:** [S/M/L/XL]  
**Dependencies:** [List any]

### US-002: [Story Title]
**As a** [persona],  
**I want to** [action],  
**So that** [benefit].

**Acceptance Criteria:**
- [ ] Criterion 1
- [ ] Criterion 2

---

## 6. Competitive Analysis

### 6.1 Existing Solutions
| Solution | Strengths | Weaknesses | Our Differentiation |
|----------|-----------|------------|---------------------|
| [Competitor 1] | | | |
| [Competitor 2] | | | |

### 6.2 Why Now?
<!-- Why is this the right time to build this? -->


---

## 7. Risks & Assumptions

### 7.1 Key Assumptions
<!-- What must be true for this to succeed? -->
- [ ] Assumption 1
- [ ] Assumption 2
- [ ] Assumption 3

### 7.2 Risks
| Risk | Probability | Impact | Mitigation Strategy |
|------|-------------|--------|---------------------|
| [Risk 1] | Low/Med/High | Low/Med/High | [How to mitigate] |
| [Risk 2] | Low/Med/High | Low/Med/High | [How to mitigate] |

---

## 8. Go-to-Market Considerations

### 8.1 Distribution Channels
<!-- How will users discover this? -->
- 
- 

### 8.2 Pricing/Packaging (if applicable)
<!-- Monetization strategy -->


---

## 9. Approval & Sign-off

### 9.1 Required Reviewers
- [ ] Product Manager
- [ ] Engineering Lead
- [ ] Design Lead
- [ ] Security Review (if applicable)
- [ ] Compliance Review (if applicable)

### 9.2 Approval Date
<!-- Date when product review was approved -->


---

## 10. Appendix

### 10.1 Research Data
<!-- Links to user research, surveys, data analysis -->


### 10.2 Related Documents
<!-- Links to architecture doc, program design, etc. -->
- Architecture Doc: \`spec://architecture/[feature-slug]\`
- Program Design: \`spec://program-design/[feature-slug]\`
- Vertical Slices: \`spec://vertical-slices/[feature-slug]\`

---

*This document follows the HumanLayer 4-stage design process.  
Next step: Create Architecture Documentation (Module 51)*
EOF

    log_info "Product review template created: ${output_file:-${MODULE_50_DIR}/${feature_slug}.md}"
}

# =============================================================================
# Product Review Commands
# =============================================================================

cmd_product_review_create() {
    local feature_name="${1:-}"
    local output_file="${2:-}"
    
    if [[ -z "$feature_name" ]]; then
        log_error "Usage: opencode product-review create <feature-name> [output-file]"
        return 1
    fi
    
    mkdir -p "$MODULE_50_DIR"
    generate_product_review_template "$feature_name" "$output_file"
}

cmd_product_review_list() {
    if [[ ! -d "$MODULE_50_DIR" ]]; then
        log_info "No product reviews found. Create one with: opencode product-review create <feature-name>"
        return 0
    fi
    
    log_info "Product Reviews in $MODULE_50_DIR:"
    echo ""
    find "$MODULE_50_DIR" -name "*.md" -type f | while read -r file; do
        local status
        status=$(grep -m1 "^\\*\\*Status:\\*\\*" "$file" 2>/dev/null | cut -d':' -f2 | tr -d '*' | xargs || echo "UNKNOWN")
        local author
        author=$(grep -m1 "^\\*\\*Author:\\*\\*" "$file" 2>/dev/null | cut -d':' -f2 | tr -d '*' | xargs || echo "UNKNOWN")
        local created
        created=$(grep -m1 "^\\*\\*Created:\\*\\*" "$file" 2>/dev/null | cut -d':' -f2 | tr -d '*' | xargs || echo "UNKNOWN")
        
        printf "%-40s | Status: %-10s | Author: %-15s | Created: %s\n" \
            "$(basename "$file" .md)" "$status" "$author" "$created"
    done
}

cmd_product_review_validate() {
    local file="${1:-}"
    
    if [[ -z "$file" ]]; then
        log_error "Usage: opencode product-review validate <file>"
        return 1
    fi
    
    if [[ ! -f "$file" ]]; then
        log_error "File not found: $file"
        return 1
    fi
    
    local errors=0
    local warnings=0
    
    # Check required sections
    local required_sections=(
        "Problem Statement"
        "Business Goals"
        "Success Metrics"
        "User Personas"
        "User Stories"
        "Risks & Assumptions"
    )
    
    for section in "${required_sections[@]}"; do
        if ! grep -q "## [0-9]*\\. $section" "$file"; then
            log_error "Missing required section: $section"
            ((errors++))
        fi
    done
    
    # Check for empty acceptance criteria
    local ac_count
    ac_count=$(grep -c "Acceptance Criteria:" "$file" || echo 0)
    local checkbox_count
    checkbox_count=$(grep -c "\\- \\[ \\]" "$file" || echo 0)
    
    if [[ $ac_count -gt 0 && $checkbox_count -eq 0 ]]; then
        log_warning "User stories found but no acceptance criteria defined"
        ((warnings++))
    fi
    
    # Check for missing metrics
    if ! grep -q "| Metric |" "$file"; then
        log_warning "No KPI table found - success metrics may be undefined"
        ((warnings++))
    fi
    
    # Check approval status
    if grep -q "\\*\\*Status:\\*\\* DRAFT" "$file"; then
        log_warning "Product review is still in DRAFT status"
        ((warnings++))
    fi
    
    echo ""
    log_info "Validation complete: $errors errors, $warnings warnings"
    
    if [[ $errors -gt 0 ]]; then
        return 1
    elif [[ $warnings -gt 0 ]]; then
        return 2  # Warnings only
    else
        log_success "Product review is complete and ready for approval"
        return 0
    fi
}

cmd_product_review_approve() {
    local file="${1:-}"
    
    if [[ -z "$file" ]]; then
        log_error "Usage: opencode product-review approve <file>"
        return 1
    fi
    
    if [[ ! -f "$file" ]]; then
        log_error "File not found: $file"
        return 1
    fi
    
    # Validate first
    if ! cmd_product_review_validate "$file"; then
        log_error "Cannot approve product review with validation errors"
        return 1
    fi
    
    # Update status
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    sed -i "s/^\\*\\*Status:\\*\\* .*/\\*\\*Status:\\*\\* APPROVED/" "$file"
    sed -i "s/^\\*\\*Approval Date\\*\\*.*/\\*\\*Approval Date\\*\\* $timestamp/" "$file"
    
    log_success "Product review approved: $file"
    
    # Log to audit trail
    if command -v wal_write_atomic &>/dev/null; then
        wal_write_atomic "PRODUCT_REVIEW_APPROVED" "{\"file\": \"$file\", \"timestamp\": \"$timestamp\"}"
    fi
}

cmd_product_review_export_json() {
    local file="${1:-}"
    
    if [[ -z "$file" ]]; then
        log_error "Usage: opencode product-review export-json <file>"
        return 1
    fi
    
    if [[ ! -f "$file" ]]; then
        log_error "File not found: $file"
        return 1
    fi
    
    # Extract key fields (simplified parsing)
    local feature_name
    feature_name=$(head -1 "$file" | sed 's/# Product Review: //')
    local status
    status=$(grep -m1 "^\\*\\*Status:\\*\\*" "$file" | cut -d':' -f2 | tr -d '*' | xargs)
    local author
    author=$(grep -m1 "^\\*\\*Author:\\*\\*" "$file" | cut -d':' -f2 | tr -d '*' | xargs)
    local created
    created=$(grep -m1 "^\\*\\*Created:\\*\\*" "$file" | cut -d':' -f2 | tr -d '*' | xargs)
    
    # Count user stories
    local story_count
    story_count=$(grep -c "^### US-[0-9]*:" "$file" || echo 0)
    
    # Output JSON
    cat << EOF
{
  "feature_name": "$feature_name",
  "status": "$status",
  "author": "$author",
  "created": "$created",
  "user_stories_count": $story_count,
  "file_path": "$file",
  "module_version": "$MODULE_50_VERSION"
}
EOF
}

# =============================================================================
# Main Entry Point
# =============================================================================

main_product_review() {
    local command="${1:-help}"
    shift || true
    
    case "$command" in
        create)
            cmd_product_review_create "$@"
            ;;
        list)
            cmd_product_review_list "$@"
            ;;
        validate)
            cmd_product_review_validate "$@"
            ;;
        approve)
            cmd_product_review_approve "$@"
            ;;
        export-json)
            cmd_product_review_export_json "$@"
            ;;
        help|--help|-h)
            cat << EOF
Product Review Module (v$MODULE_50_VERSION)

Usage: opencode product-review <command> [options]

Commands:
  create <feature-name> [output-file]   Create new product review from template
  list                                  List all product reviews
  validate <file>                       Validate product review completeness
  approve <file>                        Approve product review (after validation)
  export-json <file>                    Export product review metadata as JSON
  help                                  Show this help message

Examples:
  opencode product-review create "AI Code Review Assistant"
  opencode product-review list
  opencode product-review validate .opencode/product-reviews/ai-code-review.md
  opencode product-review approve .opencode/product-reviews/ai-code-review.md
  opencode product-review export-json .opencode/product-reviews/ai-code-review.md

Source: HumanLayer 4-stage design process - Stage 1: Product Review
Next: Architecture Documentation (opencode architecture-doc create)
EOF
            ;;
        *)
            log_error "Unknown command: $command"
            echo "Run 'opencode product-review help' for usage"
            return 1
            ;;
    esac
}

# Auto-execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_product_review "$@"
fi
