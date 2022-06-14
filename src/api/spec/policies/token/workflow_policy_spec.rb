require 'rails_helper'

RSpec.describe Token::WorkflowPolicy do
  let(:user) { create(:confirmed_user) }
  let(:user_token) { create(:workflow_token, user: user) }
  let(:other_user) { group.users.first }
  let(:group) { create(:group_with_user) }

  subject { described_class }

  before do
    Flipper.enable(:trigger_workflow, user)
    Flipper.enable(:trigger_workflow, other_user)
  end

  describe '#trigger' do
    context 'user inactive' do
      include_examples 'non-active users cannot trigger a token'
    end

    # As a workflow token is not tied to a package, any user can create one as long as their account is active.
    context 'user active' do
      let(:user) { create(:confirmed_user, login: 'foo') }

      permissions :trigger? do
        it { expect(subject).to permit(user, user_token) }
      end
    end
  end

  permissions :create? do
    context 'when the user has the feature enabled' do
      context 'when the user is the owner of the token' do
        it { is_expected.to permit(user, user_token) }
      end

      context 'when the user is not the owner of the token' do
        context 'and the token has not been shared with that user' do
          it { is_expected.not_to permit(other_user, user_token) }
        end

        context 'but the token has been shared with that user' do
          before do
            other_user.shared_workflow_tokens << user_token
          end

          it { is_expected.to permit(other_user, user_token) }
        end

        context "but the token has been shared with that users's group" do
          before do
            group.shared_workflow_tokens << user_token
          end

          it { is_expected.to permit(other_user, user_token) }
        end
      end
    end

    context 'when the user does not have the feature enabled' do
      before { Flipper.disable(:trigger_workflow, user) }

      it { is_expected.not_to permit(user, user_token) }
    end
  end

  permissions :destroy? do
    context 'when the user has the feature enabled' do
      context 'when the user is the owner of the token' do
        it { is_expected.to permit(user, user_token) }
      end

      context 'when the user does not own the token' do
        it { is_expected.not_to(permit(other_user, user_token)) }
      end
    end

    context 'when the user does not have the feature enabled' do
      before { Flipper.disable(:trigger_workflow, user) }

      it { is_expected.not_to permit(user, user_token) }
    end
  end
end
