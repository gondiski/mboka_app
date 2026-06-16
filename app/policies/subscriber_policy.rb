# frozen_string_literal: true

class SubscriberPolicy < ApplicationPolicy
  def new?
    true
  end

  def create?
    true
  end
end
