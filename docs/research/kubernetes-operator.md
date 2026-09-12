# OpenCode Initializer — Kubernetes Operator

## Overview

This document describes a Kubernetes operator for managing opencode_initializer
environments in Kubernetes clusters.

## Why Kubernetes Operator?

| Feature | Manual Setup | K8s Operator |
|---------|-------------|--------------|
| Scalability | Manual | Automatic |
| Self-healing | Manual | Automatic |
| Updates | Manual | Rolling |
| Monitoring | Manual | Built-in |
| Multi-tenant | Difficult | Easy |

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│              Kubernetes Operator                         │
├─────────────────────────────────────────────────────────┤
│  Controller (Go)                                        │
│  ├── Reconciler                                         │
│  ├── CRD Handler                                        │
│  ├── Event Watcher                                      │
│  └── Status Updater                                     │
├─────────────────────────────────────────────────────────┤
│  Custom Resources (CRDs)                                │
│  ├── OpenCodeEnvironment                                │
│  ├── OpenCodeModule                                     │
│  ├── OpenCodeProvider                                   │
│  └── OpenCodeService                                    │
├─────────────────────────────────────────────────────────┤
│  Managed Resources                                      │
│  ├── Deployments                                        │
│  ├── Services                                           │
│  ├── ConfigMaps                                         │
│  ├── Secrets                                            │
│  ├── PersistentVolumeClaims                             │
│  └── Jobs                                               │
└─────────────────────────────────────────────────────────┘
```

## Custom Resources

### OpenCodeEnvironment

```yaml
apiVersion: opencode.dev/v1alpha1
kind: OpenCodeEnvironment
metadata:
  name: my-environment
  namespace: development
spec:
  image: opencode-init:latest
  replicas: 1
  modules:
    - system
    - docker
    - nodejs
    - python
  providers:
    - deepseek
    - openai
  services:
    postgres:
      enabled: true
      version: "17"
    redis:
      enabled: true
  resources:
    requests:
      cpu: "1"
      memory: "2Gi"
    limits:
      cpu: "4"
      memory: "8Gi"
  storage:
    size: "10Gi"
    storageClass: "standard"
status:
  phase: Running
  readyReplicas: 1
  conditions:
    - type: Ready
      status: "True"
```

### OpenCodeModule

```yaml
apiVersion: opencode.dev/v1alpha1
kind: OpenCodeModule
metadata:
  name: nodejs-24
spec:
  name: nodejs
  version: "24"
  dependencies:
    - system
  install: |
    curl -fsSL https://deb.nodesource.com/setup_24.x | bash -
    apt-get install -y nodejs
  health: node --version
```

## Controller Implementation

```go
package controllers

import (
    "context"
    "fmt"

    appsv1 "k8s.io/api/apps/v1"
    corev1 "k8s.io/api/core/v1"
    metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
    "k8s.io/apimachinery/pkg/runtime"
    ctrl "sigs.k8s.io/controller-runtime"
    "sigs.k8s.io/controller-runtime/pkg/client"

    opendevv1alpha1 "github.com/AlexanderNarbaev/opencode-operator/api/v1alpha1"
)

type OpenCodeEnvironmentReconciler struct {
    client.Client
    Scheme *runtime.Scheme
}

func (r *OpenCodeEnvironmentReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
    // Get the OpenCodeEnvironment
    env := &opendevv1alpha1.OpenCodeEnvironment{}
    if err := r.Get(ctx, req.NamespacedName, env); err != nil {
        return ctrl.Result{}, client.IgnoreNotFound(err)
    }

    // Create or update Deployment
    deployment := r.createDeployment(env)
    if err := r.Create(ctx, deployment); err != nil {
        return ctrl.Result{}, err
    }

    // Update status
    env.Status.Phase = "Running"
    if err := r.Status().Update(ctx, env); err != nil {
        return ctrl.Result{}, err
    }

    return ctrl.Result{}, nil
}

func (r *OpenCodeEnvironmentReconciler) SetupWithManager(mgr ctrl.Manager) error {
    return ctrl.NewControllerManagedBy(mgr).
        For(&opendevv1alpha1.OpenCodeEnvironment{}).
        Owns(&appsv1.Deployment{}).
        Complete(r)
}
```

## Installation

### Using Helm

```bash
helm repo add opencode https://charts.opencode.dev
helm install opencode-operator opencode/opencode-operator
```

### Using kubectl

```bash
kubectl apply -f https://github.com/AlexanderNarbaev/opencode-operator/releases/latest/download/install.yaml
```

## Usage

### Create Environment

```bash
kubectl apply -f - <<EOF
apiVersion: opencode.dev/v1alpha1
kind: OpenCodeEnvironment
metadata:
  name: dev-team
  namespace: development
spec:
  image: opencode-init:latest
  replicas: 3
  modules:
    - system
    - docker
    - nodejs
    - python
    - go
EOF
```

### Check Status

```bash
kubectl get opencodeenvironments -n development
kubectl describe opencodeenvironment dev-team -n development
```

### Scale

```bash
kubectl scale opencodeenvironment dev-team --replicas=5 -n development
```

## Benefits

1. **Multi-tenant** — Separate environments per team
2. **Scalable** — Auto-scale based on demand
3. **Self-healing** — Automatic recovery from failures
4. **GitOps** — Declarative configuration
5. **Observability** — Built-in monitoring

## Implementation Plan

### Phase 1: Basic Operator
- [ ] CRD definitions
- [ ] Basic controller
- [ ] Deployment management
- [ ] Status reporting

### Phase 2: Advanced Features
- [ ] Module management
- [ ] Service management
- [ ] Provider management
- [ ] Configuration management

### Phase 3: Production Ready
- [ ] Helm chart
- [ ] RBAC
- [ ] Monitoring
- [ ] Documentation

## Future Enhancements

1. **Auto-scaling** — Scale based on usage
2. **Backup/Restore** — Automated backups
3. **Multi-cluster** — Cross-cluster management
4. **Cost optimization** — Resource right-sizing
