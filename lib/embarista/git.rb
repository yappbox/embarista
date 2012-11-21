module Embarista
  module Git
    BRANCH_TO_DEPLOY_FROM = 'master'
    extend self

    def is_dirty?
      not `git status --porcelain`.empty?
    end

    def git_branches
      `git branch --no-color -vv`
    end

    def can_deploy_from_curren_branch?
      git_branches =~ /\A\* #{BRANCH_TO_DEPLOY_FROM}.*origin\/#{BRANCH_TO_DEPLOY_FROM}: (ahead|behind)/
    end
  end
end
