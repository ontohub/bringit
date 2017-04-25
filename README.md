# GitLab Git

## `Gitlab::Git` has been absorbed into the [main GitLab project](https://gitlab-com/gitlab-org/gitlab-ce), and the `gitlab_git` gem has been deprecated. See the [gitlab-ce issue](https://gitlab.com/gitlab-org/gitlab-ce/issues/24374) and [merge request](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/8447) for more information.

In this repository, some updates to gitlab_git from the integrated gitlab-git are copied over and adjusted to work as a gem.
There is no guarantee that this repository will be up to date in the future because some changes to the gitlab_git-part of gitlab-ce can introduce changes that are too large for us to maintain.

GitLab wrapper around git objects.

[![build status](https://gitlab.com/gitlab-org/gitlab_git/badges/master/build.svg)](https://gitlab.com/gitlab-org/gitlab_git/commits/master)
[![Gem Version](https://badge.fury.io/rb/gitlab_git.svg)](http://badge.fury.io/rb/gitlab_git)

## Moved from Grit to Rugged

GitLab Git used grit as main library in past. Now it uses rugged

## How to use

### Repository

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

### Specs

In case it's needed to update https://gitlab.com/gitlab-org/gitlab-git-test with new content changes the developer should update `spec/support/last_commit.rb` with the updated sha of the last commit and the required information. The developer should also run the full set of tests to check which ones are failing and fix them accordingly.

### Tree

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

### Blob

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

#### Commiting blob

    options = {
       file: {
         content: 'Lorem ipsum...',
         path: 'documents/story.txt'
       },
       author: {
         email: 'user@example.com',
         name: 'Test User',
         time: Time.now
       },
       committer: {
         email: 'user@example.com',
         name: 'Test User',
         time: Time.now
       },
       commit: {
         message: 'Wow such commit',
         branch: 'master'
       }
    }

    # Create or update file in repository.
    # Returns sha of commit that did a change
    Gitlab::Git::Blob.commit(repository, commit_options)


### Commit

#### Picking

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

#### Commit object

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

### Diff object

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

### Git blame

    # Git blame for file
    blame = Gitlab::Git::Blame.new(repo, 'master, 'app/models/project.rb')
    blame.each do |commit, lines|
      commit # <Gitlab::Git::Commit:0x000..>
      lines # ['class Project', 'def initialize']
    end

### Compare

Allows you to get difference (commits, diffs) between two SHA/branch/tag:

    compare = Gitlab::Git::Compare.new(repo, 'v4.3.2', 'master')

    compare.commits
    # [ <Gitlab::Git::Commit:0x000..>, <Gitlab::Git::Commit:0x000..>]

    compare.diffs
    # [ <Gitlab::Git::Diff:0x000..>, <Gitlab::Git::Diff:0x000..>]
