# frozen_string_literal: true

class TopicDigestPolicy < ApplicationPolicy
  def show?
    user.present?
  end
end
