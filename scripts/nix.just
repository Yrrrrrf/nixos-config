host := "g14"

[doc("Build only — no activation")]
[group("NixOS")]
build:
    nh os build -H {{ host }}

[doc("Rebuild and switch")]
[group("NixOS")]
switch:
    nh os switch -H {{ host }}

[doc("Update flake inputs and switch")]
[group("NixOS")]
update:
    nh os switch -H {{ host }} --update

[doc("Garbage collect old generations (keeps last 7 days)")]
[group("NixOS")]
clean:
    nh clean all

[doc("List all generations")]
[group("NixOS")]
list-gen:
    nixos-rebuild list-generations --flake .
