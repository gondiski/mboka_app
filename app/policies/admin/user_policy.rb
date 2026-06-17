# frozen_string_literal: true

class Admin::UserPolicy < ApplicationPolicy
  def index?
    admin? || moderator?
  end

  def show?
    admin? || moderator?
  end

  def update_status?
    admin?
  end

  def import?
    admin?
  end

  class Scope < Scope
    def resolve
      return scope.all if admin?
      return scope.select(:id, :full_name, :email, :designation, :status, :created_at) if moderator?

      scope.none
    end
  end
end
