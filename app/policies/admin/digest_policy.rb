# frozen_string_literal: true

class Admin::DigestPolicy < ApplicationPolicy
  def index?
    admin_or_moderator?
  end

  def show?
    admin_or_moderator?
  end

  def edit?
    admin_or_moderator?
  end

  def update?
    admin_or_moderator?
  end

  def approve?
    admin_or_moderator?
  end

  def reject?
    admin_or_moderator?
  end

  def bulk_approve?
    admin_only?
  end

  def run_now?
    admin_only?
  end

  private

  def admin_or_moderator?
    user&.has_role?(:admin) || user&.has_role?(:moderator)
  end

  def admin_only?
    user&.has_role?(:admin)
  end
end
