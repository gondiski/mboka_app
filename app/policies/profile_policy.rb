# frozen_string_literal: true

class ProfilePolicy < ApplicationPolicy
  def show?
    return true if admin? || moderator?
    return true if authenticated? && user.id == record.id

    false
  end

  def update?
    return true if admin?
    return true if authenticated? && user.id == record.id

    false
  end

  class Scope < Scope
    def resolve
      return scope.all if admin? || moderator?

      scope.where(id: user.id)
    end
  end
end
