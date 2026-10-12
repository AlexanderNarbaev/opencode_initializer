#!/usr/bin/env bash
set -euo pipefail
# =============================================================================
# Module 52: Program Design
# =============================================================================
# Description: Program design layer - detailed algorithm and data structure design
#              Bridges architecture and implementation with precise specifications
# Source: HumanLayer 4-stage design process
# Status: ACTIVE
# =============================================================================

# NOTE: sourced by setup.sh — set -euo pipefail is idempotent there (setup.sh already strict).


# Guard: only source core/logging when running standalone (avoid double-source under setup.sh)
# ── Idempotent module constants (safe under repeated sourcing) ──
MODULE_52_VERSION="${MODULE_52_VERSION:-"1.0.0"}"
MODULE_52_NAME="${MODULE_52_NAME:-"program-design"}"
MODULE_52_DIR="${MODULE_52_DIR:-"${OPENCODE_ROOT:-$PWD}/.opencode/program-designs"}"

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then

  source "${OPENCODE_ROOT:-$PWD}/src/lib/00-core.sh" || exit 1
  source "${OPENCODE_ROOT:-$PWD}/src/lib/00y-logging.sh" || exit 1
fi

generate_program_design_template() {
    local feature_name="${1:-}"
    local arch_doc_file="${2:-}"
    local output_file="${3:-}"
    
    [[ -z "$feature_name" ]] && { log_error "Feature name required"; return 1; }
    
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local feature_slug=$(echo "$feature_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g')
    
    local arch_ref=""
    [[ -n "$arch_doc_file" && -f "$arch_doc_file" ]] && arch_ref="spec://architecture-doc/$(basename "$arch_doc_file" .md)"
    
    cat > "${output_file:-${MODULE_52_DIR}/${feature_slug}.md}" << EOF
# Program Design: ${feature_name}

**Status:** DRAFT  
**Created:** ${timestamp}  
**Author:** \${USER:-unknown}  
**Reviewers:** [TBD]  
**Architecture Doc:** ${arch_ref:-[Link to approved architecture doc]}  

---

## 1. Overview

### 1.1 Purpose
<!-- What this program design covers -->


### 1.2 Scope
<!-- In-scope and out-of-scope components -->


### 1.3 Definitions & Acronyms
| Term | Definition |
|------|------------|
| | |

---

## 2. Algorithm Design

### 2.1 Core Algorithms

#### Algorithm 2.1.1: [Algorithm Name]
**Purpose:** [Single responsibility]

**Pseudocode:**
\`\`\`
function algorithmName(input):
    // Step 1: Validation
    if input is invalid:
        return error
    
    // Step 2: Processing
    result = transform(input)
    
    // Step 3: Output
    return result
\`\`\`

**Time Complexity:** O(?)  
**Space Complexity:** O(?)  

**Edge Cases:**
- 
- 

#### Algorithm 2.1.2: [Algorithm Name]


### 2.2 Decision Logic

\`\`\`mermaid
flowchart TD
    A[Start] --> B{Condition?}
    B -->|Yes| C[Action 1]
    B -->|No| D[Action 2]
    C --> E[End]
    D --> E
\`\`\`

---

## 3. Data Structures

### 3.1 Primary Data Structures

#### Structure 3.1.1: [Structure Name]
**Purpose:** [Why this structure]

**Definition:**
\`\`\`typescript
interface DataStructure {
  id: string;
  name: string;
  metadata: Record<string, any>;
  createdAt: Date;
  updatedAt?: Date;
}
\`\`\`

**Invariants:**
- 
- 

**Operations:**
| Operation | Complexity | Description |
|-----------|------------|-------------|
| insert | O(?) | |
| delete | O(?) | |
| search | O(?) | |

### 3.2 Caching Strategy
<!-- What to cache, eviction policy, invalidation -->


---

## 4. Interface Specifications

### 4.1 Function Signatures
\`\`\`typescript
// Core function
export function processData(
  input: InputType,
  options?: ProcessOptions
): Promise<ResultType>;

// Helper functions
export function validateInput(input: unknown): asserts input is InputType;
export function transformData(data: InputType): TransformedType;
\`\`\`

### 4.2 Class Designs
\`\`\`typescript
export class Processor {
  private cache: Cache;
  private logger: Logger;
  
  constructor(config: ProcessorConfig);
  
  public async process(input: InputType): Promise<ResultType>;
  public validate(): boolean;
}
\`\`\`

### 4.3 Error Handling Strategy
| Error Type | Handling Strategy | Recovery Action |
|------------|-------------------|-----------------|
| ValidationError | Return immediately | Log and notify user |
| NetworkError | Retry with backoff | Circuit breaker |
| DatabaseError | Transaction rollback | Alert on-call |

---

## 5. State Management

### 5.1 State Diagram

\`\`\`mermaid
stateDiagram-v2
    [*] --> Idle
    Idle --> Processing: Start
    Processing --> Validating: Validate
    Validating --> Processing: Invalid
    Validating --> Saving: Valid
    Saving --> [*]: Complete
    Processing --> Error: Fail
    Error --> [*]: Handle
\`\`\`

### 5.2 State Transitions
| From State | To State | Trigger | Guard Condition |
|------------|----------|---------|-----------------|
| Idle | Processing | User action | Input valid |
| Processing | Validating | Validation start | |

---

## 6. Concurrency Model

### 6.1 Threading Strategy
<!-- Single-threaded, multi-threaded, async/await -->


### 6.2 Synchronization Primitives
<!-- Locks, semaphores, channels -->


### 6.3 Race Condition Prevention
<!-- How race conditions are avoided -->


---

## 7. Performance Considerations

### 7.1 Bottleneck Analysis
<!-- Known or potential bottlenecks -->


### 7.2 Optimization Opportunities
| Area | Current | Optimized | Effort |
|------|---------|-----------|--------|
| | | | |

### 7.3 Memory Management
<!-- Allocation, deallocation, GC considerations -->


---

## 8. Testing Strategy

### 8.1 Unit Tests
| Function | Test Cases | Edge Cases | Mock Dependencies |
|----------|------------|------------|-------------------|
| | | | |

### 8.2 Integration Tests
<!-- Component interaction tests -->


### 8.3 Property-Based Tests
<!-- Invariants to test -->


---

## 9. Implementation Plan

### 9.1 Phase 1: Foundation
- [ ] Task 1
- [ ] Task 2

### 9.2 Phase 2: Core Logic
- [ ] Task 3
- [ ] Task 4

### 9.3 Phase 3: Integration
- [ ] Task 5
- [ ] Task 6

---

## 10. References

- Architecture Doc: \`spec://architecture-doc/[slug]\`
- Product Review: \`spec://product-review/[slug]\`
- Related ADRs: \`docs/architecture/adr-*.md\`

---

*HumanLayer Stage 3: Program Design  
Next: Vertical Slices (Module 53)*
EOF
    
    log_info "Program design created: ${output_file:-${MODULE_52_DIR}/${feature_slug}.md}"
}

cmd_program_design_create() {
    local feature_name="${1:-}"
    local arch_doc_file="${2:-}"
    local output_file="${3:-}"
    
    [[ -z "$feature_name" ]] && { log_error "Usage: opencode program-design create <feature-name> [arch-doc] [output]"; return 1; }
    
    mkdir -p "$MODULE_52_DIR"
    generate_program_design_template "$feature_name" "$arch_doc_file" "$output_file"
}

cmd_program_design_list() {
    [[ ! -d "$MODULE_52_DIR" ]] && { log_info "No program designs found"; return 0; }
    
    log_info "Program Designs:"
    find "$MODULE_52_DIR" -name "*.md" -type f -exec basename {} .md \;
}

main_program_design() {
    local cmd="${1:-help}"
    shift || true
    
    case "$cmd" in
        create) cmd_program_design_create "$@" ;;
        list) cmd_program_design_list "$@" ;;
        help|--help|-h)
            cat << EOF
Program Design Module (v$MODULE_52_VERSION)

Usage: opencode program-design <command> [options]

Commands:
  create <feature> [arch-doc] [output]  Create program design
  list                                  List all program designs
  help                                  Show help

Source: HumanLayer 4-stage design process - Stage 3
EOF
            ;;
        *) log_error "Unknown: $cmd"; return 1 ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_program_design "$@"
fi

