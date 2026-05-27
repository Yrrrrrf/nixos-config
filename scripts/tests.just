import "_shared.just"

test-cmd := "nix develop ./tests -c nu"

[doc("Run health audits (e.g. just health, just health ram)")]
[group("Test")]
health feature="all":
    @just _run health {{feature}}

[doc("Run benchmarks (e.g. just bench, just bench disk quick)")]
[group("Test")]
bench feature="all" quick="":
    @just _run bench {{feature}} {{ if quick == "quick" { "--quick" } else { "" } }}

[doc("Run all UI contract tests")]
[group("Test")]
ui:
    @just health ui
    @just bench ui

[doc("Run everything")]
[group("Test")]
all: health bench ui

[doc("Run UI benchmarks selectively (e.g. just bench-ui, just bench-ui brightness)")]
[group("Test")]
bench-ui feature="":
    @ {{test-cmd}} -c "nu tests/bench-ui.nu {{feature}}"

# Internal test runner
_run type feature flags="":
    @ {{test-cmd}} -c "let file = (ls tests/{{type}}-{{feature}}.nu | get 0.name); print $'(ansi cyan)→ ($file)(ansi reset)'; nu $file {{flags}}"
