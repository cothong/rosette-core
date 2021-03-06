# encoding: UTF-8

module Rosette
  module Core
    module Commands

      # Computes the status of a git ref. Statuses contain the number of
      # translations per locale as well as the state of the commit (pending,
      # untranslated, or translated).
      #
      # @see Rosette::DataStores::PhraseStatus
      #
      # @example
      #   cmd = StatusCommand.new(configuration)
      #     .set_repo_name('my_repo')
      #     .set_ref('master')
      #
      #   cmd.execute
      #   # =>
      #   # {
      #   #   commit_id: "5756196042a3a307b43fd1a7092ecc6710eec42a",
      #   #   status: "PENDING",
      #   #   phrase_count: 100,
      #   #   locales: [{
      #   #     locale: 'fr-FR',
      #   #     percent_translated: 0.5,
      #   #     translated_count: 50
      #   #   }, ... ]
      #   # }
      class StatusCommand < GitCommand
        include WithRepoName
        include WithRef

        # Computes the status for the configured repository and git ref. The
        # status is computed by identifying the branch the ref belongs to, then
        # examining and merging the statuses of all commits that belong to
        # that branch.
        #
        # @see Rosette::DataStores::PhraseStatus
        #
        # @return [Hash] a hash of status information for the ref:
        #   * +commit_id+: the commit id of the ref the status came from.
        #   * +status+: One of +"FETCHED"+, +"EXTRACTED"+, +"PUSHED"+,
        #     +"FINALIZED"+, or +"NOT_FOUND"+.
        #   * +phrase_count+: The number of phrases found in the commit.
        #   * +locales+: A hash of locale codes to locale statuses having these
        #     entries:
        #     * +percent_translated+: The percentage of +phrase_count+ phrases
        #       that are currently translated in +locale+ for this commit.
        #       In other words, +translated_count+ +/+ +phrase_count+.
        #     * +translated_count+: The number of translated phrases in +locale+
        #       for this commit.
        def execute
          repo_config = get_repo(repo_name)
          branch_name = BranchUtils.derive_branch_name(commit_id, repo_config.repo)
          status, phrase_count, locale_statuses = derive(branch_name, repo_config)

          {
            status: status,
            commit_id: commit_id,
            phrase_count: phrase_count,
            locales: locale_statuses
          }
        end

        protected

        def derive(branch_name, repo_config)
          commit_logs = commit_logs_for(branch_name, repo_config)
          status = derive_status(branch_name, commit_logs)
          phrase_count = BranchUtils.derive_phrase_count_from(commit_logs)
          locale_statuses = BranchUtils.derive_locale_statuses_from(
            commit_logs, repo_name, datastore, phrase_count
          )

          [
            status, phrase_count,
            BranchUtils.fill_in_missing_locales(
              repo_config.locales, locale_statuses
            )
          ]
        end

        def derive_status(branch_name, commit_logs)
          if branch_name
            statuses = [Rosette::DataStores::PhraseStatus::FINALIZED]
            finalized = datastore.commit_log_with_status_count(
              repo_name, statuses, branch_name
            )

            if finalized > 0
              BranchUtils.derive_status_from(commit_logs)
            else
              Rosette::DataStores::PhraseStatus::NOT_FOUND
            end
          else
            BranchUtils.derive_status_from(commit_logs)
          end
        end

        def commit_logs_for(branch_name, repo_config)
          statuses = Rosette::DataStores::PhraseStatus.incomplete
          datastore.each_commit_log_with_status(repo_name, statuses, branch_name).to_a
        end
      end

    end
  end
end
