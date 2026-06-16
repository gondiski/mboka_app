# frozen_string_literal: true

class Admin::DashboardPolicy < ApplicationPolicy
  def show?
    admin? || moderator?
  end

  def manage_jobs?
    admin?
  end
end
