# frozen_string_literal: true

class Admin::PaymentsPolicy < ApplicationPolicy
  def show?
    admin?
  end

  def checkout?
    admin?
  end

  def verify?
    admin?
  end

  def history?
    admin?
  end
end
