# frozen_string_literal: true

class Admin::DigestSchedulePolicy < ApplicationPolicy
  def show?
    admin?
  end

  def update?
    admin?
  end
end
