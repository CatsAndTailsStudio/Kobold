<details>
<summary>Collapsible header...</summary> 
I want a system for managing C and C++ library versions for me. It would be able to seamlessly switch between versions as well as download specific versions by hooking into github. Maybe look into how asdf works.

Will probably have to interface with specific shells so should probably build an easy way to interface with the ones I might want(dash, bash, zsh, elvish)

No build system abstraction, it will be strictly for managing and installing versions at the moment. Having some kind of build system integrated should be a separate project built on top as a separate program.

This would also be flexible enough to allow version management of things such as ruby or other programs

Having a nice TUI would be great, maybe using something like the Ruby TUI kit to build it out.

---

- Shell interface/hook
- Directory system that holds the packages
	- Install directory -> this is where the git/build files/etc are
	- Build directory -> this is where build targets are moved to. E.g raylib lets you build for linux but also web and windows. Having those built versions in different directories would be very nice
- Shim that activates or deactivates certain versions. This would also modify the build dirs.
- Packages are called Knapsacks, they are tarballs that contain configuration files used to install or download the software.
	- A configuration file
	- A .rb installation file
If a package requires to download from a remote repo then it should be a `remote.knapsack`
If a package is a version manager then it should be a `manager.knapsack`
If it is a single version and doesnt depend on downloading things(other package dependencies are an exception) then it is just a ``.knapsack`

---

First test project: making raylib into a remote package with which I can add into and use for a C project.

it will need to keep track of how to:
- "install" raylib files into kobold
- treat dynamic and static as seperate "versions"
- allow setting a raylib version inside my C project

Kobold will -> read the kobold file -> download raylib from github -> checkout correct version
When it checks out it should place it into a specific custom orphaned branch.
For now, it should be built and managed manually by the user.
Allow user to name give an extra tag to the version(e.g if they want to build using web it should be a different "version" then the one used for linux)
Allow kobold to manage shims that will exist inside the project directory where the project can build and utilize them.

The benefit of this is automatic setup of the correct version of a dependency, allowing for reuse of the same dependency across the system automatically if desired but if required it can also use a specific custom version separate from the rest of the dependencies(i.e if you need your specific project to have custom compile flags)
 </details>


---

May need to look into Git Worktrees as they potentially do what I need: https://git-scm.com/docs/git-worktree and https://stackoverflow.com/a/62018137

Here is a very long but promising explanation of how Rbenv manages shims: https://www.impostorsguides.com/rbenv/how-shims-work

---

Need to have a shims directory like RBENV. -> /home/username/.rbenv/shims

Directory for how RBENV sets up shims: rbenv/libexec/rbenv-shims

---

[File class doc](https://rubydoc.info/stdlib/core/File)

`.symlink(old_name, new_name) ⇒ 0`

    Creates a symbolic link called new_name for the existing file old_name.

`.symlink?(file_name) ⇒ Boolean`

    Returns true if the named file is a symbolic link.

`.realpath(pathname[, dir_string]) ⇒ Object`

    Returns the real (absolute) pathname of pathname in the actual filesystem not containing symlinks or useless dots.
    
---

[Ruby Git Gem](https://github.com/ruby-git/ruby-git)

[Ruby Command Line Option Parser](https://github.com/piotrmurach/tty-option)
