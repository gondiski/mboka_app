# frozen_string_literal: true

class Admin::ReportPolicy < ApplicationPolicy
  def show?
    user.has_any_role?(:admin, :moderator)
  end
end
