# frozen_string_literal: true

class MagicLinkPolicy < ApplicationPolicy
  def new?
    true
  end

  def create?
    true
  end

  def validate?
    true
  end

  def check_email?
    true
  end
end
