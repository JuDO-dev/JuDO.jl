# Template for JuDO Packages

## Create GitHub repository
1. Click the green **'Use this template'** button and choose **'Create a new repository'**;
2. Name your repository with the `.jl` suffix (for example `Pizza.jl`);
3. Leave **'Include all branches'** unticked;
4. Click **'Create repository from template'**;
5. Clone the repository to your machine.

## Generate package files
1. In your machine, open Julia in a directory of your choice (for example `\Documents`);
2. Create a package template by running:
```julia 
julia> using Pkg; Pkg.add("PkgTemplates");
julia> using PkgTemplates
julia> t = Template(
    user="JuDO-dev",
    dir=pwd(),
    julia=v"1.6",
    plugins=[
        !License,
        ProjectFile(; version=v"0.1.0"),
        Git(branch="dev"),
        GitHubActions(linux=true, osx=true, windows=true, x64=true, x86=true, extra_versions=["1.9", "nightly"]),
        Codecov(),
        Documenter{GitHubActions}()])
```
3. Generate the package files by running:
```julia
julia> t("Pizza") # Without the ".jl" suffix!
```

## Assemble Julia package
1. Copy the contents of `Pizza` into `Pizza.jl`, except `.git` and `.gitignore`, replacing `README.md`;
2. Commit changes and push to origin*.

*You may use [GitHub Desktop](https://desktop.github.com/).
