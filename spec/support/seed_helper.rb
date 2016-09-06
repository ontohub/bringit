module SeedHelper
  GITLAB_URL = "https://gitlab.com/gitlab-org/gitlab-git-test.git"

  def ensure_seeds
    if File.exists?(SUPPORT_PATH)
      FileUtils.rm_r(SUPPORT_PATH)
    end

    FileUtils.mkdir_p(SUPPORT_PATH)

    create_bare_seeds
    create_normal_seeds
    create_mutable_seeds
    create_git_attributes
  end

  def create_bare_seeds
    system(git_env, *%W(git clone --bare #{GITLAB_URL}),
           chdir: SUPPORT_PATH,
           out:   '/dev/null',
           err:   '/dev/null')
  end

  def create_normal_seeds
    system(git_env, *%W(git clone #{TEST_REPO_PATH} #{TEST_NORMAL_REPO_PATH}),
           out: '/dev/null',
           err: '/dev/null')
  end

  def create_mutable_seeds
    system(git_env, *%W(git clone #{TEST_REPO_PATH} #{TEST_MUTABLE_REPO_PATH}),
           out: '/dev/null',
           err: '/dev/null')

    system(git_env, *%w(git branch -t feature origin/feature),
           chdir: TEST_MUTABLE_REPO_PATH, out: '/dev/null', err: '/dev/null')

    system(git_env, *%W(git remote add expendable #{GITLAB_URL}),
           chdir: TEST_MUTABLE_REPO_PATH, out: '/dev/null', err: '/dev/null')
  end

  def create_git_attributes
    dir = File.join(SUPPORT_PATH, 'with-git-attributes.git', 'info')

    FileUtils.mkdir_p(dir)

    File.open(File.join(dir, 'attributes'), 'w') do |handle|
      handle.write <<-EOF.strip
# This is a comment, it should be ignored.

*.txt     text
*.jpg     -text
*.sh      eol=lf gitlab-language=shell
*.haml.*  gitlab-language=haml
foo/bar.* foo
*.cgi     key=value?p1=v1&p2=v2
/*.png    gitlab-language=png
*.binary  binary

# This uses a tab instead of spaces to ensure the parser also supports this.
*.md\tgitlab-language=markdown
      EOF
    end
  end

  # Prevent developer git configurations from being persisted to test
  # repositories
  def git_env
    {'GIT_TEMPLATE_DIR' => ''}
  end
end
