import "_shared.just"

test-cmd := "nix develop ./tests -c nu"

[doc("Run all system health audits")]
[group("Test")]
health:
    {{test-cmd}} tests/health.nu

[doc("Run GPU health audit")]
[group("Test")]
gpu:
    {{test-cmd}} tests/gpu-health.nu

[doc("Run system performance benchmarks")]
[group("Test")]
bench quick="":
    {{test-cmd}} tests/bench.nu {{ if quick == "quick" { "--quick" } else { "" } }}

[doc("Run all UI contract tests")]
[group("Test")]
ui:
    {{test-cmd}} tests/ui-get.nu

[doc("Run everything (Health + UI)")]
[group("Test")]
all: health ui
