class Token::WorkflowPolicy < TokenPolicy
  # TODO: remove the second half of the condition when `trigger_workflow` feature is rolled out
  def trigger?
    user.is_active? && Flipper.enabled?(:trigger_workflow, user)
  end

  def rebuild?
    return PackagePolicy.new(user, record.object_to_authorize).update? if record.object_to_authorize.is_a?(Package)
    return ProjectPolicy.new(user, record.object_to_authorize).update? if record.object_to_authorize.is_a?(Project)
  end

  def trigger_service?
    PackagePolicy.new(user, record.object_to_authorize).update?
  end

  def create?
    # TODO: when trigger_workflow is rolled out, remove the Flipper check
    return false unless Flipper.enabled?(:trigger_workflow, user)

    # TODO: remove the first condition if we migrate the Token.user to Token.users_shared_among
    record.user == user || record.users_shared_among.include?(user) || record.groups_shared_among.map(&:users).flatten.include?(user)
  end
end
