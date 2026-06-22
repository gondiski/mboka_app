# frozen_string_literal: true

class Admin::SettingsPolicy < ApplicationPolicy
  def show?
    admin?
  end

  def update?
    admin?
  end
end
