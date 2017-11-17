# GitLab Git
[![Build Status](https://travis-ci.org/ontohub/gitlab_git.svg?branch=master)](https://travis-ci.org/ontohub/gitlab_git)

GitLab wrapper around git objects.

This is the Ontohub-fork of [gitlab_git](https://gitlab.com/gitlab-org/gitlab_git).
Since `Gitlab::Git` has been absorbed into the [main GitLab project](https://gitlab-com/gitlab-org/gitlab-ce), the original `gitlab_git` gem has been deprecated. See the [gitlab-ce issue](https://gitlab.com/gitlab-org/gitlab-ce/issues/24374) and [merge request](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/8447) for more information.

In this fork, some updates to gitlab_git from the integrated gitlab-git are copied over and adjusted to work as a gem.
However, newer changes to the git layer of Gitlab are so tightly intergrated with Gitlab that pulling them back into this gem is impossible.
Even though this will not receive any more changes introduced by Gitlab, this fork is still maintained by the Ontohub team.

This fork of the original gem adds a wrapper `Gitlab::Git::Wrapper` around the original Gitlab::Git objects to allow for easier handling.

# Documentation

## Moved from Grit to Rugged

GitLab Git used grit as main library in past. Now it uses rugged

## How to use

### Wrapper

The Wrapper is an object encapsulating the Gitlab::Git functionality to provide a more convenient interface.

```ruby
# Create a new bare git repository
wrapper = Gitlab::Git::Wrapper.create('/path/to/the/new/repository.git') # => #<Gitlab::Git::Wrapper:0x00007fa91fa1e440 ...>

# Delete an existing git repository
Gitlab::Git::Wrapper.destroy('/path/to/the/repository.git')

# Initialize a Wrapper object on an existing repository
wrapper = Gitlab::Git::Wrapper.new('/path/to/the/repository.git') # => #<Gitlab::Git::Wrapper:0x00007fa91fa1e440 ...>

# Check if a git repository exists in the given path
wrapper.repo_exists? # => true

# Check if the repository is a bare repository
wrapper.bare? # => true

# Check if the repository is a bare repository
wrapper.empty? # => false

# Get the full absolute path of the repository
wrapper.path # => #<Pathname:/path/to/the/repository>

# Get the list of all files
wrapper.ls_files('master') # => ['path/to/my_file.txt', 'another_file.txt']

# Find a blob (file)
wrapper.blob('master~3', 'path/to/my_file.txt') # => #<Gitlab::Git::Blob:0x00007fa91fe3dcb0 ...>

# Find a tree (directory)
wrapper.tree('master~3', 'path/to/my_directory') # => [#<Gitlab::Git::Tree:0x00007fa92005e968 ...>, ...]

# Find a commit
wrapper.commit('master~3') # => #<Gitlab::Git::Commit:0x00007fa91cef58e0 ...>

# The the number of commits up to a revision
wrapper.commit_count('master') # => 17

# Check if a path exists (as a blob or a tree)
wrapper.path_exists?('master~3', 'some/path') # => true

# Get the commit hash of a branch
wrapper.branch_sha('master') # => "98cf6fcfb912fb733bd3ed7480fc75ba5a762d35"

# Get the name of the default branch
wrapper.default_branch # => "master"

# Set the name of the default branch
wrapper.default_branch = "staging" # => "staging"

# Create a new branch at revision 322ba8d
wrapper.create_branch('my_feature', '322ba8d') # => #<Gitlab::Git::Branch:0x00007fa91507f178 ...>

# Get a list of all branches
wrapper.branches # => [#<Gitlab::Git::Branch:0x00007fa920372488 ...>, ...]

# Get a list of all branch names
wrapper.branch_names # => ["master", "my_feature"]

# Get the number of branches
wrapper.branch_count => 2

# Check if a branch exists
wrapper.branch_exists?('my_feature') # => true

# Find a branch by its name
wrapper.find_branch('my_feature') # => #<Gitlab::Git::Branch:0x00007fa920606b18 ...>

# Delete a branch
wrapper.rm_branch('my_feature') # => nil

# Create a new tag at revision 322ba8d
wrapper.create_tag('v1.0.0', '322ba8d') # => => #<Gitlab::Git::Tag:0x00007fa921828440 ...>

# Create a new tag with an annotation at revision 322ba8d
wrapper.create_tag('v1.0.1', '22ba8d3',
                   message: 'My tag message',
                   tagger: {name: 'Tagger',
                            email: 'tagger@example.com',
                            time: Time.now}) # => #<Gitlab::Git::Tag:0x00007fa91ed669a0 ...>

# Get a list of all tags
wrapper.tags # => [#<Gitlab::Git::Tag:0x00007fa91b25c990 ...>, ...]

# Get a list of all tag names
wrapper.tag_names # => ['v1.0', 'v1.1']

# Find a tag by its name
wrapper.find_tag('v1.0') # => #<Gitlab::Git::Tag:0x00007fa91cd52998 ...>

# Delete a tag
wrapper.rm_tag('v1.0') # => nil

# Diff of a single commit (compared to its parent commit)
wrapper.diff_from_parent('322ba8d') # => => #<Gitlab::Git::DiffCollection:0x00007fa91fb603d0 ...>

# Diff of a commit range
wrapper.diff('322ba8d', 'master') # => #<Gitlab::Git::DiffCollection:0x00007fa91d341840 ...>

# Diff of a commit range at some paths (the empty hash argument is for options)
wrapper.diff('322ba8d', 'master', {}, 'src/lib/', 'assets/javascript/application.js') # => #<Gitlab::Git::DiffCollection:0x00007fa91d341840 ...>

# Diff: Please see the lib/gitlab_git/diff.rb (filter_diff_options) for documentation of the options.
# The allowed options are:
#   :max_size, :context_lines, :interhunk_lines,
#   :old_prefix, :new_prefix, :reverse, :force_text,
#   :ignore_whitespace, :ignore_whitespace_change,
#   :ignore_whitespace_eol, :ignore_submodules,
#   :patience, :include_ignored, :include_untracked,
#   :include_unmodified, :recurse_untracked_dirs,
#   :disable_pathspec_match, :deltas_are_icase,
#   :include_untracked_content, :skip_binary_check,
#   :include_typechange, :include_typechange_trees,
#   :ignore_filemode, :recurse_ignored_dirs, :paths,
#   :max_files, :max_lines, :all_diffs, :no_collapse

# Log
wrapper.log(ref: 'master') # => [#<Gitlab::Git::Commit:0x00007fa91f971588 ...>, ...]

# Log that returns only the commit hashes (a lot faster)
wrapper.log(ref: 'master', only_commit_sha: true) # => ["98cf6fcfb912fb733bd3ed7480fc75ba5a762d35", ...]

# Log of a commit range. This is unsafe because the end commit might not
# have the start commit as a parent. In this case, the result is empty and a
# warning is printed on the console.
wrapper.log(ref: '322ba8d..master', unsafe_range: true) # => [#<Gitlab::Git::Commit:0x00007fa91e4334a0 ...>, ...]

# Log: The options and their defaults are:
#     limit: 10,           # How many commits should be retrieved
#     offset: 0,           # Skip a number of commits before starting to show the commit output
#     path: nil,           # Show only commits that are enough to explain how the files that match the specified paths came to be
#     follow: false,       # Continue listing the history of a file beyond renames
#     skip_merges: false,  # Do not print commits with more than one parent
#     disable_walk: false, # Retrieve the log using the git command line client instead of Rugged
#     after: nil,          # Show commits more recent than a specific date
#     before: nil,         # Show commits older than a specific date
#     unsafe_range: false, # Allow commit ranges in the ref option

# Get the Gitlab::Git::Repository instance
wrapper.gitlab

# Get the Rugged::Repository instance
wrapper.rugged
```

### Clone

Allows you to clone a remote git or svn repository.
Note that `git` must be in the `PATH` and that `git-svn` must be installed if svn functionality is needed.

```ruby
Gitlab::Git::Wrapper.clone(path, remote_address)
```

### Pull

Allows you to pull from a remote git or svn repository.
Note that `git` must be in the `PATH` and that `git-svn` must be installed if svn functionality is needed.

```ruby
Gitlab::Git::Wrapper.new(path).pull
```

### Creating a commit

The `Gitlab::Git::Wrapper` adds convenience-methods to create commits.
All of these need a committer and an author object as well as some commit options.

If the optional parameter `previous_head_sha` is supplied to any of the following methods, and the HEAD of the branch is different from that parameter (i.e. the branch has changed since authoring the commit-changes) Gitlab::Git::Wrapper attempts to merge the new commit on top of the current HEAD.
If merging is not possible, a `Gitlab::Git::Committing::HeadChangedError` is raised that contains data about the conflicts in its `conflicts` attribute.
If the parameter `previous_head_sha` is not set (`nil`), then the new commit overwrites possible changes to the branch that occurred in the meantime.

```ruby
# Preliminary objects - the time and update_ref keys are optional.
author = {name: 'author', email: 'author@example.com', time: Time.now}
committer = {name: 'committer', email: 'committer@example.com', time: Time.now}
commit_info = {message: 'Some message', branch: 'master', update_ref: true}
previous_head_sha = wrapper.commit('master').id # optional, set long before creating the commit

# Create a new file with a single commit
wrapper.create_file({file: {path: 'path/to/file.txt',
                           content: 'some content',
                           encoding: 'plain'}, # supported: 'plain', 'base64', default: 'plain'
                     author: author,
                     committer: committer,
                     commit: commit_info}, previous_head_sha) # previous_head_sha is optional (default: nil)
  # => 'c7454ef14304af343b6bc8b1545e224364d5a44b'

# Update file contents with a single commit
wrapper.update_file({file: {path: 'path/to/file.txt',
                           content: 'some new content',
                           encoding: 'plain'}, # supported: 'plain', 'base64', default: 'plain'
                     author: author,
                     committer: committer,
                     commit: commit_info}, previous_head_sha) # previous_head_sha is optional (default: nil)
  # => 'c7454ef14304af343b6bc8b1545e224364d5a44b'

# Update file contents and move the file with a single commit
wrapper.rename_and_update_file({file: {path: 'path/to/other_file.txt',
                                      previous_path: 'path/to/file.txt',
                                      content: 'some new content',
                                      encoding: 'plain'}, # supported: 'plain', 'base64', default: 'plain'
                                author: author,
                                committer: committer,
                                commit: commit_info}, previous_head_sha) # previous_head_sha is optional (default: nil)
  # => 'c7454ef14304af343b6bc8b1545e224364d5a44b'

# Rename a file with a single commit
wrapper.rename_file({file: {path: 'path/to/other_file.txt',
                            previous_path: 'path/to/file.txt'}
                     author: author,
                     committer: committer,
                     commit: commit_info}, previous_head_sha) # previous_head_sha is optional (default: nil)
  # => 'c7454ef14304af343b6bc8b1545e224364d5a44b'

# Remove a file with a single commit
wrapper.update_file({file: {path: 'path/to/file.txt'},
                     author: author,
                     committer: committer,
                     commit: commit_info}, previous_head_sha) # previous_head_sha is optional (default: nil)
  # => 'c7454ef14304af343b6bc8b1545e224364d5a44b'

# Create a directory (with a .gitkeep file) with a single commit
wrapper.mkdir('path/to/file.txt',
              {author: author, committer: committer, commit: commit_info}, previous_head_sha) # previous_head_sha is optional (default: nil)
  # => 'c7454ef14304af343b6bc8b1545e224364d5a44b'

# Create a single commit with multiple actions:
files =
  [{content: 'Lorem ipsum...',
    path: 'documents/story.txt',
    action: :create},
   {content: 'New Lorem ipsum...',
    path: 'documents/old_story',
    action: :update},
   {content: 'New Lorem ipsum...',
    path: 'documents/another_old_story',
    previus_path: 'documents/another_really_old_story.txt',
    action: :rename_and_update},
   {path: 'documents/obsolet_story.txt',
    action: :remove},
   {path: 'documents/old_story',
    previus_path: 'documents/really_old_story.txt',
    action: :rename},
   {path: 'documents/secret',
    action: :mkdir}
  ]
wrapper.commit_multichange({files: files,
                            author: author,
                            committer: committer,
                            commit: commit_info}, previous_head_sha) # previous_head_sha is optional (default: nil)
  # => 'c7454ef14304af343b6bc8b1545e224364d5a44b'
```


### Repository

```ruby
# Init repo with full path
repo = Gitlab::Git::Repository.new('/home/git/repositories/gitlab/gitlab-ci.git')

repo.path
# "/home/git/repositories/gitlab/gitlab-ci.git"

repo.name
# "gitlab-ci.git"

# Get branches and tags
repo.branches
repo.tags

# Get branch or tag names
repo.branch_names
repo.tag_names

# Archive repo to `/tmp` dir
repo.archive_repo('master', '/tmp')

# Bare repo size in MB.
repo.size
# 10.43

# Search for code
repo.search_files('rspec', 'master')
# [ <Gitlab::Git::BlobSnippet:0x000..>, <Gitlab::Git::BlobSnippet:0x000..>]

# Access to rugged repo object
repo.rugged
```

### Specs

In case it's needed to update https://gitlab.com/gitlab-org/gitlab-git-test with new content changes the developer should update `spec/support/last_commit.rb` with the updated sha of the last commit and the required information. The developer should also run the full set of tests to check which ones are failing and fix them accordingly.

### Tree

```ruby
# Tree objects for root dir
tree = Gitlab::Git::Tree.where(repo, '893ade32')

# Tree objects for sub dir
tree = Gitlab::Git::Tree.where(repo, '893ade32', 'app/models/')

# [
#   #<Gitlab::Git::Tree:0x00000002b2ed80 @id="38f45392ae61f0effa84048f208a81019cc306bb", @name="lib", @path="projects/lib", @type=:tree, @mode="040000", @commit_id="8470d70da67355c9c009e4401746b1d5410af2e3">
#   #<Gitlab::Git::Tree:0x00000002b2ed80 @id="32a45392ae61f0effa84048f208a81019cc306bb", @name="sample.rb", @path="projects/sample.rb", @type=:blob, @mode="040000", @commit_id="8470d70da67355c9c009e4401746b1d5410af2e3">
# ]

dir = tree.first
dir.name # lib
dir.type # :tree
dir.dir? # true
dir.file? # false

file = tree.last
file.name # sample.rb
file.type # :blob
file.dir? # false
file.file? # true

# Select only files for tree
tree.select(&:file?)

# Find readme
tree.find(&:readme?)
```

### Blob

```ruby
# Blob object for Commit sha 893ade32
blob = Gitlab::Git::Blob.find(repo, '893ade32', 'Gemfile')

# Attributes
blob.id
blob.name
blob.size
blob.data # contains only a fragment of the blob's data to save memory
blob.mode
blob.path
blob.commit_id

# Load all blob data into memory
blob.load_all_data!(repo)

# Blob object with sha 8a3f8ddcf3536628c9670d41e67a785383eded1d
raw_blob = Gitlab::Git::Blob.raw(repo, '8a3f8ddcf3536628c9670d41e67a785383eded1d')

# Attributes for raw blobs are more limited
raw_blob.id
raw_blob.size
raw_blob.data
```

#### Committing a blob

```ruby
options = {
  file: {
    content: 'Lorem ipsum...',
    path: 'documents/story.txt'
  },
  author: {
    email: 'user@example.com',
    name: 'Test User',
    time: Time.now    # optional - default: Time.now
  },
  committer: {
    email: 'user@example.com',
    name: 'Test User',
    time: Time.now    # optional - default: Time.now
  },
  commit: {
    message: 'Wow such commit',
    branch: 'master',    # optional - default: 'master'
    update_ref: false    # optional - default: true
}

# Create a file in the repository.
# Returns sha of commit that did a change
Gitlab::Git::Wrapper.new('path/to/repository.git').create_file(options)


options = {
  file: {
    content: 'Lorem ipsum...',
    path: 'documents/story.txt',
    previous_path: 'documents/old_story.txt' # optional - used for renaming while updating
  },
  author: {
    email: 'user@example.com',
    name: 'Test User',
    time: Time.now    # optional - default: Time.now
  },
  committer: {
    email: 'user@example.com',
    name: 'Test User',
    time: Time.now    # optional - default: Time.now
  },
  commit: {
    message: 'Wow such commit',
    branch: 'master',    # optional - default: 'master'
    update_ref: false    # optional - default: true
  }
}

# Update a file in the repository.
# Returns sha of commit that did a change
Gitlab::Git::Wrapper.new('path/to/repository.git').update_file(options)


options = {
  file: {
    path: 'documents/story.txt'
  },
  author: {
    email: 'user@example.com',
    name: 'Test User',
    time: Time.now    # optional - default: Time.now
  },
  committer: {
    email: 'user@example.com',
    name: 'Test User',
    time: Time.now    # optional - default: Time.now
  },
  commit: {
    message: 'Remove FILENAME',
    branch: 'master'    # optional - default: 'master'
  }
}

# Delete a file from the repository.
# Returns sha of commit that did a change
Gitlab::Git::Wrapper.new('path/to/repository.git').remove_file(options)

options = {
  file: {
    previous_path: 'documents/old_story.txt'
    path: 'documents/story.txt'
  },
  author: {
    email: 'user@example.com',
    name: 'Test User',
    time: Time.now    # optional - default: Time.now
  },
  committer: {
    email: 'user@example.com',
    name: 'Test User',
    time: Time.now    # optional - default: Time.now
  },
  commit: {
    message: 'Rename FILENAME',
    branch: 'master'    # optional - default: 'master'
  }
}

# Rename a file in the repository. This does not change the file content.
# Returns sha of commit that did a change
Gitlab::Git::Wrapper.new('path/to/repository.git').rename_file(options)



options = {
  author: {
    email: 'user@example.com',
    name: 'Test User',
    time: Time.now    # optional - default: Time.now
  },
  committer: {
    email: 'user@example.com',
    name: 'Test User',
    time: Time.now    # optional - default: Time.now
  },
  commit: {
    message: 'Wow such commit',
    branch: 'master',    # optional - default: 'master'
    update_ref: false    # optional - default: true
  }
}

# Create a directory (via .gitkeep) in the repository.
# Returns sha of commit that did a change
Gitlab::Git::Wrapper.new('path/to/repository.git').mkdir(path, options)



options = {
  files: {
    [{content: 'Lorem ipsum...',
      path: 'documents/story.txt',
      action: :create},
     {content: 'New Lorem ipsum...',
      path: 'documents/old_story',
      previus_path: 'documents/really_old_story.txt', # optional - moves the file from +previous_path+ to +path+ if this is given
      action: :update},
     {path: 'documents/obsolet_story.txt',
      action: :remove},
     {path: 'documents/old_story',
      previus_path: 'documents/really_old_story.txt',
      action: :rename},
     {path: 'documents/secret',
      action: :mkdir}
    ]
    }
  },
  author: {
    email: 'user@example.com',
    name: 'Test User',
    time: Time.now    # optional - default: Time.now
  },
  committer: {
    email: 'user@example.com',
    name: 'Test User',
    time: Time.now    # optional - default: Time.now
  },
  commit: {
    message: 'Wow such commit',
    branch: 'master',    # optional - default: 'master'
    update_ref: false    # optional - default: true
  }
}

# Apply multiple file changes to the repository
# Returns sha of commit that did a change
Gitlab::Git::Wrapper.new('path/to/repository.git').commit_multichange(options)
```


### Commit

#### Picking

```ruby
# Get commits collection with pagination
Gitlab::Git::Commit.where(
  repo: repo,
  ref: 'master',
  path: 'app/models',
  limit: 10,
  offset: 5,
)

# Find single commit
Gitlab::Git::Commit.find(repo, '29eda46b')
Gitlab::Git::Commit.find(repo, 'v2.4.6')

# Get last commit for HEAD
commit = Gitlab::Git::Commit.last(repo)

# Get last commit for specified file/directory
Gitlab::Git::Commit.last_for_path(repo, '29eda46b', 'app/models')

# Commits between branches
Gitlab::Git::Commit.between(repo, 'dev', 'master')
# [ <Gitlab::Git::Commit:0x000..>, <Gitlab::Git::Commit:0x000..>]
```

#### Commit object

```ruby
# Commit id
commit.id
commit.sha
# ba8812a2de5e5ea191da6930a8ee1965873286e3

commit.short_id
# ba8812a2de

commit.message
commit.safe_message
# Fix bug 891

commit.parent_id
# ba8812a2de5e5ea191da6930a8ee1965873286e3

commit.diffs
# [ <Gitlab::Git::Diff:0x000..>, <Gitlab::Git::Diff:0x000..>]

commit.created_at
commit.authored_date
commit.committed_date
# 2013-07-03 22:11:26 +0300

commit.committer_name
commit.author_name
# John Smith

commit.committer_email
commit.author_email
# jsmith@sample.com
```

### Diff object

```ruby
# From commit
commit.diffs
# [ <Gitlab::Git::Diff:0x000..>, <Gitlab::Git::Diff:0x000..>]

# Diff between several commits
Gitlab::Git::Diff.between(repo, 'dev', 'master')
# [ <Gitlab::Git::Diff:0x000..>, <Gitlab::Git::Diff:0x000..>]

# Diff object
diff = commit.diffs.first

diff.diff #  "--- a/Gemfile.lock\....."
diff.new_path # => "Gemfile.lock",
diff.old_path # => "Gemfile.lock",
diff.a_mode # => nil,
diff.b_mode # => "100644",
diff.new_file # => false,
diff.renamed_file # => false,
diff.deleted_file # => false
```

### Git blame

```ruby
# Git blame for file
blame = Gitlab::Git::Blame.new(repo, 'master, 'app/models/project.rb')
blame.each do |commit, lines|
  commit # <Gitlab::Git::Commit:0x000..>
  lines # ['class Project', 'def initialize']
end
```

### Compare

Allows you to get difference (commits, diffs) between two SHA/branch/tag:

```ruby
compare = Gitlab::Git::Compare.new(repo, 'v4.3.2', 'master')

compare.commits
# [ <Gitlab::Git::Commit:0x000..>, <Gitlab::Git::Commit:0x000..>]

compare.diffs
# [ <Gitlab::Git::Diff:0x000..>, <Gitlab::Git::Diff:0x000..>]
```
