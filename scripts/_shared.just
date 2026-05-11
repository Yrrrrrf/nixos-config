set shell := ["bash", "-cu"]

user := env('USER')
group := "users"
dir := justfile_directory()
