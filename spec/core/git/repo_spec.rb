# encoding: UTF-8

require 'spec_helper'

include Rosette::Core

java_import 'org.eclipse.jgit.lib.ObjectId'

describe Repo do
  let(:repo_class) { Repo }

  describe 'self.from_path' do
    it 'returns a new repo at the given path' do
      tmp_repo = TmpRepo.new
      repo = repo_class.from_path(tmp_repo.working_dir.join('.git').to_s)
      expect(repo.path).to eq(tmp_repo.working_dir.to_s)
      tmp_repo.unlink
    end
  end

  context 'with the double commit fixture' do
    let(:repo_name) { 'double_commit' }
    let(:fixture) { load_repo_fixture(repo_name) }
    let(:repo) { repo_class.from_path(fixture.working_dir.join('.git').to_s) }
    let(:commits) do
      fixture.git('rev-list --all').split("\n").map do |sha|
        repo.get_rev_commit(sha)
      end.reverse
    end

    describe '#get_rev_commit' do
      it 'returns a rev commit for a symbolic ref' do
        commit = repo.get_rev_commit('HEAD')
        expect(commit.getName).to eq(commits.last.getName)
      end

      it 'returns a rev commit for a sha' do
        commit = repo.get_rev_commit(commits.last.getName)
        expect(commit.getName).to eq(commits.last.getName)
      end

      it "falls back to remotes if the branch hasn't been checked out locally" do
        branch_name = 'my_remote_branch'

        remote_repo = TmpRepo.new.tap do |r|
          r.create_branch(branch_name)
          r.create_file('foo.txt') { |f| f.write('foo') }
          r.add_all
          r.commit('Initial commit')
        end

        fixture.repo.git("remote add origin file://#{remote_repo.working_dir}")
        fixture.repo.git('fetch')

        remote_commit_id = remote_repo.git('rev-parse HEAD').strip
        commit = repo.get_rev_commit(branch_name)
        expect(commit.getName).to eq(remote_commit_id)
      end
    end

    describe '#diff' do
      it 'returns the diff when a symbolic ref is involved' do
        commit_id = commits.first.getName
        repo.diff(commit_id, 'HEAD').tap do |diff|
          expect(diff.size).to eq(1)
          expect(diff[commit_id].first.getNewPath).to eq('second_file.txt')
        end
      end

      it 'returns the diff between two shas' do
        first_commit_id = commits.first.getName
        second_commit_id = commits.last.getName
        repo.diff(first_commit_id, second_commit_id).tap do |diff|
          expect(diff.size).to eq(1)
          expect(diff[first_commit_id].first.getNewPath).to eq('second_file.txt')
        end
      end
    end

    describe '#ref_diff_with_parents' do
      it 'returns the correct diff' do
        commit_id = commits.first.getName
        repo.ref_diff_with_parents('HEAD').tap do |diff|
          expect(diff.size).to eq(1)
          expect(diff[commit_id].first.getNewPath).to eq('second_file.txt')
        end
      end
    end

    describe '#rev_diff_with_parents' do
      it 'returns the correct diff' do
        commit_id = commits.first.getName
        repo.rev_diff_with_parents(repo.get_rev_commit('HEAD')).tap do |diff|
          expect(diff.size).to eq(1)
          expect(diff[commit_id].first.getNewPath).to eq('second_file.txt')
        end
      end
    end

    describe '#path' do
      it 'returns the current working directory' do
        expect(repo.path).to eq(fixture.working_dir.to_s)
      end
    end

    describe '#read_object_bytes' do
      it 'returns a byte array containing the object of the given id' do
        object_id = ObjectId.fromString(fixture.git('hash-object first_file.txt').strip)
        actual_bytes = repo.read_object_bytes(object_id)
        expected_bytes = "I'm a little teapot\nThe green albatross flitters in the moonlight\n".bytes

        expected_bytes.each_with_index do |expected_byte, index|
          expect(actual_bytes[index]).to eq(expected_byte)
        end
      end
    end

    describe '#each_commit' do
      it 'yields each commit or returns an enumerator' do
        repo.each_commit.tap do |commit_enum|
          expect(commit_enum).to be_a(Enumerator)
          expect(commit_enum.map(&:getName)).to eq(commits.map(&:getName))
        end
      end
    end

    describe '#commit_count' do
      it 'returns the total number of commits in the repo' do
        expect(repo.commit_count).to eq(2)
      end
    end
  end

  context 'with the four commits fixture' do
    let(:repo_name) { 'four_commits' }
    let(:fixture) { load_repo_fixture(repo_name) }
    let(:repo) { repo_class.from_path(fixture.working_dir.join('.git').to_s) }
    let(:commits) do
      fixture.git('rev-list --all').split("\n").map do |sha|
        repo.get_rev_commit(sha)
      end.reverse
    end

    describe '#each_commit_in_range' do
      it 'yields only the commits in the given range' do
        commit_args = [commits[2].getId.name, commits[0].getId.name]

        found_commits = repo.each_commit_in_range(*commit_args).map do |c|
          c.getId.name
        end

        expect(found_commits).to(
          eq(commits[0..2].map { |c| c.getId.name }.reverse)
        )
      end
    end
  end

  context 'with a merge commit fixture' do
    let(:repo_name) { 'merge_commit' }
    let(:fixture) { load_repo_fixture(repo_name) }
    let(:repo) { repo_class.from_path(fixture.working_dir.join('.git').to_s) }
    let(:commits) do
      fixture.git('rev-list --all').split("\n").map do |sha|
        repo.get_rev_commit(sha)
      end
    end

    describe '#parents_of' do
      it 'returns a single commit for a commit with a single parent' do
        repo.parents_of(commits[1]).tap do |parents|
          expect(parents.size).to eq(1)
          expect(parents.first.getName).to eq(commits.last.getName)
        end
      end

      it 'returns multiple parents when given a merge commit' do
        repo.parents_of(commits.first).tap do |parents|
          expect(parents.size).to eq(2)
          parent_shas = parents.map(&:getName)
          expect(parent_shas).to include(commits.last.getName)
          expect(parent_shas).to include(commits[1].getName)
        end
      end
    end

    describe '#parent_ids_of' do
      it 'returns a single sha for a commit with a single parent' do
        repo.parent_ids_of(commits[1]).tap do |parent_ids|
          expect(parent_ids).to eq([commits.last.getName])
        end
      end

      it 'returns multiple parent shas when given a merge commit' do
        repo.parent_ids_of(commits.first).tap do |parent_ids|
          expect(parent_ids).to eq(commits[1..-1].reverse.map(&:getName))
        end
      end
    end

    describe '#commit_count' do
      it 'returns the total number of commits in the repo' do
        expect(repo.commit_count).to eq(3)
      end
    end

    describe '#refs_containing' do
      it 'returns the refs that contain the given commit' do
        refs = repo.refs_containing(commits.last.getId.name)
        expect(refs.map(&:getName)).to eq([
          "HEAD", "refs/heads/master", "refs/heads/mybranch"
        ])
      end
    end
  end
end
