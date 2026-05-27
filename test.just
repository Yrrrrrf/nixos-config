test-cmd := "echo"
health feature="all":
    @just _run "health" "{{feature}}"
bench feature="all" quick="":
    @just _run "bench" "{{feature}}" "{{ if quick == 'quick' { '--quick' } else { '' } }}"
_run type feature flags="":
    @{{test-cmd}} "ls tests/{{type}}-{{ if feature == 'all' { '*' } else { feature } }}.nu | each { |it| nu $it.name {{flags}} }"
