<!--
SPDX-License-Identifier: MPL-2.0
Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
-->
# NSAI Neurosymbolic Platform Overview

## Vision

Transform NSAI from a citation validator into a **comprehensive neurosymbolic research platform** that:

1. **Validates** bibliographic structure (Tractarian logic)
2. **Integrates** with advanced AI/ML systems
3. **Orchestrates** neurosymbolic reasoning
4. **Remains lightweight** in the plugin
5. **Offloads** heavy computation to external services

## Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                     NSAI Neurosymbolic Platform                   │
└──────────────────────────────────────────────────────────────────┘

┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Zotero Plugin  │    │  GraphQL API    │    │  External AI/ML │
│    (Lightweight)│◄──►│   (Elixir)      │◄──►│    Services     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
     │                        │                       │
     │  Validation            │  Orchestration        │  Computation
     │  Certainty             │  Real-time            │  Learning
     │  Handoff               │  Subscriptions        │  Reasoning
     │                        │                       │
     ▼                        ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Tractarian     │    │  Type-safe      │    │  - OpenCyc      │
│  Validator      │    │  Schema         │    │  - Reservoir    │
│                 │    │                 │    │  - Conceptors   │
│  - Structure    │    │  - 70+ types    │    │  - Expert Sys   │
│  - Consistency  │    │  - 15+ queries  │    │  - LSM          │
│  - Certainty    │    │  - 12+ mutations│    │  - Agents       │
│  - Fogbinder    │    │  - Subscriptions│    │  - Neural-Sym   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Core Principles

### 1. Tractarian Foundation (Certainty)

NSAI's validation follows Wittgenstein's *Tractatus*:

- **What can be said clearly** → Formal validation (structure, consistency)
- **What cannot be spoken of** → AI/ML integration (semantics, learning)

### 2. Lightweight Plugin

The Zotero plugin remains minimal:

- **5 MB or less**
- **No heavy dependencies**
- **Fast startup**
- **Offline-first validation**

### 3. External Services

Heavy computation happens outside:

- **Knowledge bases** (OpenCyc)
- **ML training** (Reservoir, LSM)
- **Symbolic reasoning** (Expert systems)
- **Agent planning** (BDI, STRIPS)

### 4. GraphQL Orchestration

GraphQL API coordinates everything:

- **Type-safe** communication
- **Real-time** subscriptions
- **Modular** service integration
- **Language-agnostic** clients

## Integrated Systems

### Tier 1: Knowledge & Validation

1. **Tractarian Validator** (Built-in)
   - Structural completeness
   - Format consistency
   - Certainty scoring
   - **Status**: ✅ Implemented

2. **Fogbinder Integration** (Built-in)
   - Uncertainty detection
   - Contradiction hints
   - Epistemic summaries
   - **Status**: ✅ Implemented

3. **OpenCyc Knowledge Base** (External)
   - Concept enrichment
   - Assertion retrieval
   - Reasoning queries
   - **Status**: 🔄 Schema ready, guide pending

### Tier 2: Reservoir Computing

4. **Echo State Networks** (External)
   - Temporal pattern recognition
   - Citation sequence prediction
   - Fast training
   - **Status**: 🔄 Schema ready, guide pending

5. **Conceptors** (Herbert Jaeger)
   - Pattern abstraction
   - Logic operations (AND/OR/NOT)
   - Aperture-based generalization
   - **Status**: 🔄 Schema ready, guide pending

6. **Liquid State Machines** (External)
   - Spiking neural networks
   - Spatiotemporal processing
   - Biological plausibility
   - **Status**: 🔄 Schema ready, guide pending

### Tier 3: Symbolic Reasoning

7. **Expert Systems** (External)
   - Rule-based inference
   - Forward/backward chaining
   - Domain knowledge
   - **Status**: 🔄 Schema ready, guide pending

8. **Logic Programming** (External)
   - Prolog/Datalog queries
   - Answer Set Programming
   - Constraint solving
   - **Status**: 🔄 Schema ready, guide pending

### Tier 4: Agentic AI

9. **BDI Agents** (External)
   - Belief-Desire-Intention
   - Goal-oriented behavior
   - Autonomous research assistance
   - **Status**: 🔄 Schema ready, guide pending

10. **Planning Systems** (External)
    - STRIPS/HTN planning
    - POMDP decision making
    - Multi-agent coordination
    - **Status**: 🔄 Schema ready, guide pending

### Tier 5: Neural-Symbolic Integration

11. **DeepProbLog** (External)
    - Probabilistic logic + neural networks
    - Differentiable reasoning
    - Explainable predictions
    - **Status**: 🔄 Schema ready, guide pending

12. **Logic Tensor Networks** (External)
    - First-order logic in vector space
    - Neural-symbolic grounding
    - Semantic matching
    - **Status**: 🔄 Schema ready, guide pending

## Integration Workflow

### Step 1: Validation (NSAI Plugin)

```typescript
// In Zotero plugin
const validator = new TractarianValidator();
const result = validator.validate(citation);

if (result.certainty.score >= 0.7) {
  // High certainty - NSAI handles
  displayValidated(result);
} else {
  // Low certainty - prepare for AI/ML
  sendToGraphQL(result);
}
```

### Step 2: GraphQL Query (API Server)

```graphql
query EnrichCitation($id: ID!) {
  citation: getCitation(id: $id) {
    id
    title
    certainty { score }

    # OpenCyc enrichment
    cycConcepts {
      name
      comment
      related { name }
    }

    # Expert system reasoning
    expertAnalysis: queryExpertSystem(
      systemId: "bibliography-expert"
      query: "analyze_citation"
    ) {
      confidence
      explanation
      suggestedActions {
        type
        target
      }
    }
  }
}
```

### Step 3: External Service (e.g., OpenCyc)

```elixir
# GraphQL resolver (Elixir/Absinthe)
def resolve_cyc_concepts(%{id: citation_id}, _context) do
  citation = Repo.get(Citation, citation_id)

  # Poll OpenCyc REST API
  {:ok, concepts} = OpenCyc.query(citation.title)

  # Cache results locally
  Enum.map(concepts, &format_cyc_concept/1)
end
```

### Step 4: Real-time Updates (Subscriptions)

```graphql
subscription ReservoirTraining($reservoirId: ID!) {
  reservoirState(reservoirId: $reservoirId)
}
```

```typescript
// Client receives live updates
const subscription = client.subscribe({
  query: RESERVOIR_TRAINING_SUB,
  variables: { reservoirId: 'reservoir-1' }
});

subscription.subscribe({
  next: ({data}) => {
    updateReservoirVisualization(data.reservoirState);
  }
});
```

## Data Flow

```
User selects citations in Zotero
         │
         ▼
NSAI validates (Tractarian logic)
         │
         ├──► Certainty >= 0.7? ──► Display validated ──► Done
         │
         └──► Certainty < 0.7? ──► Send to GraphQL API
                                           │
                                           ▼
                                   Route to appropriate service:
                                           │
         ┌─────────────────────────────────┼──────────────────────┐
         │                                 │                      │
         ▼                                 ▼                      ▼
    OpenCyc                          Reservoir              Expert System
    (concepts)                       (patterns)             (rules)
         │                                 │                      │
         └─────────────────┬───────────────┴──────────────────────┘
                           │
                           ▼
                  Aggregate results
                           │
                           ▼
                  Return to NSAI plugin
                           │
                           ▼
                  Display enriched citation
                  + Fogbinder export option
```

## Technology Stack

### NSAI Plugin (Zotero)
- **Language**: TypeScript
- **Build**: Vite
- **Testing**: Vitest
- **Validation**: Zod
- **Size**: < 5 MB

### GraphQL API Server
- **Language**: Elixir
- **Framework**: Phoenix + Absinthe
- **Database**: PostgreSQL
- **Cache**: Redis
- **Realtime**: WebSockets (Phoenix Channels)

### External Services

**OpenCyc**:
- Language: Common Lisp / Java
- API: REST + SPARQL
- Polling: RSS/Atom feeds

**Reservoir Computing**:
- Language: Python
- Libraries: ReservoirPy, PyESN
- API: FastAPI

**Conceptors**:
- Language: MATLAB/Python
- Original: Herbert Jaeger's MATLAB code
- Port: Python (NumPy/SciPy)

**Expert Systems**:
- Language: Prolog (SWI-Prolog)
- Alternative: Clojure (Clara Rules)
- API: HTTP JSON-RPC

**Liquid State Machines**:
- Language: Python
- Simulators: Brian2, NEST
- API: gRPC (performance)

**Agentic Systems**:
- Language: Java (GOAL, Jason)
- Alternative: Python (pyddl, pyBDI)
- API: REST

**Neural-Symbolic**:
- Language: Python
- Frameworks: DeepProbLog, LTN
- Training: PyTorch/TensorFlow
- API: gRPC

## Performance Targets

| Component | Response Time | Throughput |
|-----------|--------------|------------|
| NSAI Validation | < 10ms | 1000 cit/sec |
| GraphQL Query | < 100ms | 100 req/sec |
| OpenCyc Lookup | < 500ms | 10 req/sec |
| Reservoir Prediction | < 50ms | 50 req/sec |
| Expert System Query | < 200ms | 20 req/sec |
| LSM Classification | < 100ms | 30 req/sec |
| Agent Planning | < 2s | 5 req/sec |
| Neural-Symbolic Inference | < 500ms | 10 req/sec |

## Deployment Options

### Option 1: Local Development

```bash
# NSAI plugin (Zotero)
cd zotero-nsai
npm install
npm run build

# GraphQL API (Docker Compose)
cd nsai-graphql-api
docker-compose up -d

# External services (separate containers)
docker-compose -f services.yml up -d
```

### Option 2: Cloud Deployment

```yaml
# Kubernetes deployment
apiVersion: v1
kind: Service
metadata:
  name: nsai-graphql
spec:
  selector:
    app: nsai-api
  ports:
    - port: 4000
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nsai-api
spec:
  replicas: 3
  template:
    spec:
      containers:
      - name: api
        image: nsai/graphql-api:latest
        env:
        - name: OPENCYC_URL
          value: "http://opencyc-service:3601"
```

### Option 3: Serverless

```typescript
// AWS Lambda / Cloudflare Workers
export default {
  async fetch(request: Request): Promise<Response> {
    const result = await validate(citation);

    if (result.certainty.score < 0.7) {
      // Invoke AI/ML services
      const enriched = await enrichWithOpenCyc(citation);
      return json(enriched);
    }

    return json(result);
  }
}
```

## Security Considerations

### Authentication

```graphql
query ValidateCitation($token: String!) {
  validateCitation(
    citation: $input
    auth: { token: $token }
  ) {
    # Results
  }
}
```

### Rate Limiting

```elixir
# Absinthe middleware
def limit_rate(resolution, config) do
  case RateLimiter.check(resolution.context.user_id) do
    :ok -> resolution
    {:error, :rate_limited} ->
      Resolution.put_result(resolution, {:error, "Rate limit exceeded"})
  end
end
```

### Data Privacy

- **Local-first**: Validation happens locally
- **Opt-in AI**: User must explicitly enable AI/ML services
- **No tracking**: External services receive minimal data
- **Encryption**: TLS for all API calls
- **Audit logs**: Track all external service calls

## Roadmap

### v0.2.0 (Q1 2025)
- [ ] GraphQL API server (Elixir/Absinthe)
- [ ] OpenCyc integration guide
- [ ] Basic reservoir computing example
- [ ] Expert system template

### v0.3.0 (Q2 2025)
- [ ] Conceptor framework integration
- [ ] LSM simulator connector
- [ ] Agentic system examples
- [ ] Neural-symbolic tutorials

### v1.0.0 (Q3 2025)
- [ ] Full production deployment
- [ ] All external services documented
- [ ] Performance benchmarks
- [ ] Security audit complete

### v2.0.0 (Future)
- [ ] Federated learning across NSAI instances
- [ ] Quantum computing integration (D-Wave)
- [ ] Blockchain citation verification
- [ ] TLA+ distributed consensus

## Getting Started

See integration guides:

1. [OpenCyc Integration](./01-OPENCYC-INTEGRATION.md)
2. [Reservoir Computing](./02-RESERVOIR-COMPUTING.md)
3. [Conceptor Framework](./03-CONCEPTOR-FRAMEWORK.md)
4. [Expert Systems](./04-EXPERT-SYSTEMS.md)
5. [Liquid State Machines](./05-LIQUID-STATE-MACHINES.md)
6. [Agentic Systems](./06-AGENTIC-SYSTEMS.md)
7. [Neural-Symbolic Integration](./07-NEURAL-SYMBOLIC.md)
8. [RSS Polling Mechanism](./08-RSS-POLLING.md)

## Philosophy

This platform embodies **both** Wittgensteins:

**Early Wittgenstein (Tractatus)**: NSAI validation
- "What can be said clearly" → Formal structure
- Logical atomism → Citations as atomic facts
- Certainty boundary → Where validation ends

**Late Wittgenstein (Investigations)**: AI/ML integration
- "Meaning is use" → Learn from citation patterns
- Language games → Different research domains
- Family resemblance → Conceptor pattern matching

Together, they form a complete research epistemology:

**"What can be validated formally, NSAI validates.
What requires learning and reasoning, NSAI orchestrates."**

---

Next: [OpenCyc Integration →](./01-OPENCYC-INTEGRATION.md)
