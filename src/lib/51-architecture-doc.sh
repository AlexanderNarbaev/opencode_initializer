#!/usr/bin/env bash
set -euo pipefail
# =============================================================================
# Module 51: Architecture Documentation
# =============================================================================
# Description: Architecture documentation layer for AI-assisted development
#              Captures system design, component interactions, data flows, and technical decisions
#              Ensures architectural thinking is documented before implementation
# Source: HumanLayer 4-stage design process
# Status: ACTIVE
# Dependencies: 00-core.sh, 05-logging.sh, 50-product-review.sh
# =============================================================================

# NOTE: sourced by setup.sh — set -euo pipefail is idempotent there (setup.sh already strict).

# Module metadata

# Import dependencies
# shellcheck source=/dev/null
# Guard: only source core/logging when running standalone (avoid double-source under setup.sh)
# ── Idempotent module constants (safe under repeated sourcing) ──
MODULE_51_VERSION="${MODULE_51_VERSION:-"1.0.0"}"
MODULE_51_NAME="${MODULE_51_NAME:-"architecture-doc"}"
MODULE_51_DIR="${MODULE_51_DIR:-"${OPENCODE_ROOT:-$PWD}/.opencode/architecture-docs"}"
MODULE_51_TEMPLATE_DIR="${MODULE_51_TEMPLATE_DIR:-"${OPENCODE_ROOT:-$PWD}/src/templates/architecture-doc"}"

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then

  source "${OPENCODE_ROOT:-$PWD}/src/lib/00-core.sh" || { echo "ERROR: Cannot load core"; exit 1; }
# shellcheck source=/dev/null
  source "${OPENCODE_ROOT:-$PWD}/src/lib/00y-logging.sh" || { echo "ERROR: Cannot load logging"; exit 1; }
fi

# =============================================================================
# Architecture Documentation Template
# =============================================================================
generate_architecture_doc_template() {
    local feature_name="${1:-}"
    local product_review_file="${2:-}"
    local output_file="${3:-}"
    
    if [[ -z "$feature_name" ]]; then
        log_error "Feature name is required"
        return 1
    fi
    
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local feature_slug
    feature_slug=$(echo "$feature_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g')
    
    # Extract product review reference if provided
    local pr_ref=""
    if [[ -n "$product_review_file" && -f "$product_review_file" ]]; then
        pr_ref="spec://product-review/$(basename "$product_review_file" .md)"
    fi
    
    cat > "${output_file:-${MODULE_51_DIR}/${feature_slug}.md}" << EOF
# Architecture Documentation: ${feature_name}

**Status:** DRAFT  
**Created:** ${timestamp}  
**Author:** \${USER:-unknown}  
**Reviewers:** [TBD]  
**Product Review:** ${pr_ref:-[Link to approved product review]}  
**Target Wave:** [TBD]

---

## 1. Executive Summary

### 1.1 Architecture Overview
<!-- 2-3 sentence summary of the proposed architecture -->


### 1.2 Key Architectural Decisions
<!-- List the most important architectural choices -->
1. 
2. 
3. 

### 1.3 Alternatives Considered
<!-- Briefly mention rejected alternatives -->
- 
- 

---

## 2. System Context

### 2.1 System Context Diagram
<!-- Describe how this system fits into the broader ecosystem -->

\`\`\`mermaid
C4Context
    title System Context Diagram: ${feature_name}
    
    Person(user, "User", "[Persona from product review]")
    System_Boundary(system_boundary, "${feature_name}") {
        System(system, "System", "[Description]")
    }
    
    Ext_System_Ext(external_system, "External System", "[Description]")
    
    Rel(user, system, "Uses", "HTTPS/API")
    Rel(system, external_system, "Integrates with", "API/RPC")
\`\`\`

### 2.2 Stakeholders
| Role | Name/Team | Responsibilities | Concerns |
|------|-----------|------------------|----------|
| [Role 1] | [Team/Person] | [What they do] | [What they care about] |
| [Role 2] | [Team/Person] | [What they do] | [What they care about] |

---

## 3. Architecture Goals & Constraints

### 3.1 Goals (from Product Review)
<!-- Link to success metrics in product review -->
- **Goal 1:** [From product review]
- **Goal 2:** [From product review]
- **Goal 3:** [From product review]

### 3.2 Quality Attributes
| Attribute | Priority | Target | Measurement |
|-----------|----------|--------|-------------|
| Performance | High/Med/Low | [e.g., <100ms p95] | [How to measure] |
| Scalability | High/Med/Low | [e.g., 10K RPS] | [How to measure] |
| Availability | High/Med/Low | [e.g., 99.9%] | [How to measure] |
| Security | High/Med/Low | [e.g., SOC2 compliant] | [How to measure] |
| Maintainability | High/Med/Low | [e.g., test coverage >80%] | [How to measure] |

### 3.3 Constraints
<!-- Technical, business, or regulatory constraints -->
- **Technical:** [e.g., Must use PostgreSQL]
- **Business:** [e.g., Budget limit \$X/month]
- **Regulatory:** [e.g., GDPR compliance required]

---

## 4. Container Level Architecture

### 4.1 Container Diagram
<!-- Show major technology choices and component interactions -->

\`\`\`mermaid
C4Container
    title Container Diagram: ${feature_name}
    
    Container_Boundary(boundary, "${feature_name}") {
        Container(web_app, "Web Application", "React/TypeScript", "Handles UI and user interactions")
        Container(api, "API Service", "Node.js/Python", "Business logic and API endpoints")
        Container(db, "Database", "PostgreSQL", "Persistent data storage")
        Container(cache, "Cache", "Redis", "Session and query caching")
    }
    
    Rel(web_app, api, "Calls", "HTTPS/REST")
    Rel(api, db, "Reads/Writes", "SQL")
    Rel(api, cache, "Reads/Writes", "Redis Protocol")
\`\`\`

### 4.2 Technology Choices
| Component | Technology | Rationale | Alternatives Considered |
|-----------|------------|-----------|------------------------|
| Frontend | [e.g., React] | [Why chosen] | [Vue, Svelte, etc.] |
| Backend | [e.g., Node.js] | [Why chosen] | [Python, Go, etc.] |
| Database | [e.g., PostgreSQL] | [Why chosen] | [MongoDB, MySQL, etc.] |
| Cache | [e.g., Redis] | [Why chosen] | [Memcached, etc.] |

### 4.3 Infrastructure
<!-- Deployment topology and infrastructure components -->
- **Compute:** [e.g., Kubernetes, ECS, VMs]
- **Storage:** [e.g., S3, EBS, local SSD]
- **Network:** [e.g., VPC, load balancers, CDN]
- **Monitoring:** [e.g., Prometheus, Grafana, DataDog]

---

## 5. Component Level Design

### 5.1 Core Components

#### Component 5.1.1: [Component Name]
**Responsibility:** [Single responsibility statement]

**Interfaces:**
- Input: [API endpoints, events, messages]
- Output: [Data stores, external services, events]

**Dependencies:**
- [Dependency 1]
- [Dependency 2]

**Key Algorithms/Data Structures:**
<!-- If applicable -->


#### Component 5.1.2: [Component Name]
**Responsibility:** [Single responsibility statement]


### 5.2 Component Interactions

\`\`\`mermaid
sequenceDiagram
    participant User
    participant WebApp as Web Application
    participant API as API Service
    participant DB as Database
    participant Cache as Redis Cache
    
    User->>WebApp: Action
    WebApp->>API: API Request
    API->>Cache: Check Cache
    alt Cache Hit
        Cache-->>API: Cached Data
    else Cache Miss
        API->>DB: Query
        DB-->>API: Result
        API->>Cache: Store in Cache
    end
    API-->>WebApp: Response
    WebApp-->>User: UI Update
\`\`\`

---

## 6. Data Architecture

### 6.1 Data Model
<!-- Entity relationship diagram or schema overview -->

\`\`\`mermaid
erDiagram
    ENTITY1 {
        string id PK
        string name
        timestamp created_at
    }
    
    ENTITY2 {
        string id PK
        string entity1_id FK
        string value
    }
    
    ENTITY1 ||--o{ ENTITY2 : contains
\`\`\`

### 6.2 Data Flow
<!-- How data moves through the system -->

\`\`\`mermaid
flowchart LR
    A[User Input] --> B[Validation]
    B --> C[Transformation]
    C --> D[(Database)]
    C --> E[Cache]
    D --> F[Analytics]
    E --> G[API Response]
\`\`\`

### 6.3 Data Retention & Compliance
| Data Type | Retention Period | Storage Location | Compliance Requirements |
|-----------|------------------|------------------|------------------------|
| [Type 1] | [e.g., 90 days] | [Location] | [GDPR, SOC2, etc.] |
| [Type 2] | [e.g., 7 years] | [Location] | [Compliance] |

---

## 7. API Design

### 7.1 REST Endpoints (if applicable)
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | \`/api/v1/resource\` | List resources | Yes |
| POST | \`/api/v1/resource\` | Create resource | Yes |
| PUT | \`/api/v1/resource/:id\` | Update resource | Yes |
| DELETE | \`/api/v1/resource/:id\` | Delete resource | Yes |

### 7.2 GraphQL Schema (if applicable)
\`\`\`graphql
type Resource {
  id: ID!
  name: String!
  createdAt: DateTime!
  updatedAt: DateTime
}

type Query {
  resources(limit: Int, offset: Int): [Resource!]!
  resource(id: ID!): Resource
}

type Mutation {
  createResource(input: ResourceInput!): Resource!
  updateResource(id: ID!, input: ResourceInput!): Resource
  deleteResource(id: ID!): Boolean!
}
\`\`\`

### 7.3 Event Schema (if applicable)
\`\`\`json
{
  "event_type": "resource.created",
  "timestamp": "2026-01-01T00:00:00Z",
  "data": {
    "id": "uuid",
    "name": "string"
  },
  "metadata": {
    "user_id": "uuid",
    "correlation_id": "uuid"
  }
}
\`\`\`

---

## 8. Security Architecture

### 8.1 Threat Model
| Threat | Likelihood | Impact | Mitigation |
|--------|------------|--------|------------|
| Unauthorized access | Medium | High | RBAC, MFA |
| Data breach | Low | Critical | Encryption at rest/transit |
| DDoS attack | Medium | Medium | Rate limiting, CDN |
| Injection attacks | Medium | High | Input validation, parameterized queries |

### 8.2 Authentication & Authorization
- **Authentication:** [e.g., OAuth2/OIDC, JWT, API keys]
- **Authorization:** [e.g., RBAC, ABAC, ACLs]
- **Session Management:** [e.g., Stateless JWT, Redis sessions]

### 8.3 Data Protection
- **Encryption in Transit:** TLS 1.3
- **Encryption at Rest:** AES-256
- **PII Handling:** [Strategy for sensitive data]
- **Secrets Management:** [e.g., HashiCorp Vault, AWS Secrets Manager]

---

## 9. Scalability & Performance

### 9.1 Scaling Strategy
- **Horizontal Scaling:** [How to add more instances]
- **Vertical Scaling:** [When to upgrade hardware]
- **Database Scaling:** [Read replicas, sharding strategy]
- **Caching Strategy:** [CDN, application cache, database cache]

### 9.2 Performance Targets
| Metric | Target | Current Baseline | Measurement Method |
|--------|--------|------------------|-------------------|
| Latency (p50) | <50ms | [Baseline] | Prometheus/Datadog |
| Latency (p95) | <100ms | [Baseline] | Prometheus/Datadog |
| Latency (p99) | <200ms | [Baseline] | Prometheus/Datadog |
| Throughput | 1000 RPS | [Baseline] | Load testing |
| Error Rate | <0.1% | [Baseline] | Monitoring |

### 9.3 Bottleneck Analysis
<!-- Known or potential bottlenecks -->
- [Bottleneck 1]: [Mitigation strategy]
- [Bottleneck 2]: [Mitigation strategy]

---

## 10. Observability

### 10.1 Logging Strategy
- **Log Format:** JSON structured logging
- **Log Levels:** DEBUG, INFO, WARN, ERROR, FATAL
- **Aggregation:** [e.g., ELK Stack, Splunk, DataDog]
- **Retention:** [e.g., 30 days hot, 90 days cold]

### 10.2 Metrics
| Metric Name | Type | Description | Alert Threshold |
|-------------|------|-------------|-----------------|
| http_request_duration_seconds | Histogram | Request latency | p95 > 100ms |
| http_requests_total | Counter | Total requests | Error rate > 1% |
| db_connection_pool_size | Gauge | Active connections | > 80% capacity |

### 10.3 Tracing
- **Distributed Tracing:** [e.g., Jaeger, Zipkin, Honeycomb]
- **Sampling Rate:** [e.g., 10% for production]
- **Span Attributes:** [Key attributes to track]

### 10.4 Alerting
| Alert Name | Condition | Severity | Runbook |
|------------|-----------|----------|---------|
| HighErrorRate | error_rate > 1% for 5m | P1 | [Link] |
| HighLatency | p95_latency > 200ms for 10m | P2 | [Link] |
| LowDiskSpace | disk_usage > 85% | P3 | [Link] |

---

## 11. Deployment Architecture

### 11.1 Deployment Pipeline
\`\`\`mermaid
flowchart LR
    A[Code Commit] --> B[CI Build]
    B --> C[Unit Tests]
    C --> D[Integration Tests]
    D --> E[Build Docker Image]
    E --> F[Push to Registry]
    F --> G[Deploy to Staging]
    G --> H[E2E Tests]
    H --> I[Manual Approval]
    I --> J[Deploy to Production]
    J --> K[Canary Release]
    K --> L[Full Rollout]
\`\`\`

### 11.2 Environment Strategy
| Environment | Purpose | Update Frequency | Access |
|-------------|---------|------------------|--------|
| Development | Local development | On-demand | Developers |
| Staging | Pre-production testing | Per PR | QA, Devs |
| Production | Live traffic | Weekly/Bi-weekly | Restricted |

### 11.3 Disaster Recovery
- **RTO (Recovery Time Objective):** [e.g., < 1 hour]
- **RPO (Recovery Point Objective):** [e.g., < 5 minutes]
- **Backup Strategy:** [e.g., Daily snapshots, continuous replication]
- **Failover Strategy:** [e.g., Multi-AZ, multi-region]

---

## 12. Architectural Decision Records (ADRs)

### ADR-001: [Decision Title]
**Status:** Accepted / Proposed / Deprecated  
**Context:** [Why this decision was needed]  
**Decision:** [What was decided]  
**Consequences:** [Positive and negative outcomes]  
**Related ADRs:** [Links to other ADRs]

### ADR-002: [Decision Title]
**Status:** [Status]  


---

## 13. Open Questions & Risks

### 13.1 Open Questions
<!-- Unresolved architectural questions -->
- [ ] Question 1
- [ ] Question 2

### 13.2 Technical Risks
| Risk | Probability | Impact | Mitigation Plan | Owner |
|------|-------------|--------|-----------------|-------|
| [Risk 1] | Low/Med/High | Low/Med/High | [Plan] | [Owner] |
| [Risk 2] | Low/Med/High | Low/Med/High | [Plan] | [Owner] |

---

## 14. Appendix

### 14.1 Glossary
| Term | Definition |
|------|------------|
| [Term 1] | [Definition] |
| [Term 2] | [Definition] |

### 14.2 References
- Product Review: \`spec://product-review/[feature-slug]\`
- Program Design: \`spec://program-design/[feature-slug]\` (to be created)
- Vertical Slices: \`spec://vertical-slices/[feature-slug]\` (to be created)
- Related ADRs: \`docs/architecture/adr-*.md\`

### 14.3 Diagrams Source
<!-- Links to editable diagram sources (e.g., Mermaid, Draw.io) -->


---

*This document follows the HumanLayer 4-stage design process.  
Stage 2: Architecture Documentation  
Next: Program Design (Module 52)*

**Approval Checklist:**
- [ ] Architecture aligns with product goals
- [ ] Quality attributes are measurable
- [ ] Security threats are addressed
- [ ] Scalability plan is documented
- [ ] Observability strategy is defined
- [ ] Deployment pipeline is automated
- [ ] ADRs capture key decisions
EOF

    log_info "Architecture doc template created: ${output_file:-${MODULE_51_DIR}/${feature_slug}.md}"
}

# =============================================================================
# Architecture Doc Commands
# =============================================================================

cmd_architecture_doc_create() {
    local feature_name="${1:-}"
    local product_review_file="${2:-}"
    local output_file="${3:-}"
    
    if [[ -z "$feature_name" ]]; then
        log_error "Usage: opencode architecture-doc create <feature-name> [product-review-file] [output-file]"
        return 1
    fi
    
    mkdir -p "$MODULE_51_DIR"
    generate_architecture_doc_template "$feature_name" "$product_review_file" "$output_file"
}

cmd_architecture_doc_list() {
    if [[ ! -d "$MODULE_51_DIR" ]]; then
        log_info "No architecture docs found. Create one with: opencode architecture-doc create <feature-name>"
        return 0
    fi
    
    log_info "Architecture Docs in $MODULE_51_DIR:"
    echo ""
    find "$MODULE_51_DIR" -name "*.md" -type f | while read -r file; do
        local status
        status=$(grep -m1 "^\\*\\*Status:\\*\\*" "$file" 2>/dev/null | cut -d':' -f2 | tr -d '*' | xargs || echo "UNKNOWN")
        local author
        author=$(grep -m1 "^\\*\\*Author:\\*\\*" "$file" 2>/dev/null | cut -d':' -f2 | tr -d '*' | xargs || echo "UNKNOWN")
        local pr_ref
        pr_ref=$(grep -m1 "^\\*\\*Product Review:\\*\\*" "$file" 2>/dev/null | cut -d':' -f2 | tr -d '*' | xargs || echo "NONE")
        
        printf "%-40s | Status: %-10s | Author: %-15s | Product Review: %s\n" \
            "$(basename "$file" .md)" "$status" "$author" "$pr_ref"
    done
}

cmd_architecture_doc_validate() {
    local file="${1:-}"
    
    if [[ -z "$file" ]]; then
        log_error "Usage: opencode architecture-doc validate <file>"
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
        "Executive Summary"
        "System Context"
        "Architecture Goals"
        "Container Level Architecture"
        "Component Level Design"
        "Data Architecture"
        "Security Architecture"
        "Observability"
        "Deployment Architecture"
    )
    
    for section in "${required_sections[@]}"; do
        if ! grep -q "## [0-9]*\\. $section" "$file"; then
            log_error "Missing required section: $section"
            ((errors++))
        fi
    done
    
    # Check for mermaid diagrams
    local diagram_count
    diagram_count=$(grep -c "\`\`\`mermaid" "$file" || echo 0)
    if [[ $diagram_count -lt 3 ]]; then
        log_warning "Less than 3 diagrams found - consider adding more visualizations"
        ((warnings++))
    fi
    
    # Check for ADRs
    if ! grep -q "### ADR-[0-9]*:" "$file"; then
        log_warning "No architectural decision records found"
        ((warnings++))
    fi
    
    # Check approval status
    if grep -q "\\*\\*Status:\\*\\* DRAFT" "$file"; then
        log_warning "Architecture doc is still in DRAFT status"
        ((warnings++))
    fi
    
    echo ""
    log_info "Validation complete: $errors errors, $warnings warnings"
    
    if [[ $errors -gt 0 ]]; then
        return 1
    elif [[ $warnings -gt 0 ]]; then
        return 2
    else
        log_success "Architecture doc is complete and ready for approval"
        return 0
    fi
}

cmd_architecture_doc_approve() {
    local file="${1:-}"
    
    if [[ -z "$file" ]]; then
        log_error "Usage: opencode architecture-doc approve <file>"
        return 1
    fi
    
    if [[ ! -f "$file" ]]; then
        log_error "File not found: $file"
        return 1
    fi
    
    # Validate first
    if ! cmd_architecture_doc_validate "$file"; then
        log_error "Cannot approve architecture doc with validation errors"
        return 1
    fi
    
    # Update status
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    sed -i "s/^\\*\\*Status:\\*\\* .*/\\*\\*Status:\\*\\* APPROVED/" "$file"
    
    log_success "Architecture doc approved: $file"
    
    # Log to audit trail
    if command -v wal_write_atomic &>/dev/null; then
        wal_write_atomic "ARCHITECTURE_DOC_APPROVED" "{\"file\": \"$file\", \"timestamp\": \"$timestamp\"}"
    fi
}

cmd_architecture_doc_export_json() {
    local file="${1:-}"
    
    if [[ -z "$file" ]]; then
        log_error "Usage: opencode architecture-doc export-json <file>"
        return 1
    fi
    
    if [[ ! -f "$file" ]]; then
        log_error "File not found: $file"
        return 1
    fi
    
    # Extract key fields
    local feature_name
    feature_name=$(head -1 "$file" | sed 's/# Architecture Documentation: //')
    local status
    status=$(grep -m1 "^\\*\\*Status:\\*\\*" "$file" | cut -d':' -f2 | tr -d '*' | xargs)
    local author
    author=$(grep -m1 "^\\*\\*Author:\\*\\*" "$file" | cut -d':' -f2 | tr -d '*' | xargs)
    local created
    created=$(grep -m1 "^\\*\\*Created:\\*\\*" "$file" | cut -d':' -f2 | tr -d '*' | xargs)
    
    # Count diagrams
    local diagram_count
    diagram_count=$(grep -c "\`\`\`mermaid" "$file" || echo 0)
    
    # Count ADRs
    local adr_count
    adr_count=$(grep -c "### ADR-[0-9]*:" "$file" || echo 0)
    
    # Output JSON
    cat << EOF
{
  "feature_name": "$feature_name",
  "status": "$status",
  "author": "$author",
  "created": "$created",
  "diagram_count": $diagram_count,
  "adr_count": $adr_count,
  "file_path": "$file",
  "module_version": "$MODULE_51_VERSION"
}
EOF
}

# =============================================================================
# Main Entry Point
# =============================================================================

main_architecture_doc() {
    local command="${1:-help}"
    shift || true
    
    case "$command" in
        create)
            cmd_architecture_doc_create "$@"
            ;;
        list)
            cmd_architecture_doc_list "$@"
            ;;
        validate)
            cmd_architecture_doc_validate "$@"
            ;;
        approve)
            cmd_architecture_doc_approve "$@"
            ;;
        export-json)
            cmd_architecture_doc_export_json "$@"
            ;;
        help|--help|-h)
            cat << EOF
Architecture Documentation Module (v$MODULE_51_VERSION)

Usage: opencode architecture-doc <command> [options]

Commands:
  create <feature-name> [pr-file] [output]  Create new architecture doc from template
  list                                      List all architecture docs
  validate <file>                           Validate architecture doc completeness
  approve <file>                            Approve architecture doc (after validation)
  export-json <file>                        Export architecture doc metadata as JSON
  help                                      Show this help message

Examples:
  opencode architecture-doc create "AI Code Review Assistant"
  opencode architecture-doc create "AI Code Review" .opencode/product-reviews/ai-code-review.md
  opencode architecture-doc list
  opencode architecture-doc validate .opencode/architecture-docs/ai-code-review.md
  opencode architecture-doc approve .opencode/architecture-docs/ai-code-review.md
  opencode architecture-doc export-json .opencode/architecture-docs/ai-code-review.md

Source: HumanLayer 4-stage design process - Stage 2: Architecture Documentation
Prerequisites: Product Review (Module 50) - recommended but not required
Next: Program Design (opencode program-design create)
EOF
            ;;
        *)
            log_error "Unknown command: $command"
            echo "Run 'opencode architecture-doc help' for usage"
            return 1
            ;;
    esac
}

# Auto-execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_architecture_doc "$@"
fi
