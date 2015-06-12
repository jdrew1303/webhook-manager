# Mixin to provide a GitHub client and helpers.
module Github
  def github
    @github ||= Octokit::Client.new(access_token: ENV['GITHUB_ACCESS_TOKEN'])
  end
  module_function :github
  public :github

  def clone_url(uri)
    repo_clone_url = URI.parse(uri)
    repo_clone_url.user = github.login
    repo_clone_url.password = github.access_token
    repo_clone_url
  end

  def with_tmp_dir(&block)
    Dir.mktmpdir do |tmp_dir|
      Dir.chdir(tmp_dir, &block)
    end
  end

  def git_clone(repo_name)
    repo = github.repository(repo_name)
    with_tmp_dir do
      `git clone -q #{clone_url(repo.clone_url)} .`
      yield
    end
  end

  def git_config
    @git_config ||= "-c user.name='#{github.login}' " \
      "-c user.email='#{github.emails.first[:email]}'"
  end

  def git_commit_and_push(options)
    branch_name = options.fetch(:branch)
    message = options.fetch(:message)
    `git checkout -q -b #{branch_name}`
    `git add .`
    `git #{git_config} commit --message="#{message}"`
    `git push --quiet origin #{branch_name}`
  end
end
