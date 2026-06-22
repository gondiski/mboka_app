# frozen_string_literal: true

class Admin::DocsPolicy < ApplicationPolicy
  def show?
    admin? || moderator?
  end
end
