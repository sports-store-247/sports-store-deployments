## Conflict Detection Report

Mode: new (no pre-existing .planning/ context to check against)
Precedence: ADR > SPEC > PRD > DOC, with per-doc overrides from the manifest
  prec 0 = GSD.md (SPEC) · prec 1 = STATUS.md (PRD) · prec 2 = coordinator-agent-plan (SPEC)
  all remaining docs = DOC (lowest)

Note on precedence: the manifest's per-doc override places STATUS.md (PRD, prec 1) ABOVE
the coordinator plan (SPEC, prec 2). Two entries below resolve in STATUS.md's favor
against a SPEC because of that override, which inverts the default ADR>SPEC>PRD ordering.

### BLOCKERS (0)

None.

No ADRs exist in this doc set and no document is marked locked, so the LOCKED-vs-LOCKED
and LOCKED-vs-existing-context checks could not fire. All 11 classifications are
confidence "high" with manifest_override set, so no UNKNOWN/low-confidence blocker fired.
No definitional reference cycle was found (see INFO 7). Mode is "new", so there is no
existing .planning/ decision to contradict.

### WARNINGS (2)

[WARNING] README.md documents a superseded repository structure
  Found: README.md (DOC) describes a Stage 3 starter state - "Every file under this
    directory contains inline TODO comments instead of working resource definitions" - with
    a k8s/ tree of per-service {deployment,service}.yaml directories, and an apply order
    built on raw "kubectl apply -f k8s/<dir>/" plus a standalone
    "helm upgrade --install mongodb bitnami/mongodb".
  Found: STATUS.md (PRD, prec 1) records the current state as "Stage 3+ - Helm umbrella +
    Argo CD GitOps + ESO restructure landed on main", chart helm/sports-store with Bitnami
    MongoDB as a subchart dependency, GitOps via argocd-app.yaml with automated sync.
    gsd/verifications/2026-08-03-post-merge-full-risk-scan.md confirms 32 real resources
    render, with all 6 app images pinned to 0.1.0-<7char-hash>.
  Impact: Precedence alone would auto-resolve this to STATUS.md and discard README.md.
    That is the wrong outcome, because README.md is the only source for three constraints
    that are still live and are not restated anywhere else:
      - gateway is the only externally reachable Service, all others ClusterIP
        (constraints.md C-7)
      - backend Service metadata.name must match the gateway/nginx.conf proxy_pass
        hostnames, and changing one requires rebuilding the gateway image
        (constraints.md C-8) - this is precisely what made the F3 ingress duplicate-key
        defect a functional routing break rather than a cosmetic one
      - MongoDB must be healthy before app Deployments, ordered by retry-friendly startup
        or an initContainer, not readinessProbe alone (constraints.md C-10)
    Dropping README.md loses these. Keeping it whole propagates a false picture of the
    repo. It is a mixed live/stale document and cannot be resolved by precedence.
  → Decide per-section rather than per-document. Recommended: keep the Internal-service-DNS
    and ordering constraints, rewrite the Layout and Suggested-apply-order sections to
    match the Helm umbrella + Argo CD reality, and drop the "inline TODO comments"
    framing. Confirm before REQ-readme-accuracy (requirements.md, flagged derived) is
    routed as real work.

[WARNING] Competing acceptance variants for REQ-frontend-chart-intent
  Found: STATUS.md (PRD, prec 1) item F6 - "Frontend is not chart-managed: no Deployment or
    Service renders for it. Intent must be confirmed with the team and the chart aligned to
    that decision."
  Found: gsd/verifications/2026-08-03-helm-template-render.md (DOC) - frontend renders no
    workload, "grep -c sports-store-frontend = 0"; environments/production/images.yaml
    defines a frontend image tag but frontend is absent from .Values.services; "The public
    storefront is served outside this chart."
  Found: gsd/repo-feedback/2026-08-03-deployments-post-merge-feedback.md (DOC) item R8 -
    "Confirm intent that the frontend is not chart-managed."
  Impact: Every source defers the decision; none picks. The two possible resolutions imply
    materially different work and cannot be merged into one acceptance criterion:
      Variant A - frontend is deliberately out of chart. Acceptance: document the intent,
        reconcile the orphaned frontend entry in images.yaml, close with no workload added.
        Roughly a documentation task.
      Variant B - frontend belongs in the chart. Acceptance: add frontend to
        .Values.services, render a Deployment and Service, resolve routing/ingress
        implications. A chart change on its own branch, and it interacts with C-7 (gateway
        as sole external entrypoint) and with the existing ALB Ingress.
    Both variants are preserved verbatim in requirements.md; neither has been selected.
    There is also an unresolved sub-question either way: why images.yaml carries a frontend
    tag that nothing consumes.
  → Confirm intent with the team (this is listed in STATUS.md "Next up" already), then pick
    a variant before routing. Do not let the roadmapper collapse these into a single phase.

### INFO (12)

[INFO] Auto-resolved: STATUS.md (PRD, prec 1) > coordinator plan (SPEC, prec 2) on the
  app-secrets empty stringData item
  Note: The coordinator plan §5.5 directs that STATUS.md "Keep Helm app-secrets empty
    render as a David-owned deployment-layer item to investigate later", and §2/R1 lists
    "Helm app-secrets renders with empty stringData (reproduce via helm template)" as a
    check to run. STATUS.md records that the #17/#18 restructure replaced the deleted empty
    secret.yaml with externalsecret.yaml/secretstore.yaml/serviceaccount-eso.yaml and
    "supersedes the old app-secrets empty stringData item". The manifest's per-doc
    precedence puts STATUS.md above the coordinator plan, so the item is treated as closed
    and is not carried into requirements.md. Resolution is by precedence, not by date.

[INFO] Auto-resolved: STATUS.md (PRD, prec 1) > coordinator plan (SPEC, prec 2) on the OIDC
  regression
  Note: The coordinator plan §5.4 directs that STATUS.md "Keep the OIDC regression as a
    cross-repo security blocker", and §6 ranks the CI/CD auth security sweep first in the
    risk-first execution order. STATUS.md records "OIDC regression RESOLVED - all 7 service
    repos merged fix: revert to OIDC role-to-assume for AWS credentials. Cross-team security
    blocker closed (Sean/CI decision)", corroborated by
    gsd/research/2026-08-03-team-status-update.md and the org-delta notes (item D1, "OIDC
    revert - resolved. Track only, do not fix"). STATUS.md wins on precedence. Consequence
    worth noting: the coordinator plan's risk-first ordering was built around this blocker,
    so that ordering is stale if the plan is ever executed. Either way the decision remains
    Sean's, never David's (decisions.md D-5).

[INFO] Auto-resolved: STATUS.md (PRD, prec 1) > helm-template-render (DOC) on image tags
  Note: gsd/verifications/2026-08-03-helm-template-render.md findings 3 and 4 record all 6
    app images resolving to 0.1.0-latest and flag it a brief violation. STATUS.md records
    "F1 - image tags. All 6 app images now 0.1.0-<7char-hash> (no latest)", and
    gsd/verifications/2026-08-03-post-merge-full-risk-scan.md check [8] enumerates the
    actual hashes (auth 686e7cd, cart 6e0f5cc, catalog 06243ee, gateway 11ea172, order
    1661894, payment 2738bd5; MongoDB mongo:8.0). PRD outranks DOC. F1 recorded as resolved.

[INFO] Auto-resolved: STATUS.md (PRD, prec 1) > helm-template-render (DOC) on ingress
  backend routing
  Note: gsd/verifications/2026-08-03-helm-template-render.md finding 7 records a duplicate
    service.name key in templates/ingress.yaml resolving the backend to a non-existent
    Service sports-store-gateway, and explicitly elevates it from cosmetic to a functional
    routing defect. STATUS.md records "F3 - ingress routing. Backend to Service gateway:80
    in sports-store (merged)", and the post-merge risk scan check [5] confirms
    "service.name: gateway, port.number: 80 ... F3 stays fixed". PRD outranks DOC. F3
    recorded as resolved. PR #17 fix/gateway-service-name is the corroborating change.

[INFO] Auto-resolved: STATUS.md (PRD, prec 1) adjudicates a DOC-vs-DOC contradiction on
  ServiceMonitor rendering
  Note: Two same-precedence DOC sources contradict directly.
    gsd/verifications/2026-08-03-helm-template-render.md finding 1 reports zero
    ServiceMonitors render, root-caused in finding 2 to templates/servicemonitor.yaml
    ranging over an undefined .Values.microservices instead of .Values.services.
    gsd/verifications/2026-08-03-post-merge-full-risk-scan.md reports all 6 ServiceMonitors
    rendering. Both are DOC, so precedence cannot break the tie between them and a
    timestamp tiebreak is not permitted. The tie is broken by STATUS.md (prec 1), which
    states "F4 - ServiceMonitors now render (6 emitted). But selectors don't match - see R1"
    and labels helm-template-render the "prior render report". Resolution therefore comes
    from the higher-precedence source, not from file dates. Note the two defects are
    distinct: the microservices/services key bug is fixed; the selector/label mismatch (R1)
    is a separate, still-open defect in the same template.

[INFO] Auto-resolved: STATUS.md (PRD, prec 1) > org-delta notes (DOC) on superseded findings
  Note: gsd/research/2026-08-03-org-delta-monitor.md and
    gsd/repo-feedback/2026-08-03-org-delta-summary.md carry action items F1 (replace
    latest/0.1.0-latest with real tags), F3 (ingress duplicate service.name), and F4 (verify
    ServiceMonitor rendering) as open David-owned work. STATUS.md records all three as
    resolved. PRD outranks DOC; these are not carried into requirements.md as open items.
    One related item, F5 (refresh local from main), IS carried into requirements.md but
    flagged with a caveat, since STATUS.md reports the active branch already in sync with
    main and may have satisfied it.

[INFO] Reference-graph cycle: GSD.md <-> STATUS.md, treated as navigational
  Note: Cycle detection over the cross_refs graph found exactly one strongly-connected
    component: GSD.md references ./STATUS.md and STATUS.md references ./GSD.md. Max
    traversal depth reached was 3, far under the 50 cap. This was classified as a
    navigational cross-link, not a definitional dependency, and synthesis proceeded on both
    documents. Rationale: neither document's content extraction depends on resolving the
    other. GSD.md points at STATUS.md to say "live state is not here" and STATUS.md points
    back to say "process rules are not here" - the D-2 separation-of-concerns pattern.
    There is no include/extends/inherits relationship, so no synthesis loop is possible.
    This is a judgment call and it is recorded here so it can be overridden: had it been
    treated as a hard cycle, the two highest-precedence documents in the set (prec 0 and
    prec 1) would have been excluded and the ingest would have produced almost nothing.
    Two self-references were also dropped as artifacts: GSD.md lists "GSD.md" and the
    coordinator plan lists both "GSD.md" and "STATUS.md" alongside their relative forms.
    Directory-valued cross_refs (gsd/research/, gsd/instructions/, helm/, configmaps/,
    secrets/, mongodb/) were not expanded into per-document edges; expanding them would
    manufacture cycles that do not exist in the prose.

[INFO] Identifier namespace collision on R1-R10
  Note: The token "R1" carries two unrelated meanings in this doc set. In
    gsd/instructions/2026-08-03-coordinator-agent-plan.md, R1-R10 enumerate REPOSITORIES
    (R1 = sports-store-deployments, R2 = sports-store-infrastructure, R3-R9 = the seven
    image repos, R10 = sports-store-local). In STATUS.md and both verification notes, R1-R7
    enumerate FINDINGS (R1 = ServiceMonitor selector mismatch, R2 = MongoDB emptyDir,
    R3 = ESO/Secrets Manager, R4 = mongo-init namespace, R5 = /metrics endpoints,
    R6 = Mongo password property, R7 = Argo CD name). So "R3" means auth-service in one
    document and the cross-team secrets blocker in another; "R5" means cart-service or the
    /metrics gap. A third scheme, F1-F6, overlaps the finding scheme (F2 = Argo CD name is
    also R7; F6 = frontend is also R8 in the feedback note). This was neutralised in
    synthesis by assigning REQ-<slug> identifiers and never keying on the raw letters, but
    the collision persists in the source documents and in any human reading of them.
  → No action required for routing. Worth a rename if these documents are revised.

[INFO] R6 is tracked in DOC sources but absent from STATUS.md
  Note: gsd/verifications/2026-08-03-post-merge-full-risk-scan.md R6 and
    gsd/repo-feedback/2026-08-03-deployments-post-merge-feedback.md R6 both record that
    mongodb-credentials-eso maps mongodb-root-password and mongodb-passwords from the single
    MONGO_ROOT_PASSWORD property, making the root password equal to the user password
    (Sean-owned, informational). STATUS.md does not list it in any open section. This is a
    gap rather than a contradiction - the higher-precedence document is silent, not
    contradictory - so it is preserved in requirements.md under the not-routable section
    rather than dropped. It is Sean-owned either way and cannot become a phase here.

[INFO] Coordinator plan report-path contract not matched by existing artifacts
  Note: The coordinator plan §4 mandates repo review reports at
    gsd/repo-feedback/2026-08-03-<repo-slug>-review.md. The two files actually present in
    gsd/repo-feedback/ are 2026-08-03-deployments-post-merge-feedback.md and
    2026-08-03-org-delta-summary.md - neither matches the -review.md pattern. This is not
    a violation: the plan self-declares "Do not run the individual repo reviews yet - this
    plan is the deliverable", and its definition of done is explicitly open. The existing
    files are post-merge feedback and an org-delta summary, which are different artifacts.
    Recorded so the unmet definition of done is not mistaken for completed work.

[INFO] No ADRs and no locked decisions in this doc set
  Note: Type breakdown is 2 SPEC, 1 PRD, 8 DOC, 0 ADR. Every classification has
    locked: false. Six documents carry a 2026-08-03- filename prefix that resembles ADR
    sequence numbering, and the classifiers flagged each one; all six are dated notes, not
    numbered decision records. The closest ADR-shaped artifact is
    gsd/research/2026-08-03-docs-bootstrap.md, which has a "## Decision" heading but no
    Status field, no ADR number, and lives under gsd/research/ rather than an adr/
    directory - it is recorded as rationale in decisions.md D-2, not as a locked decision.
    Consequence: nothing in this ingest is protected from ordinary revision, and the
    LOCKED-decision machinery never engaged. Binding process rules do exist, but they are
    carried by the two SPEC documents and are overridable by normal PR.

[INFO] Scope fence recorded as a hard constraint
  Note: STATUS.md and the coordinator plan agree, with no divergence, on the ownership
    split - David owns deployments/Helm/GitOps/docs; Sean owns AWS/Terraform/EKS/ALB/ECR/
    CI cloud-auth; Daniel owns service and application behaviour; Maxim owns review and
    coordination. Because the two sources agree, this produced no conflict, but it has the
    largest single effect on what may be routed: R3 (ESO/Secrets Manager/IRSA), the ALB
    controller install, the EBS StorageClass that REQ-mongodb-persistence depends on, R5
    (/metrics endpoints), R6, the required-extension implementation, and full E2E validation
    are all outside this repo's authority. They are recorded in requirements.md under a
    dedicated not-routable section with routable: no, and as constraints.md C-1, so they are
    visible to the roadmapper but excluded from phase generation. Four David-owned items
    remain freely routable (R1, R4, F2, and the F5 refresh), one is routable but externally
    blocked (R2, pending Sean's StorageClass), and one is blocked on a decision (F6).
